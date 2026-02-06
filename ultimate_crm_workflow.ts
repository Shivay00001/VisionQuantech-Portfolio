import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '../utils/logger';
import { RedisManager } from '../cache/redis';
import { KafkaManager } from '../events/kafka';
import { EmailService } from './email.service';

interface Workflow {
  id?: string;
  organization_id: string;
  name: string;
  description?: string;
  trigger_type: 'lead_created' | 'deal_stage_changed' | 'contact_updated' | 'scheduled' | 'manual';
  trigger_config: TriggerConfig;
  conditions: WorkflowCondition[];
  actions: WorkflowAction[];
  is_active?: boolean;
  created_by?: string;
}

interface TriggerConfig {
  entity_type?: string;
  field?: string;
  operator?: string;
  value?: any;
  schedule?: string; // cron expression for scheduled workflows
}

interface WorkflowCondition {
  field: string;
  operator: 'equals' | 'not_equals' | 'contains' | 'greater_than' | 'less_than' | 'in' | 'not_in';
  value: any;
  logic?: 'AND' | 'OR';
}

interface WorkflowAction {
  type: 'send_email' | 'create_task' | 'update_field' | 'send_notification' | 'webhook' | 'wait';
  config: ActionConfig;
  delay_minutes?: number;
}

interface ActionConfig {
  // Email action
  template_id?: string;
  to?: string[];
  subject?: string;
  body?: string;
  
  // Task action
  task_title?: string;
  task_description?: string;
  assign_to?: string;
  due_date_offset_days?: number;
  
  // Field update action
  field_name?: string;
  field_value?: any;
  
  // Webhook action
  url?: string;
  method?: string;
  headers?: Record<string, string>;
  body_template?: string;
  
  // Wait action
  wait_minutes?: number;
}

interface WorkflowExecution {
  id?: string;
  workflow_id: string;
  trigger_data: any;
  status: 'running' | 'completed' | 'failed' | 'paused';
  current_step: number;
  error_message?: string;
  started_at?: Date;
  completed_at?: Date;
}

export class WorkflowService {
  private logger: Logger;
  private db: Pool;
  private cache: RedisManager;
  private events: KafkaManager;
  private emailService: EmailService;

  constructor(
    db: Pool, 
    cache: RedisManager, 
    events: KafkaManager,
    emailService: EmailService
  ) {
    this.logger = new Logger('WorkflowService');
    this.db = db;
    this.cache = cache;
    this.events = events;
    this.emailService = emailService;

    // Subscribe to workflow triggers
    this.subscribeToTriggers();
  }

  /**
   * Create workflow
   */
  async createWorkflow(workflow: Workflow): Promise<Workflow> {
    const workflowId = uuidv4();
    const now = new Date();

    const query = `
      INSERT INTO workflows (
        id, organization_id, name, description, trigger_type,
        trigger_config, conditions, actions, is_active,
        created_by, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *
    `;

    const values = [
      workflowId,
      workflow.organization_id,
      workflow.name,
      workflow.description,
      workflow.trigger_type,
      JSON.stringify(workflow.trigger_config),
      JSON.stringify(workflow.conditions),
      JSON.stringify(workflow.actions),
      workflow.is_active !== false,
      workflow.created_by,
      now,
      now
    ];

    try {
      const result = await this.db.query(query, values);
      const createdWorkflow = result.rows[0];

      await this.cache.del(`workflows:org:${workflow.organization_id}`);

      await this.events.publish('workflow.created', {
        workflow_id: workflowId,
        organization_id: workflow.organization_id,
        trigger_type: workflow.trigger_type,
        timestamp: now.toISOString()
      });

      this.logger.info(`Workflow created: ${workflowId}`);
      return createdWorkflow;

    } catch (error) {
      this.logger.error('Error creating workflow:', error);
      throw new Error('Failed to create workflow');
    }
  }

  /**
   * Execute workflow
   */
  async executeWorkflow(workflowId: string, triggerData: any): Promise<WorkflowExecution> {
    const executionId = uuidv4();
    const now = new Date();

    try {
      // Get workflow
      const workflowQuery = 'SELECT * FROM workflows WHERE id = $1 AND is_active = true';
      const workflowResult = await this.db.query(workflowQuery, [workflowId]);

      if (workflowResult.rows.length === 0) {
        throw new Error('Workflow not found or inactive');
      }

      const workflow = workflowResult.rows[0];

      // Check conditions
      const conditionsMet = await this.evaluateConditions(workflow.conditions, triggerData);

      if (!conditionsMet) {
        this.logger.info(`Workflow ${workflowId} conditions not met`);
        return {
          id: executionId,
          workflow_id: workflowId,
          trigger_data: triggerData,
          status: 'completed',
          current_step: 0,
          started_at: now,
          completed_at: now
        };
      }

      // Create execution record
      const execQuery = `
        INSERT INTO workflow_executions (
          id, workflow_id, trigger_data, status, current_step, started_at
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `;

      await this.db.query(execQuery, [
        executionId,
        workflowId,
        JSON.stringify(triggerData),
        'running',
        0,
        now
      ]);

      // Execute actions sequentially
      const actions = workflow.actions;
      for (let i = 0; i < actions.length; i++) {
        const action = actions[i];

        try {
          // Wait if delay specified
          if (action.delay_minutes && action.delay_minutes > 0) {
            await new Promise(resolve => setTimeout(resolve, action.delay_minutes * 60 * 1000));
          }

          // Execute action
          await this.executeAction(action, triggerData, workflow.organization_id);

          // Update execution progress
          await this.db.query(
            'UPDATE workflow_executions SET current_step = $1 WHERE id = $2',
            [i + 1, executionId]
          );

        } catch (actionError) {
          this.logger.error(`Error executing action ${i}:`, actionError);

          // Mark as failed
          await this.db.query(
            'UPDATE workflow_executions SET status = $1, error_message = $2, completed_at = $3 WHERE id = $4',
            ['failed', actionError.message, new Date(), executionId]
          );

          throw actionError;
        }
      }

      // Mark as completed
      await this.db.query(
        'UPDATE workflow_executions SET status = $1, completed_at = $2 WHERE id = $3',
        ['completed', new Date(), executionId]
      );

      // Update execution count
      await this.db.query(
        'UPDATE workflows SET execution_count = execution_count + 1, last_executed_at = $1 WHERE id = $2',
        [now, workflowId]
      );

      this.logger.info(`Workflow ${workflowId} executed successfully`);

      return {
        id: executionId,
        workflow_id: workflowId,
        trigger_data: triggerData,
        status: 'completed',
        current_step: actions.length,
        started_at: now,
        completed_at: new Date()
      };

    } catch (error) {
      this.logger.error('Error executing workflow:', error);
      throw error;
    }
  }

  /**
   * Execute single action
   */
  private async executeAction(
    action: WorkflowAction, 
    triggerData: any, 
    organizationId: string
  ): Promise<void> {
    switch (action.type) {
      case 'send_email':
        await this.executeSendEmailAction(action.config, triggerData, organizationId);
        break;

      case 'create_task':
        await this.executeCreateTaskAction(action.config, triggerData, organizationId);
        break;

      case 'update_field':
        await this.executeUpdateFieldAction(action.config, triggerData, organizationId);
        break;

      case 'webhook':
        await this.executeWebhookAction(action.config, triggerData);
        break;

      case 'wait':
        const waitMinutes = action.config.wait_minutes || 0;
        await new Promise(resolve => setTimeout(resolve, waitMinutes * 60 * 1000));
        break;

      default:
        this.logger.warn(`Unknown action type: ${action.type}`);
    }
  }

  /**
   * Execute send email action
   */
  private async executeSendEmailAction(
    config: ActionConfig, 
    triggerData: any, 
    organizationId: string
  ): Promise<void> {
    try {
      const recipients = this.interpolateValue(config.to, triggerData);
      const subject = this.interpolateValue(config.subject, triggerData);
      const body = this.interpolateValue(config.body, triggerData);

      await this.emailService.sendEmail({
        from: process.env.EMAIL_FROM || 'noreply@crm.local',
        to: Array.isArray(recipients) ? recipients : [recipients],
        subject: subject || 'CRM Notification',
        body_html: body,
        organization_id: organizationId,
        track_opens: true,
        track_clicks: true
      });

      this.logger.info('Email sent via workflow');

    } catch (error) {
      this.logger.error('Error sending email in workflow:', error);
      throw error;
    }
  }

  /**
   * Execute create task action
   */
  private async executeCreateTaskAction(
    config: ActionConfig, 
    triggerData: any, 
    organizationId: string
  ): Promise<void> {
    try {
      const taskId = uuidv4();
      const dueDate = new Date();
      if (config.due_date_offset_days) {
        dueDate.setDate(dueDate.getDate() + config.due_date_offset_days);
      }

      const query = `
        INSERT INTO activities (
          id, organization_id, type, subject, description,
          assigned_to, due_date, status, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `;

      await this.db.query(query, [
        taskId,
        organizationId,
        'task',
        this.interpolateValue(config.task_title, triggerData),
        this.interpolateValue(config.task_description, triggerData),
        config.assign_to,
        dueDate,
        'pending',
        new Date()
      ]);

      this.logger.info(`Task created via workflow: ${taskId}`);

    } catch (error) {
      this.logger.error('Error creating task in workflow:', error);
      throw error;
    }
  }

  /**
   * Execute update field action
   */
  private async executeUpdateFieldAction(
    config: ActionConfig, 
    triggerData: any, 
    organizationId: string
  ): Promise<void> {
    try {
      const entityType = triggerData.entity_type;
      const entityId = triggerData.entity_id;
      const fieldName = config.field_name;
      const fieldValue = this.interpolateValue(config.field_value, triggerData);

      if (!entityType || !entityId || !fieldName) {
        throw new Error('Missing required fields for update action');
      }

      const query = `
        UPDATE ${entityType}s
        SET ${fieldName} = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2 AND organization_id = $3
      `;

      await this.db.query(query, [fieldValue, entityId, organizationId]);

      this.logger.info(`Field ${fieldName} updated via workflow`);

    } catch (error) {
      this.logger.error('Error updating field in workflow:', error);
      throw error;
    }
  }

  /**
   * Execute webhook action
   */
  private async executeWebhookAction(config: ActionConfig, triggerData: any): Promise<void> {
    try {
      const url = config.url;
      const method = config.method || 'POST';
      const headers = config.headers || { 'Content-Type': 'application/json' };
      const body = this.interpolateValue(config.body_template, triggerData);

      const response = await fetch(url!, {
        method: method,
        headers: headers,
        body: typeof body === 'string' ? body : JSON.stringify(body)
      });

      if (!response.ok) {
        throw new Error(`Webhook failed with status ${response.status}`);
      }

      this.logger.info('Webhook executed successfully');

    } catch (error) {
      this.logger.error('Error executing webhook:', error);
      throw error;
    }
  }

  /**
   * Evaluate conditions
   */
  private async evaluateConditions(
    conditions: WorkflowCondition[], 
    data: any
  ): Promise<boolean> {
    if (conditions.length === 0) return true;

    for (const condition of conditions) {
      const fieldValue = this.getNestedValue(data, condition.field);
      const result = this.evaluateCondition(fieldValue, condition.operator, condition.value);

      if (condition.logic === 'OR' && result) {
        return true;
      }

      if (condition.logic === 'AND' && !result) {
        return false;
      }

      if (!condition.logic && !result) {
        return false;
      }
    }

    return true;
  }

  /**
   * Evaluate single condition
   */
  private evaluateCondition(fieldValue: any, operator: string, expectedValue: any): boolean {
    switch (operator) {
      case 'equals':
        return fieldValue == expectedValue;
      case 'not_equals':
        return fieldValue != expectedValue;
      case 'contains':
        return String(fieldValue).includes(String(expectedValue));
      case 'greater_than':
        return Number(fieldValue) > Number(expectedValue);
      case 'less_than':
        return Number(fieldValue) < Number(expectedValue);
      case 'in':
        return Array.isArray(expectedValue) && expectedValue.includes(fieldValue);
      case 'not_in':
        return Array.isArray(expectedValue) && !expectedValue.includes(fieldValue);
      default:
        return false;
    }
  }

  /**
   * Interpolate template variables
   */
  private interpolateValue(template: any, data: any): any {
    if (typeof template !== 'string') return template;

    return template.replace(/\{\{([^}]+)\}\}/g, (match, path) => {
      return this.getNestedValue(data, path.trim()) || match;
    });
  }

  /**
   * Get nested object value by path
   */
  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((current, key) => current?.[key], obj);
  }

  /**
   * Subscribe to workflow triggers
   */
  private subscribeToTriggers(): void {
    // Subscribe to Kafka events
    this.events.subscribe('lead.created', async (message: any) => {
      await this.handleTrigger('lead_created', message);
    });

    this.events.subscribe('deal.stage_changed', async (message: any) => {
      await this.handleTrigger('deal_stage_changed', message);
    });

    this.events.subscribe('contact.updated', async (message: any) => {
      await this.handleTrigger('contact_updated', message);
    });
  }

  /**
   * Handle trigger event
   */
  private async handleTrigger(triggerType: string, triggerData: any): Promise<void> {
    try {
      // Find all active workflows with this trigger
      const query = `
        SELECT * FROM workflows
        WHERE trigger_type = $1 
          AND organization_id = $2
          AND is_active = true
      `;

      const result = await this.db.query(query, [triggerType, triggerData.organization_id]);

      // Execute each workflow
      for (const workflow of result.rows) {
        await this.executeWorkflow(workflow.id, triggerData);
      }

    } catch (error) {
      this.logger.error('Error handling trigger:', error);
    }
  }

  /**
   * List workflows
   */
  async listWorkflows(organizationId: string): Promise<Workflow[]> {
    const query = `
      SELECT w.*, u.first_name || ' ' || u.last_name AS created_by_name
      FROM workflows w
      LEFT JOIN users u ON w.created_by = u.id
      WHERE w.organization_id = $1
      ORDER BY w.created_at DESC
    `;

    try {
      const result = await this.db.query(query, [organizationId]);
      return result.rows;

    } catch (error) {
      this.logger.error('Error listing workflows:', error);
      throw error;
    }
  }

  /**
   * Get workflow execution history
   */
  async getWorkflowExecutions(workflowId: string, limit: number = 50): Promise<any[]> {
    const query = `
      SELECT * FROM workflow_executions
      WHERE workflow_id = $1
      ORDER BY started_at DESC
      LIMIT $2
    `;

    try {
      const result = await this.db.query(query, [workflowId, limit]);
      return result.rows;

    } catch (error) {
      this.logger.error('Error fetching workflow executions:', error);
      throw error;
    }
  }
}