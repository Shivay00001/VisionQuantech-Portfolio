import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import nodemailer from 'nodemailer';
import { Logger } from '../utils/logger';
import { RedisManager } from '../cache/redis';
import { KafkaManager } from '../events/kafka';

interface EmailMessage {
  from: string;
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  body_text?: string;
  body_html?: string;
  attachments?: any[];
  related_to_type?: string;
  related_to_id?: string;
  organization_id: string;
  track_opens?: boolean;
  track_clicks?: boolean;
}

interface EmailTemplate {
  id?: string;
  organization_id: string;
  name: string;
  subject: string;
  body_html: string;
  variables?: string[];
  category?: string;
}

export class EmailService {
  private logger: Logger;
  private db: Pool;
  private cache: RedisManager;
  private events: KafkaManager;
  private transporter: any;

  constructor(db: Pool, cache: RedisManager, events: KafkaManager) {
    this.logger = new Logger('EmailService');
    this.db = db;
    this.cache = cache;
    this.events = events;
    
    // Initialize email transporter
    this.transporter = nodemailer.createTransporter({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
      }
    });
  }

  /**
   * Send email with tracking
   */
  async sendEmail(email: EmailMessage): Promise<any> {
    const emailId = uuidv4();
    const messageId = `<${emailId}@${process.env.SMTP_DOMAIN || 'crm.local'}>`;

    try {
      // Generate tracking pixel
      const trackingPixel = email.track_opens 
        ? `<img src="${process.env.API_URL}/api/v1/emails/${emailId}/track/open" width="1" height="1" />`
        : '';

      // Replace links with tracking links
      let bodyHtml = email.body_html || '';
      if (email.track_clicks && bodyHtml) {
        bodyHtml = this.injectClickTracking(bodyHtml, emailId);
      }

      // Add tracking pixel
      if (trackingPixel && bodyHtml) {
        bodyHtml += trackingPixel;
      }

      // Send email
      const info = await this.transporter.sendMail({
        from: email.from,
        to: email.to.join(', '),
        cc: email.cc?.join(', '),
        bcc: email.bcc?.join(', '),
        subject: email.subject,
        text: email.body_text,
        html: bodyHtml,
        messageId: messageId,
        attachments: email.attachments
      });

      // Store email in database
      const query = `
        INSERT INTO emails (
          id, organization_id, from_address, to_addresses, cc_addresses,
          bcc_addresses, subject, body_text, body_html, message_id,
          related_to_type, related_to_id, direction, status, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        RETURNING *
      `;

      const values = [
        emailId,
        email.organization_id,
        email.from,
        email.to,
        email.cc || [],
        email.bcc || [],
        email.subject,
        email.body_text,
        email.body_html,
        messageId,
        email.related_to_type,
        email.related_to_id,
        'outbound',
        'sent',
        new Date()
      ];

      const result = await this.db.query(query, values);

      // Publish event
      await this.events.publish('email.sent', {
        email_id: emailId,
        organization_id: email.organization_id,
        to: email.to,
        subject: email.subject,
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Email sent: ${emailId} to ${email.to.join(', ')}`);
      return result.rows[0];

    } catch (error) {
      this.logger.error('Error sending email:', error);
      
      // Store failed email
      await this.db.query(`
        INSERT INTO emails (
          id, organization_id, from_address, to_addresses, subject,
          body_text, body_html, direction, status, metadata, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      `, [
        emailId,
        email.organization_id,
        email.from,
        email.to,
        email.subject,
        email.body_text,
        email.body_html,
        'outbound',
        'failed',
        JSON.stringify({ error: error.message }),
        new Date()
      ]);

      throw new Error('Failed to send email');
    }
  }

  /**
   * Track email open
   */
  async trackEmailOpen(emailId: string): Promise<void> {
    try {
      const query = `
        UPDATE emails
        SET opened_at = CURRENT_TIMESTAMP,
            metadata = jsonb_set(
              COALESCE(metadata, '{}'::jsonb),
              '{open_count}',
              (COALESCE((metadata->>'open_count')::int, 0) + 1)::text::jsonb
            )
        WHERE id = $1 AND opened_at IS NULL
      `;

      await this.db.query(query, [emailId]);

      // Publish event
      await this.events.publish('email.opened', {
        email_id: emailId,
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Email opened: ${emailId}`);

    } catch (error) {
      this.logger.error('Error tracking email open:', error);
    }
  }

  /**
   * Track email click
   */
  async trackEmailClick(emailId: string, url: string): Promise<void> {
    try {
      const query = `
        UPDATE emails
        SET clicked_at = CURRENT_TIMESTAMP,
            metadata = jsonb_set(
              COALESCE(metadata, '{}'::jsonb),
              '{clicked_urls}',
              COALESCE(metadata->'clicked_urls', '[]'::jsonb) || $2::jsonb
            )
        WHERE id = $1
      `;

      await this.db.query(query, [emailId, JSON.stringify([url])]);

      // Publish event
      await this.events.publish('email.clicked', {
        email_id: emailId,
        url: url,
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Email link clicked: ${emailId} - ${url}`);

    } catch (error) {
      this.logger.error('Error tracking email click:', error);
    }
  }

  /**
   * Send bulk emails (campaign)
   */
  async sendBulkEmails(
    organizationId: string,
    recipients: string[],
    subject: string,
    body: string,
    templateId?: string
  ): Promise<{ sent: number; failed: number }> {
    let sent = 0;
    let failed = 0;

    // Get template if provided
    let emailBody = body;
    if (templateId) {
      const template = await this.getTemplate(templateId, organizationId);
      if (template) {
        emailBody = template.body_html;
      }
    }

    // Send in batches of 50
    const batchSize = 50;
    for (let i = 0; i < recipients.length; i += batchSize) {
      const batch = recipients.slice(i, i + batchSize);

      for (const recipient of batch) {
        try {
          await this.sendEmail({
            from: process.env.EMAIL_FROM || 'noreply@crm.local',
            to: [recipient],
            subject: subject,
            body_html: emailBody,
            organization_id: organizationId,
            track_opens: true,
            track_clicks: true
          });
          sent++;
        } catch (error) {
          failed++;
          this.logger.error(`Failed to send to ${recipient}:`, error);
        }
      }

      // Wait 1 second between batches to avoid rate limits
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    this.logger.info(`Bulk email campaign completed: ${sent} sent, ${failed} failed`);
    return { sent, failed };
  }

  /**
   * Create email template
   */
  async createTemplate(template: EmailTemplate): Promise<EmailTemplate> {
    const templateId = uuidv4();

    const query = `
      INSERT INTO email_templates (
        id, organization_id, name, subject, body_html,
        variables, category, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;

    const values = [
      templateId,
      template.organization_id,
      template.name,
      template.subject,
      template.body_html,
      JSON.stringify(template.variables || []),
      template.category || 'general',
      new Date(),
      new Date()
    ];

    try {
      const result = await this.db.query(query, values);
      this.logger.info(`Template created: ${templateId}`);
      return result.rows[0];

    } catch (error) {
      this.logger.error('Error creating template:', error);
      throw new Error('Failed to create template');
    }
  }

  /**
   * Get template
   */
  async getTemplate(templateId: string, organizationId: string): Promise<EmailTemplate | null> {
    const query = `
      SELECT * FROM email_templates
      WHERE id = $1 AND organization_id = $2
    `;

    try {
      const result = await this.db.query(query, [templateId, organizationId]);
      return result.rows.length > 0 ? result.rows[0] : null;

    } catch (error) {
      this.logger.error('Error fetching template:', error);
      throw error;
    }
  }

  /**
   * List templates
   */
  async listTemplates(organizationId: string, category?: string): Promise<EmailTemplate[]> {
    let query = 'SELECT * FROM email_templates WHERE organization_id = $1';
    const params: any[] = [organizationId];

    if (category) {
      query += ' AND category = $2';
      params.push(category);
    }

    query += ' ORDER BY created_at DESC';

    try {
      const result = await this.db.query(query, params);
      return result.rows;

    } catch (error) {
      this.logger.error('Error listing templates:', error);
      throw error;
    }
  }

  /**
   * Get email analytics
   */
  async getEmailAnalytics(organizationId: string, days: number = 30): Promise<any> {
    try {
      const query = `
        SELECT 
          COUNT(*) AS total_sent,
          COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END) AS total_opened,
          COUNT(CASE WHEN clicked_at IS NOT NULL THEN 1 END) AS total_clicked,
          COUNT(CASE WHEN bounced_at IS NOT NULL THEN 1 END) AS total_bounced,
          ROUND(
            (COUNT(CASE WHEN opened_at IS NOT NULL THEN 1 END)::numeric / COUNT(*)::numeric) * 100, 
            2
          ) AS open_rate,
          ROUND(
            (COUNT(CASE WHEN clicked_at IS NOT NULL THEN 1 END)::numeric / COUNT(*)::numeric) * 100, 
            2
          ) AS click_rate
        FROM emails
        WHERE organization_id = $1
          AND direction = 'outbound'
          AND created_at >= CURRENT_DATE - INTERVAL '${days} days'
      `;

      const result = await this.db.query(query, [organizationId]);
      return result.rows[0];

    } catch (error) {
      this.logger.error('Error fetching email analytics:', error);
      throw error;
    }
  }

  /**
   * Inject click tracking into HTML
   */
  private injectClickTracking(html: string, emailId: string): string {
    // Replace all <a> tags with tracking links
    const urlRegex = /<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1/gi;
    
    return html.replace(urlRegex, (match, quote, url) => {
      const trackingUrl = `${process.env.API_URL}/api/v1/emails/${emailId}/track/click?url=${encodeURIComponent(url)}`;
      return `<a href=${quote}${trackingUrl}${quote}`;
    });
  }

  /**
   * Parse incoming email (webhook handler)
   */
  async parseIncomingEmail(rawEmail: any): Promise<void> {
    try {
      const emailId = uuidv4();
      
      // Extract email details
      const from = rawEmail.from || rawEmail.sender;
      const to = Array.isArray(rawEmail.to) ? rawEmail.to : [rawEmail.to];
      const subject = rawEmail.subject || '';
      const bodyText = rawEmail.text || '';
      const bodyHtml = rawEmail.html || '';

      // Find related contact by email
      const contactQuery = `
        SELECT c.*, o.id AS organization_id
        FROM contacts c
        JOIN organizations o ON c.organization_id = o.id
        WHERE c.email = $1
        LIMIT 1
      `;
      const contactResult = await this.db.query(contactQuery, [from]);

      let relatedToType = null;
      let relatedToId = null;
      let organizationId = null;

      if (contactResult.rows.length > 0) {
        const contact = contactResult.rows[0];
        relatedToType = 'contact';
        relatedToId = contact.id;
        organizationId = contact.organization_id;
      }

      // Store incoming email
      const query = `
        INSERT INTO emails (
          id, organization_id, from_address, to_addresses, subject,
          body_text, body_html, direction, status, related_to_type,
          related_to_id, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      `;

      await this.db.query(query, [
        emailId,
        organizationId,
        from,
        to,
        subject,
        bodyText,
        bodyHtml,
        'inbound',
        'received',
        relatedToType,
        relatedToId,
        new Date()
      ]);

      // Publish event
      await this.events.publish('email.received', {
        email_id: emailId,
        from: from,
        subject: subject,
        organization_id: organizationId,
        timestamp: new Date().toISOString()
      });

      this.logger.info(`Incoming email processed: ${emailId}`);

    } catch (error) {
      this.logger.error('Error parsing incoming email:', error);
      throw error;
    }
  }
}