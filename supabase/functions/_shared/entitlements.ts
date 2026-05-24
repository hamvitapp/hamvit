import { admin } from './supabase.ts';

export async function hasPremiumLifetime(userId: string): Promise<boolean> {
  const { data } = await admin
    .from('user_entitlements')
    .select('plan, active')
    .eq('user_id', userId)
    .eq('plan', 'premium_lifetime')
    .eq('active', true)
    .maybeSingle();

  return Boolean(data);
}
