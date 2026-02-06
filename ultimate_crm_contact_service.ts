import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '../utils/logger';
import { RedisManager } from '../cache/redis';
import { KafkaManager } from '../events/kafka';
import { ElasticsearchManager } from '../search/elasticsearch';

interface Contact {
  id?: string;
  organization_id: string;
  lead_id?: string;
  first_name: string;
  last_name: string;
  email?: string;
  phone?: string;
  company?: string;
  job_title?: string;
  department?: string;
  lifecycle_stage?: string;
  owner_id?: string;
  address?: Record<string, any>;
  social_profiles?: Record<string, any>;
  custom_fields?: Record<string, any>;
  tags?: string[];
}

interface ContactActivity {
  id?: string;
  contact_id: string;
  type: 'email' | 'call' | 'meeting' | 'note' | 'task';
  subject?: string;
  description?: string;
  created_at?: Date;
  created_by?: string;
}

interface ContactTimeline {
  activities: ContactActivity[];
  deals: any[];
  emails: any[];
  calls: any[];
  notes: any[];
}

export class ContactService {
  private logger: Logger;
  private db: Pool;
  private cache: RedisManager;
  private events: KafkaManager;
  private search: ElasticsearchManager;

  constructor(db: Pool, cache: RedisManager, events: KafkaManager, search: ElasticsearchManager) {
    this.logger = new Logger('ContactService');
    this.db = db;
    this.cache = cache;
    this.events = events;
    this.search = search;
  }

  /**
   * Create new contact
   */
  async createContact(contact: Contact): Promise<Contact> {
    const contactId = uuidv4();
    const now = new Date();

    const query = `
      INSERT INTO contacts (
        id, organization_id, lead_id, first_name, last_name, 
        email, phone, company, job_title, department,
        lifecycle_stage, owner_id, address, social_profiles,
        custom_fields, tags, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
      RETURNING *
    `;

    const values = [
      contactId,
      contact.organization_id,
      contact.lead_id,
      contact.first_name,
      contact.last_name,
      contact.email,
      contact.phone,
      contact.company,
      contact.job_title,
      contact.department,
      contact.lifecycle_stage || 'subscriber',
      contact.owner_id,
      JSON.stringify(contact.address || {}),
      JSON.stringify(contact.social_profiles || {}),
      JSON.stringify(contact.custom_fields || {}),
      contact.tags || [],
      now,
      now
    ];

    try {
      const result = await this.db.query(query, values);
      const createdContact = result.rows[0];

      // Index in Elasticsearch for fast search
      await this.search.indexContact(createdContact);

      // Invalidate cache
      await this.cache.del(`contact:${contactId}`);
      await this.cache.del(`contacts:org:${contact.organization_id}`);

      // Publish event
      await this.events.publish('contact.created', {
        contact_id: contactId,
        organization_id: contact.organization_id,
        timestamp: now.toISOString()
      });

      this.logger.info(`Contact created: ${contactId}`);
      return createdContact;

    } catch (error) {
      this.logger.error('Error creating contact:', error);
      throw new Error('Failed to create contact');
    }
  }

  /**
   * Get contact by ID with full 360° view
   */
  async getContact360(contactId: string, organizationId: string): Promise<any> {
    const cacheKey = `contact:360:${contactId}`;

    // Try cache first
    const cached = await this.cache.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    try {
      // Get contact details
      const contactQuery = `
        SELECT c.*, 
               u.first_name || ' ' || u.last_name AS owner_name,
               u.email AS owner_email,
               l.lead_score AS original_lead_score
        FROM contacts c
        LEFT JOIN users u ON c.owner_id = u.id
        LEFT JOIN leads l ON c.lead_id = l.id
        WHERE c.id = $1 AND c.organization_id = $2
      `;
      const contactResult = await this.db.query(contactQuery, [contactId, organizationId]);

      if (contactResult.rows.length === 0) {
        return null;
      }

      const contact = contactResult.rows[0];

      // Get all deals
      const dealsQuery = `
        SELECT d.*, p.name AS pipeline_name
        FROM deals d
        LEFT JOIN pipelines p ON d.pipeline_id = p.id
        WHERE d.contact_id = $1
        ORDER BY d.created_at DESC
      `;
      const dealsResult = await this.db.query(dealsQuery, [contactId]);

      // Get recent activities
      const activitiesQuery = `
        SELECT a.*, u.first_name || ' ' || u.last_name AS assigned_to_name
        FROM activities a
        LEFT JOIN users u ON a.assigned_to = u.id
        WHERE a.related_to_type = 'contact' AND a.related_to_id = $1
        ORDER BY a.created_at DESC
        LIMIT 50
      `;
      const activitiesResult = await this.db.query(activitiesQuery, [contactId]);

      // Get email history
      const emailsQuery = `
        SELECT *
        FROM emails
        WHERE related_to_type = 'contact' AND related_to_id = $1
        ORDER BY created_at DESC
        LIMIT 100
      `;
      const emailsResult = await this.db.query(emailsQuery, [contactId]);

      // Calculate engagement metrics
      const engagementQuery = `
        SELECT 
          COUNT(CASE WHEN type = 'email' THEN 1 END) AS email_count,
          COUNT(CASE WHEN type = 'call' THEN 1 END) AS call_count,
          COUNT(CASE WHEN type = 'meeting' THEN 1 END) AS meeting_count,
          MAX(created_at) AS last_activity_date
        FROM activities
        WHERE related_to_type = 'contact' AND related_to_id = $1
      `;
      const engagementResult = await this.db.query(engagementQuery, [contactId]);

      // Build 360° view
      const contact360 = {
        ...contact,
        deals: dealsResult.rows,
        recent_activities: activitiesResult.rows,
        email_history: emailsResult.rows,
        engagement_metrics: engagementResult.rows[0],
        total_deal_value: dealsResult.rows.reduce((sum, d) => sum + parseFloat(d.amount || 0), 0),
        won_deals_count: dealsResult.rows.filter(d => d.status === 'won').length,
        open_deals_count: dealsResult.rows.filter(d => d.status === 'open').length
      };

      // Cache for 2 minutes
      await this.cache.set(cacheKey, JSON.stringify(contact360), 120);

      return contact360;

    } catch (error) {
      this.logger.error('Error fetching contact 360:', error);
      throw error;
    }
  }

  /**
   * Get contact timeline (activity feed)
   */
  async getContactTimeline(contactId: string, organizationId: string): Promise<ContactTimeline> {
    try {
      const query = `
        SELECT 
          'activity' AS source,
          a.id,
          a.type,
          a.subject,
          a.description,
          a.created_at,
          u.first_name || ' ' || u.last_name AS created_by_name
        FROM activities a
        LEFT JOIN users u ON a.assigned_to = u.id
        WHERE a.related_to_type = 'contact' AND a.related_to_id = $1
        
        UNION ALL
        
        SELECT 
          'email' AS source,
          e.id,
          'email' AS type,
          e.subject,
          e.body_text AS description,
          e.created_at,
          e.from_address AS created_by_name
        FROM emails e
        WHERE e.related_to_type = 'contact' AND e.related_to_id = $1
        
        UNION ALL
        
        SELECT 
          'deal' AS source,
          d.id,
          'deal_stage_change' AS type,
          d.title AS subject,
          'Stage: ' || d.stage AS description,
          d.updated_at AS created_at,
          u.first_name || ' ' || u.last_name AS created_by_name
        FROM deals d
        LEFT JOIN users u ON d.owner_id = u.id
        WHERE d.contact_id = $1
        
        ORDER BY created_at DESC
        LIMIT 200
      `;

      const result = await this.db.query(query, [contactId]);

      return {
        activities: result.rows.filter(r => r.source === 'activity'),
        deals: result.rows.filter(r => r.source === 'deal'),
        emails: result.rows.filter(r => r.source === 'email'),
        calls: result.rows.filter(r => r.type === 'call'),
        notes: result.rows.filter(r => r.type === 'note')
      };

    } catch (error) {
      this.logger.error('Error fetching timeline:', error);
      throw error;
    }
  }

  /**
   * Update contact
   */
  async updateContact(contactId: string, organizationId: string, updates: Partial<Contact>): Promise<Contact> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramCount = 0;

    Object.entries(updates).forEach(([key, value]) => {
      if (value !== undefined && key !== 'id' && key !== 'organization_id') {
        paramCount++;
        if (typeof value === 'object' && !Array.isArray(value)) {
          setClauses.push(`${key} = $${paramCount}::jsonb`);
          values.push(JSON.stringify(value));
        } else {
          setClauses.push(`${key} = $${paramCount}`);
          values.push(value);
        }
      }
    });

    if (setClauses.length === 0) {
      throw new Error('No fields to update');
    }

    paramCount++;
    values.push(contactId);
    paramCount++;
    values.push(organizationId);

    const query = `
      UPDATE contacts
      SET ${setClauses.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramCount - 1} AND organization_id = $${paramCount}
      RETURNING *
    `;

    try {
      const result = await this.db.query(query, values);

      if (result.rows.length === 0) {
        throw new Error('Contact not found');
      }

      const updatedContact = result.rows[0];

      // Update search index
      await this.search.indexContact(updatedContact);

      // Invalidate cache
      await this.cache.del(`contact:${contactId}`);
      await this.cache.del(`contact:360:${contactId}`);
      await this.cache.del(`contacts:org:${organizationId}`);

      // Publish event
      await this.events.publish('contact.updated', {
        contact_id: contactId,
        organization_id: organizationId,
        updates: Object.keys(updates),
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Contact updated: ${contactId}`);
      return updatedContact;

    } catch (error) {
      this.logger.error('Error updating contact:', error);
      throw error;
    }
  }

  /**
   * Search contacts (Elasticsearch)
   */
  async searchContacts(organizationId: string, searchTerm: string, filters?: any): Promise<any[]> {
    try {
      const results = await this.search.searchContacts({
        organization_id: organizationId,
        search: searchTerm,
        ...filters
      });

      return results;

    } catch (error) {
      this.logger.error('Error searching contacts:', error);
      throw error;
    }
  }

  /**
   * Convert lead to contact
   */
  async convertLeadToContact(leadId: string, organizationId: string): Promise<Contact> {
    const client = await this.db.connect();

    try {
      await client.query('BEGIN');

      // Get lead details
      const leadQuery = 'SELECT * FROM leads WHERE id = $1 AND organization_id = $2';
      const leadResult = await client.query(leadQuery, [leadId, organizationId]);

      if (leadResult.rows.length === 0) {
        throw new Error('Lead not found');
      }

      const lead = leadResult.rows[0];

      // Create contact from lead
      const contact = await this.createContact({
        organization_id: organizationId,
        lead_id: leadId,
        first_name: lead.first_name,
        last_name: lead.last_name,
        email: lead.email,
        phone: lead.phone,
        company: lead.company,
        job_title: lead.job_title,
        lifecycle_stage: 'lead',
        owner_id: lead.assigned_to,
        address: lead.address,
        custom_fields: lead.custom_fields,
        tags: lead.tags
      });

      // Update lead status
      await client.query(
        'UPDATE leads SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
        ['converted', leadId]
      );

      await client.query('COMMIT');

      // Publish event
      await this.events.publish('lead.converted', {
        lead_id: leadId,
        contact_id: contact.id,
        organization_id: organizationId,
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Lead ${leadId} converted to contact ${contact.id}`);
      return contact;

    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Error converting lead:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Merge duplicate contacts
   */
  async mergeContacts(primaryId: string, duplicateIds: string[], organizationId: string): Promise<Contact> {
    const client = await this.db.connect();

    try {
      await client.query('BEGIN');

      // Get primary contact
      const primaryQuery = 'SELECT * FROM contacts WHERE id = $1 AND organization_id = $2';
      const primaryResult = await client.query(primaryQuery, [primaryId, organizationId]);

      if (primaryResult.rows.length === 0) {
        throw new Error('Primary contact not found');
      }

      // Move all related records to primary contact
      for (const duplicateId of duplicateIds) {
        // Move deals
        await client.query(
          'UPDATE deals SET contact_id = $1 WHERE contact_id = $2',
          [primaryId, duplicateId]
        );

        // Move activities
        await client.query(
          'UPDATE activities SET related_to_id = $1 WHERE related_to_type = $2 AND related_to_id = $3',
          [primaryId, 'contact', duplicateId]
        );

        // Move emails
        await client.query(
          'UPDATE emails SET related_to_id = $1 WHERE related_to_type = $2 AND related_to_id = $3',
          [primaryId, 'contact', duplicateId]
        );

        // Delete duplicate
        await client.query('DELETE FROM contacts WHERE id = $1', [duplicateId]);
      }

      await client.query('COMMIT');

      // Invalidate cache
      await this.cache.del(`contact:${primaryId}`);
      await this.cache.del(`contact:360:${primaryId}`);

      this.logger.info(`Merged ${duplicateIds.length} contacts into ${primaryId}`);
      return primaryResult.rows[0];

    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('Error merging contacts:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get contact insights (AI-powered)
   */
  async getContactInsights(contactId: string, organizationId: string): Promise<any> {
    try {
      const contact360 = await this.getContact360(contactId, organizationId);

      // Calculate insights
      const insights = {
        engagement_level: this.calculateEngagementLevel(contact360),
        next_best_action: this.predictNextAction(contact360),
        churn_risk: this.calculateChurnRisk(contact360),
        lifetime_value: contact360.total_deal_value,
        health_score: this.calculateHealthScore(contact360)
      };

      return insights;

    } catch (error) {
      this.logger.error('Error calculating insights:', error);
      throw error;
    }
  }

  // Helper methods
  private calculateEngagementLevel(contact: any): string {
    const metrics = contact.engagement_metrics;
    const totalEngagements = 
      (metrics.email_count || 0) + 
      (metrics.call_count || 0) + 
      (metrics.meeting_count || 0);

    if (totalEngagements > 20) return 'high';
    if (totalEngagements > 10) return 'medium';
    return 'low';
  }

  private predictNextAction(contact: any): string {
    const lastActivity = contact.engagement_metrics?.last_activity_date;
    if (!lastActivity) return 'Initial Outreach';

    const daysSinceLastActivity = Math.floor(
      (Date.now() - new Date(lastActivity).getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysSinceLastActivity > 30) return 'Re-engagement Email';
    if (daysSinceLastActivity > 14) return 'Follow-up Call';
    if (contact.open_deals_count > 0) return 'Deal Progression';
    return 'Nurture Campaign';
  }

  private calculateChurnRisk(contact: any): number {
    const lastActivity = contact.engagement_metrics?.last_activity_date;
    if (!lastActivity) return 80;

    const daysSinceLastActivity = Math.floor(
      (Date.now() - new Date(lastActivity).getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysSinceLastActivity > 90) return 90;
    if (daysSinceLastActivity > 60) return 70;
    if (daysSinceLastActivity > 30) return 50;
    return 20;
  }

  private calculateHealthScore(contact: any): number {
    let score = 50;

    // Engagement boost
    const engagementLevel = this.calculateEngagementLevel(contact);
    if (engagementLevel === 'high') score += 30;
    else if (engagementLevel === 'medium') score += 15;

    // Deal activity
    if (contact.open_deals_count > 0) score += 20;
    if (contact.won_deals_count > 0) score += 10;

    // Recent activity
    const churnRisk = this.calculateChurnRisk(contact);
    score -= Math.floor(churnRisk / 5);

    return Math.max(0, Math.min(100, score));
  }
}