// Deterministic Premium meal recommendation (v1 scaffold)
export function scoreRecipe(target, consumed, recipe, wasRecentlyUsed) {
  const remainingCal = Math.max((target.calories || 0) - (consumed.calories || 0), 0);
  const dCal = Math.abs(remainingCal - (recipe.calories || 0));
  const dPro = Math.abs((target.protein_g || 0) - (consumed.protein_g || 0) - (recipe.protein_g || 0));
  const dCarb = Math.abs((target.carbs_g || 0) - (consumed.carbs_g || 0) - (recipe.carbs_g || 0));
  const dFat = Math.abs((target.fats_g || 0) - (consumed.fats_g || 0) - (recipe.fats_g || 0));
  const repetitionPenalty = wasRecentlyUsed ? 50 : 0;
  return 1000 - (dCal * 1.5 + dPro * 2 + dCarb * 1.2 + dFat * 1.2 + repetitionPenalty);
}
