import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

export async function createFoodPhotoAnalysis({ userId, storagePath }) {
  const { data: usage } = await supabase
    .from('ai_usage_limits')
    .select('*')
    .eq('user_id', userId)
    .eq('feature', 'food_photo')
    .eq('usage_date', new Date().toISOString().slice(0, 10))
    .maybeSingle();

  const used = Number(usage?.used_count || 0);
  if (used >= 3) return { allowed: false, reason: 'daily_limit_reached' };

  if (usage) {
    await supabase.from('ai_usage_limits').update({ used_count: used + 1 }).eq('id', usage.id);
  } else {
    await supabase.from('ai_usage_limits').insert({
      user_id: userId,
      feature: 'food_photo',
      usage_date: new Date().toISOString().slice(0, 10),
      used_count: 1,
    });
  }

  const estimated = {
    notice: 'Valores estimados e ajustáveis. Confirme antes de salvar.',
    items: [
      { name: 'Item detectado', portion: '1 porção', calories: 250, protein_g: 12, carbs_g: 30, fats_g: 8 },
    ],
  };

  const { data } = await supabase
    .from('food_photo_analyses')
    .insert({ user_id: userId, storage_path: storagePath, result: estimated, status: 'needs_review' })
    .select('*')
    .single();

  return { allowed: true, analysis: data };
}
