// Backend helper layer for Supabase Edge/Node.
// Env vars required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, OPEN_FOOD_FACTS_BASE_URL
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

export async function generatePremiumMealSuggestions({ userId, date, mealType }) {
  const { data: entitlement } = await supabase
    .from('user_entitlements')
    .select('plan, active')
    .eq('user_id', userId)
    .eq('plan', 'premium_lifetime')
    .eq('active', true)
    .maybeSingle();

  if (!entitlement) return { blocked: true, reason: 'premium_required' };

  const day = date.slice(0, 10);
  const [{ data: targets }, { data: consumedRows }, { data: recipes }] = await Promise.all([
    supabase.from('daily_nutrition_targets').select('*').eq('user_id', userId).eq('target_date', day).maybeSingle(),
    supabase.from('meal_items').select('calories, protein_g, carbs_g, fats_g, meal_logs!inner(user_id, consumed_at)').eq('meal_logs.user_id', userId),
    supabase.from('recipes').select('id,name,prep_time_min,recipe_nutrition_profiles(calories,protein_g,carbs_g,fats_g)').limit(300),
  ]);

  const consumed = (consumedRows || []).reduce(
    (acc, item) => ({
      calories: acc.calories + Number(item.calories || 0),
      protein_g: acc.protein_g + Number(item.protein_g || 0),
      carbs_g: acc.carbs_g + Number(item.carbs_g || 0),
      fats_g: acc.fats_g + Number(item.fats_g || 0),
    }),
    { calories: 0, protein_g: 0, carbs_g: 0, fats_g: 0 }
  );

  const target = targets || { calories: 2000, protein_g: 120, carbs_g: 220, fats_g: 70 };

  const scored = (recipes || []).map((r) => {
    const n = r.recipe_nutrition_profiles?.[0] || {};
    const dCal = Math.abs((target.calories - consumed.calories) - Number(n.calories || 0));
    const dPro = Math.abs((target.protein_g - consumed.protein_g) - Number(n.protein_g || 0));
    const dCarb = Math.abs((target.carbs_g - consumed.carbs_g) - Number(n.carbs_g || 0));
    const dFat = Math.abs((target.fats_g - consumed.fats_g) - Number(n.fats_g || 0));
    const score = 1000 - dCal * 1.4 - dPro * 2 - dCarb * 1.2 - dFat * 1.2;
    return { recipe_id: r.id, meal_type: mealType, score, reason: { dCal, dPro, dCarb, dFat } };
  });

  const suggestions = scored.sort((a, b) => b.score - a.score).slice(0, 5);

  if (suggestions.length > 0) {
    await supabase.from('user_meal_plan_suggestions').insert(
      suggestions.map((s) => ({
        user_id: userId,
        suggestion_date: day,
        meal_type: s.meal_type,
        recipe_id: s.recipe_id,
        score: s.score,
        reason: s.reason,
      }))
    );
  }

  return { blocked: false, suggestions };
}

export async function enforcePremiumPhotoLimit({ userId, date }) {
  const day = date.slice(0, 10);
  const { data: entitlement } = await supabase
    .from('user_entitlements')
    .select('plan, active')
    .eq('user_id', userId)
    .eq('plan', 'premium_lifetime')
    .eq('active', true)
    .maybeSingle();
  if (!entitlement) return { allowed: false, reason: 'premium_required' };

  const { data: usage } = await supabase
    .from('ai_usage_limits')
    .select('*')
    .eq('user_id', userId)
    .eq('feature', 'food_photo')
    .eq('usage_date', day)
    .maybeSingle();

  const used = Number(usage?.used_count || 0);
  if (used >= 3) return { allowed: false, reason: 'daily_limit_reached' };

  if (usage) {
    await supabase.from('ai_usage_limits').update({ used_count: used + 1 }).eq('id', usage.id);
  } else {
    await supabase.from('ai_usage_limits').insert({ user_id: userId, feature: 'food_photo', usage_date: day, used_count: 1 });
  }

  return { allowed: true };
}

export async function resolveBarcode(barcode) {
  const { data: local } = await supabase.from('barcode_lookups').select('*, foods(*)').eq('barcode', barcode).maybeSingle();
  if (local) return { source: 'supabase', data: local };

  const base = process.env.OPEN_FOOD_FACTS_BASE_URL || 'https://world.openfoodfacts.org/api/v2/product';
  const resp = await fetch(`${base}/${barcode}.json`);
  if (!resp.ok) return { source: 'not_found', data: null };
  const body = await resp.json();
  return { source: 'open_food_facts', data: body };
}
