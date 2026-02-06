import { createClient, SupabaseClient as Client } from '@supabase/supabase-js';

export class SupabaseClient {
  private static instance: Client;

  public static getInstance(): Client {
    if (!SupabaseClient.instance) {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

      if (!supabaseUrl || !supabaseKey) {
        console.warn('Supabase credentials not configured. Online features will be disabled.');
        // Return a mock client that fails gracefully
        return this.createMockClient();
      }

      SupabaseClient.instance = createClient(supabaseUrl, supabaseKey, {
        auth: {
          persistSession: false,
          autoRefreshToken: false
        }
      });
    }

    return SupabaseClient.instance;
  }

  private static createMockClient(): any {
    return {
      from: () => ({
        select: () => Promise.resolve({ data: [], error: new Error('Supabase not configured') }),
        insert: () => Promise.resolve({ data: null, error: new Error('Supabase not configured') }),
        update: () => Promise.resolve({ data: null, error: new Error('Supabase not configured') }),
        delete: () => Promise.resolve({ data: null, error: new Error('Supabase not configured') }),
        upsert: () => Promise.resolve({ data: null, error: new Error('Supabase not configured') })
      })
    };
  }
}