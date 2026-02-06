import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '@you-pdf/core';
import type { Job, User } from '@you-pdf/core';

export function createSupabaseClient(useServiceKey: boolean = false): SupabaseClient {
  const key = useServiceKey ? config.supabase.serviceKey : config.supabase.anonKey;
  return createClient(config.supabase.url, key);
}

export async function getUserById(supabase: SupabaseClient, userId: string): Promise<User | null> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (error || !data) return null;
  return data as User;
}

export async function createUser(
  supabase: SupabaseClient,
  userId: string,
  email: string
): Promise<User | null> {
  const { data, error } = await supabase
    .from('users')
    .insert({
      id: userId,
      email,
      tier: 'free',
      daily_usage: 0,
      usage_reset_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    })
    .select()
    .single();

  if (error || !data) return null;
  return data as User;
}

export async function incrementDailyUsage(
  supabase: SupabaseClient,
  userId: string
): Promise<boolean> {
  const { error } = await supabase
    .from('users')
    .update({
      daily_usage: supabase.rpc('increment_daily_usage', { user_id: userId }),
    })
    .eq('id', userId);

  return !error;
}

export async function getJobById(
  supabase: SupabaseClient,
  jobId: string
): Promise<Job | null> {
  const { data, error } = await supabase
    .from('jobs')
    .select('*')
    .eq('id', jobId)
    .single();

  if (error || !data) return null;
  return data as Job;
}

export async function createJob(
  supabase: SupabaseClient,
  job: Partial<Job>
): Promise<string | null> {
  const { data, error } = await supabase
    .from('jobs')
    .insert(job)
    .select('id')
    .single();

  if (error || !data) return null;
  return data.id;
}

export async function updateJob(
  supabase: SupabaseClient,
  jobId: string,
  updates: Partial<Job>
): Promise<boolean> {
  const { error } = await supabase
    .from('jobs')
    .update({
      ...updates,
      updated_at: new Date().toISOString(),
    })
    .eq('id', jobId);

  return !error;
}

export async function getRecentJobs(
  supabase: SupabaseClient,
  userId: string,
  limit: number = 10
): Promise<Job[]> {
  const { data, error } = await supabase
    .from('jobs')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error || !data) return [];
  return data as Job[];
}

export async function cleanupExpiredJobs(supabase: SupabaseClient): Promise<number> {
  const { data, error } = await supabase
    .from('jobs')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .in('status', ['completed', 'failed']);

  if (error) return 0;
  return data?.length || 0;
}

export async function resetDailyUsage(supabase: SupabaseClient): Promise<boolean> {
  const { error } = await supabase
    .from('users')
    .update({
      daily_usage: 0,
      usage_reset_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    })
    .lt('usage_reset_at', new Date().toISOString());

  return !error;
}

export async function updateUserTier(
  supabase: SupabaseClient,
  userId: string,
  tier: 'free' | 'pro' | 'business'
): Promise<boolean> {
  const { error } = await supabase
    .from('users')
    .update({ tier })
    .eq('id', userId);

  return !error;
}

export async function getUserUsageStats(
  supabase: SupabaseClient,
  userId: string
): Promise<{ today: number; thisMonth: number; total: number }> {
  const today = new Date().toISOString().split('T')[0];
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);

  const { count: todayCount } = await supabase
    .from('jobs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', today);

  const { count: monthCount } = await supabase
    .from('jobs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', monthStart.toISOString());

  const { count: totalCount } = await supabase
    .from('jobs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);

  return {
    today: todayCount || 0,
    thisMonth: monthCount || 0,
    total: totalCount || 0,
  };
}