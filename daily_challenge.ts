import { SupabaseClient } from '../services/SupabaseClient';
import { StorageService } from '../services/StorageService';

export class DailyChallenge {
  private supabase = SupabaseClient.getInstance();
  private storage = new StorageService();

  public async getDailySeed(): Promise<string> {
    const today = this.getTodayString();
    
    // Check cache first
    const cachedSeed = this.storage.get(`dailySeed_${today}`, '');
    if (cachedSeed) {
      return cachedSeed;
    }

    try {
      // Fetch from Supabase
      const { data, error } = await this.supabase
        .from('daily_challenges')
        .select('seed')
        .eq('day', today)
        .single();

      if (error) {
        // If no seed exists for today, create one
        if (error.code === 'PGRST116') {
          return await this.createTodaySeed();
        }
        throw error;
      }

      if (data && data.seed) {
        this.storage.set(`dailySeed_${today}`, data.seed);
        return data.seed;
      }

      // Fallback: create seed if none exists
      return await this.createTodaySeed();
    } catch (error) {
      console.error('Failed to get daily seed:', error);
      // Fallback to local seed based on date
      return this.generateLocalSeed(today);
    }
  }

  private async createTodaySeed(): Promise<string> {
    const today = this.getTodayString();
    const seed = this.generateLocalSeed(today);

    try {
      const { error } = await this.supabase
        .from('daily_challenges')
        .insert({
          day: today,
          seed: seed
        });

      if (error) {
        console.error('Failed to create daily seed:', error);
      }

      this.storage.set(`dailySeed_${today}`, seed);
      return seed;
    } catch (error) {
      console.error('Failed to create daily seed:', error);
      return seed;
    }
  }

  private getTodayString(): string {
    const now = new Date();
    return now.toISOString().split('T')[0]; // YYYY-MM-DD
  }

  private generateLocalSeed(dateString: string): string {
    // Generate deterministic seed from date
    let hash = 0;
    for (let i = 0; i < dateString.length; i++) {
      hash = ((hash << 5) - hash) + dateString.charCodeAt(i);
      hash = hash & hash;
    }
    return Math.abs(hash).toString();
  }
}