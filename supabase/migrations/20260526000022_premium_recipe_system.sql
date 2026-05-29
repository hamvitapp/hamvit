-- HAMVIT - Premium Recipe System
-- Migration 22: Complete recipe system with real consumption, favorites, feedback

-- 1. ENHANCE recipes TABLE
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS category text CHECK (category IN ('cafe_da_manha','almoco','jantar','lanche','ceia'));
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS prep_time_minutes int;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS servings int DEFAULT 1;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS calories_kcal numeric(8,2);
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS protein_g numeric(8,2);
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS carbs_g numeric(8,2);
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS fat_g numeric(8,2);
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS premium_only boolean NOT NULL DEFAULT false;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS difficulty text CHECK (difficulty IN ('facil','medio','dificil'));
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 2. ENHANCE recipe_ingredients
ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS quantity numeric(10,2);
ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS grams numeric(10,2);
ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS portion_label text;
ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS step_order int DEFAULT 1;
ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

-- 3. recipe_steps TABLE (replaces old preparation text with ordered steps)
CREATE TABLE IF NOT EXISTS recipe_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  step_order int NOT NULL,
  instruction text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 4. ENHANCE recipe_tags (make it simpler: direct tags per recipe)
-- First ensure recipe_tags exists with the right structure
-- We'll use a simpler approach: recipe_tags now stores tags directly per recipe
CREATE TABLE IF NOT EXISTS recipe_tags_direct (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id uuid NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  tag text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(recipe_id, tag)
);

-- Migrate existing tags from the old system if any
INSERT INTO recipe_tags_direct (recipe_id, tag)
SELECT rtl.recipe_id, rt.tag
FROM recipe_tag_links rtl
JOIN recipe_tags rt ON rt.id = rtl.tag_id
ON CONFLICT DO NOTHING;

-- 5. user_favorite_recipes TABLE
CREATE TABLE IF NOT EXISTS user_favorite_recipes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- 6. recipe_rejection_log (track "não gostei" for recommendation engine)
CREATE TABLE IF NOT EXISTS recipe_rejection_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipe_id uuid NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  reason text,
  created_at timestamptz DEFAULT now()
);

-- 7. ENHANCE meal_logs for recipe integration
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS recipe_id uuid REFERENCES recipes(id);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS servings numeric(5,2) DEFAULT 1;
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS meal_date date;
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS total_calories_kcal numeric(8,2);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS total_protein_g numeric(8,2);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS total_carbs_g numeric(8,2);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS total_fat_g numeric(8,2);
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 8. ENHANCE meal_items for richer data
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS ingredient_text text;
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS quantity numeric(10,2);
ALTER TABLE meal_items ADD COLUMN IF NOT EXISTS grams numeric(10,2);

-- 9. View for daily nutrition summary (real-time)
CREATE OR REPLACE VIEW daily_macro_summary AS
SELECT
  ml.user_id,
  ml.meal_date::date AS log_date,
  COALESCE(SUM(ml.total_calories_kcal), 0) AS total_calories,
  COALESCE(SUM(ml.total_protein_g), 0) AS total_protein,
  COALESCE(SUM(ml.total_carbs_g), 0) AS total_carbs,
  COALESCE(SUM(ml.total_fat_g), 0) AS total_fat,
  COUNT(DISTINCT ml.id) AS meal_count
FROM meal_logs ml
GROUP BY ml.user_id, ml.meal_date::date;

-- 10. RLS policies for new tables
ALTER TABLE user_favorite_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_rejection_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_favorite_recipes_owner ON user_favorite_recipes;
CREATE POLICY user_favorite_recipes_owner ON user_favorite_recipes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS recipe_rejection_log_owner ON recipe_rejection_log;
CREATE POLICY recipe_rejection_log_owner ON recipe_rejection_log
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS recipe_steps_read ON recipe_steps;
CREATE POLICY recipe_steps_read ON recipe_steps
  FOR SELECT USING (true);

DROP POLICY IF EXISTS recipe_tags_direct_read ON recipe_tags_direct;
CREATE POLICY recipe_tags_direct_read ON recipe_tags_direct
  FOR SELECT USING (true);

-- 11. Function to auto-calculate recipe macros from ingredients
CREATE OR REPLACE FUNCTION recalculate_recipe_macros(p_recipe_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_calories numeric;
  v_protein numeric;
  v_carbs numeric;
  v_fat numeric;
BEGIN
  SELECT
    COALESCE(SUM(f.calories * ri.grams / fp.grams), 0),
    COALESCE(SUM(f.protein_g * ri.grams / fp.grams), 0),
    COALESCE(SUM(f.carbs_g * ri.grams / fp.grams), 0),
    COALESCE(SUM(f.fats_g * ri.grams / fp.grams), 0)
  INTO v_calories, v_protein, v_carbs, v_fat
  FROM recipe_ingredients ri
  JOIN food_portions fp ON fp.food_id = ri.food_id AND fp.label = ri.portion_label
  JOIN foods f ON f.id = ri.food_id
  WHERE ri.recipe_id = p_recipe_id;

  UPDATE recipes SET
    calories_kcal = v_calories,
    protein_g = v_protein,
    carbs_g = v_carbs,
    fat_g = v_fat,
    updated_at = now()
  WHERE id = p_recipe_id;
END;
$$;

-- 12. Function to register recipe consumption
CREATE OR REPLACE FUNCTION register_recipe_consumption(
  p_user_id uuid,
  p_recipe_id uuid,
  p_meal_type text,
  p_servings numeric DEFAULT 1,
  p_consumed_at timestamptz DEFAULT now()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recipe recipes%ROWTYPE;
  v_meal_log_id uuid;
  v_meal_date date;
BEGIN
  -- Get recipe
  SELECT * INTO v_recipe FROM recipes WHERE id = p_recipe_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Recipe not found';
  END IF;

  v_meal_date := p_consumed_at::date;

  -- Create meal_log
  INSERT INTO meal_logs (
    user_id, meal_type, consumed_at, created_at, recipe_id, servings,
    meal_date,
    total_calories_kcal, total_protein_g, total_carbs_g, total_fat_g
  ) VALUES (
    p_user_id, p_meal_type, p_consumed_at, now(), p_recipe_id, p_servings,
    v_meal_date,
    COALESCE(v_recipe.calories_kcal, 0) * p_servings,
    COALESCE(v_recipe.protein_g, 0) * p_servings,
    COALESCE(v_recipe.carbs_g, 0) * p_servings,
    COALESCE(v_recipe.fat_g, 0) * p_servings
  )
  RETURNING id INTO v_meal_log_id;

  -- Create meal_items from recipe ingredients
  INSERT INTO meal_items (meal_log_id, food_id, recipe_id, calories, protein_g, carbs_g, fats_g, ingredient_text, quantity, grams)
  SELECT
    v_meal_log_id,
    ri.food_id,
    p_recipe_id,
    COALESCE(f.calories, 0) * COALESCE(ri.quantity, 1) * p_servings,
    COALESCE(f.protein_g, 0) * COALESCE(ri.quantity, 1) * p_servings,
    COALESCE(f.carbs_g, 0) * COALESCE(ri.quantity, 1) * p_servings,
    COALESCE(f.fats_g, 0) * COALESCE(ri.quantity, 1) * p_servings,
    ri.ingredient_text,
    ri.quantity * p_servings,
    ri.grams * p_servings
  FROM recipe_ingredients ri
  LEFT JOIN foods f ON f.id = ri.food_id
  WHERE ri.recipe_id = p_recipe_id;

  RETURN v_meal_log_id;
END;
$$;

-- 13. Seed recipes data
INSERT INTO recipes (name, description, category, prep_time_minutes, servings, calories_kcal, protein_g, carbs_g, fat_g, premium_only, difficulty, source)
VALUES
  ('Omelete proteico com tomate', 'Omelete rico em proteínas com tomates frescos, ideal para café da manhã.', 'cafe_da_manha', 10, 1, 350, 30, 8, 22, false, 'facil', 'admin'),
  ('Panqueca de aveia e banana', 'Panqueca fit de aveia com banana, sem glúten.', 'cafe_da_manha', 15, 1, 280, 12, 40, 8, false, 'facil', 'admin'),
  ('Iogurte proteico com granola', 'Iogurte grego com granola caseira e frutas vermelhas.', 'cafe_da_manha', 5, 1, 270, 22, 28, 9, false, 'facil', 'admin'),
  ('Frango grelhado com arroz integral', 'Peito de frango grelhado temperado com arroz integral e legumes.', 'almoco', 25, 1, 420, 38, 42, 10, false, 'medio', 'admin'),
  ('Salmão com batata doce', 'Filé de salmão grelhado com batata doce assada e brócolis.', 'almoco', 30, 1, 480, 40, 35, 18, true, 'medio', 'admin'),
  ('Wrap de frango com vegetais', 'Wrap integral com frango desfiado, alface, tomate e molho de iogurte.', 'almoco', 15, 1, 380, 32, 38, 12, false, 'facil', 'admin'),
  ('Sopa detox de legumes', 'Sopa leve com abóbora, cenoura, gengibre e couve.', 'jantar', 20, 2, 180, 8, 30, 4, false, 'facil', 'admin'),
  ('Tilápia grelhada com purê de couve-flor', 'Filé de tilápia temperado com purê low carb de couve-flor.', 'jantar', 20, 1, 320, 35, 12, 14, false, 'medio', 'admin'),
  ('Bowl de quinoa com legumes', 'Bowl nutritivo com quinoa, grão de bico, abacate e legumes assados.', 'jantar', 25, 1, 390, 16, 48, 16, false, 'medio', 'admin'),
  ('Shake proteico de chocolate', 'Shake rápido com whey protein, leite vegetal e cacau.', 'lanche', 5, 1, 220, 28, 18, 5, false, 'facil', 'admin'),
  ('Mix de castanhas e frutas secas', 'Mix energético com castanhas, amêndoas, damasco e uva passa.', 'lanche', 2, 1, 200, 6, 22, 12, false, 'facil', 'admin'),
  ('Overnight oats proteico', 'Aveia deixada de molho durante a noite com whey e frutas.', 'ceia', 5, 1, 310, 24, 38, 8, false, 'facil', 'admin'),
  ('Chá calmante com biscoito integral', 'Chá de camomila com biscoito integral de aveia e mel.', 'ceia', 8, 1, 150, 4, 24, 4, false, 'facil', 'admin')
ON CONFLICT DO NOTHING;

-- Seed recipe ingredients
-- Omelete proteico (recipe will be looked up by name)
INSERT INTO recipe_ingredients (recipe_id, food_id, ingredient_text, quantity, portion_label)
SELECT r.id, f.id, '2 ovos', 2, 'unidade'
FROM recipes r, foods f WHERE r.name = 'Omelete proteico com tomate' AND f.name ILIKE '%ovo%'
LIMIT 1;

INSERT INTO recipe_ingredients (recipe_id, food_id, ingredient_text, quantity, portion_label)
SELECT r.id, NULL, '1 tomate picado', 1, 'unidade'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_ingredients (recipe_id, food_id, ingredient_text, quantity, portion_label)
SELECT r.id, NULL, '1 colher de azeite', 1, 'colher'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_ingredients (recipe_id, food_id, ingredient_text, quantity, portion_label)
SELECT r.id, NULL, 'Sal e pimenta a gosto', 1, 'porcao'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

-- Insert recipe steps (directly with id)
INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 1, 'Bata os ovos em uma tigela até ficarem homogêneos.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 2, 'Corte o tomate em cubos pequenos e tempere com sal.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 3, 'Aqueça o azeite em uma frigideira antiaderente em fogo médio.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 4, 'Despeje os ovos batidos e espalhe uniformemente.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 5, 'Adicione o tomate picado sobre a superfície e cozinhe até firmar.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 6, 'Dobre ao meio e sirva quente.'
FROM recipes r WHERE r.name = 'Omelete proteico com tomate'
LIMIT 1;

-- Steps for Frango com arroz
INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 1, 'Tempere o peito de frango com sal, pimenta, alho e limão.'
FROM recipes r WHERE r.name = 'Frango grelhado com arroz integral'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 2, 'Cozinhe o arroz integral conforme instruções da embalagem.'
FROM recipes r WHERE r.name = 'Frango grelhado com arroz integral'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 3, 'Grelhe o frango em fogo médio-alto por 6-7 minutos de cada lado.'
FROM recipes r WHERE r.name = 'Frango grelhado com arroz integral'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 4, 'Sirva o frango fatiado sobre o arroz com legumes refogados.'
FROM recipes r WHERE r.name = 'Frango grelhado com arroz integral'
LIMIT 1;

-- Steps for Iogurte proteico
INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 1, 'Coloque o iogurte grego em uma tigela.'
FROM recipes r WHERE r.name = 'Iogurte proteico com granola'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 2, 'Adicione a granola e as frutas vermelhas por cima.'
FROM recipes r WHERE r.name = 'Iogurte proteico com granola'
LIMIT 1;

INSERT INTO recipe_steps (recipe_id, step_order, instruction)
SELECT r.id, 3, 'Finalize com um fio de mel se desejar.'
FROM recipes r WHERE r.name = 'Iogurte proteico com granola'
LIMIT 1;

-- Seed tags for each recipe
INSERT INTO recipe_tags_direct (recipe_id, tag)
SELECT r.id, t.tag
FROM recipes r,
(VALUES
  ('Omelete proteico com tomate', 'alta proteina'),
  ('Omelete proteico com tomate', 'rapido'),
  ('Omelete proteico com tomate', 'caseiro'),
  ('Frango grelhado com arroz integral', 'alta proteina'),
  ('Frango grelhado com arroz integral', 'caseiro'),
  ('Iogurte proteico com granola', 'alta proteina'),
  ('Iogurte proteico com granola', 'rapido')
) AS t(recipe_name, tag)
WHERE r.name = t.recipe_name
ON CONFLICT DO NOTHING;

-- Seed additional recipes with complete data
INSERT INTO recipes (name, description, category, prep_time_minutes, servings, calories_kcal, protein_g, carbs_g, fat_g, premium_only, difficulty, source)
VALUES
  ('Bowl de açaí com granola', 'Açaí batido com banana, granola crocante e mel.', 'cafe_da_manha', 10, 1, 350, 6, 55, 14, true, 'facil', 'admin'),
  ('Tapioca recheada com queijo', 'Tapioca leve recheada com queijo minas e orégano.', 'cafe_da_manha', 8, 1, 250, 12, 30, 10, false, 'facil', 'admin'),
  ('Risoto de cogumelos', 'Risoto cremoso de cogumelos paris com arroz arbóreo.', 'almoco', 35, 2, 420, 14, 52, 18, true, 'dificil', 'admin'),
  ('Strogonoff de frango', 'Strogonoff cremoso de frango com arroz e batata palha.', 'almoco', 25, 2, 450, 34, 38, 16, false, 'medio', 'admin'),
  ('Peixe assado com legumes', 'Filé de peixe branco assado com legumes mediterrâneos.', 'jantar', 30, 1, 340, 32, 18, 14, false, 'medio', 'admin'),
  ('Salada completa com grão de bico', 'Salada nutritiva com grão de bico, quinoa, tomate e pepino.', 'jantar', 15, 1, 290, 14, 36, 10, false, 'facil', 'admin'),
  ('Cookie proteico de banana', 'Cookie fit de banana com aveia e chocolate 70%.', 'lanche', 20, 6, 120, 8, 16, 4, false, 'facil', 'admin'),
  ('Pão de queijo fit', 'Pão de queijo funcional com polvilho e queijo minas.', 'lanche', 25, 8, 110, 5, 12, 5, false, 'medio', 'admin'),
  ('Leite dourado (Golden milk)', 'Bebida quente de cúrcuma com leite vegetal e especiarias.', 'ceia', 8, 1, 120, 3, 14, 6, false, 'facil', 'admin')
ON CONFLICT DO NOTHING;

-- Function to get smart recommendations
CREATE OR REPLACE FUNCTION get_smart_recipe_recommendations(
  p_user_id uuid,
  p_meal_type text DEFAULT NULL,
  p_limit int DEFAULT 5
)
RETURNS TABLE (
  recipe_id uuid,
  name text,
  description text,
  category text,
  prep_time_minutes int,
  servings int,
  image_url text,
  calories_kcal numeric,
  protein_g numeric,
  carbs_g numeric,
  fat_g numeric,
  premium_only boolean,
  difficulty text,
  score numeric,
  match_reason text,
  tags text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today date := CURRENT_DATE;
  v_calories_remaining numeric;
  v_protein_remaining numeric;
  v_carbs_remaining numeric;
  v_fat_remaining numeric;
  v_calorie_goal numeric;
  v_protein_goal numeric;
  v_carbs_goal numeric;
  v_fat_goal numeric;
  v_preferences text[];
  v_restrictions text[];
  v_objective text;
  v_rejected_recipes uuid[];
BEGIN
  -- Get user's daily targets
  SELECT
    COALESCE(dnt.calories_kcal, 2000),
    COALESCE(dnt.protein_g, 120),
    COALESCE(dnt.carbs_g, 250),
    COALESCE(dnt.fats_g, 55)
  INTO v_calorie_goal, v_protein_goal, v_carbs_goal, v_fat_goal
  FROM daily_nutrition_targets dnt
  WHERE dnt.user_id = p_user_id AND dnt.target_date = v_today;

  -- Calculate remaining macros
  SELECT
    GREATEST(v_calorie_goal - COALESCE(SUM(ml.total_calories_kcal), 0), 0),
    GREATEST(v_protein_goal - COALESCE(SUM(ml.total_protein_g), 0), 0),
    GREATEST(v_carbs_goal - COALESCE(SUM(ml.total_carbs_g), 0), 0),
    GREATEST(v_fat_goal - COALESCE(SUM(ml.total_fat_g), 0), 0)
  INTO v_calories_remaining, v_protein_remaining, v_carbs_remaining, v_fat_remaining
  FROM meal_logs ml
  WHERE ml.user_id = p_user_id AND ml.meal_date = v_today;

  -- Get user preferences
  SELECT ARRAY_AGG(DISTINCT pref) INTO v_preferences
  FROM (
    SELECT unnest(string_to_array(COALESCE(fp.data->>'food_preferences', ''), ',')) AS pref
    FROM user_preferences fp WHERE fp.user_id = p_user_id
    UNION
    SELECT unnest(string_to_array(COALESCE(pr.data->>'food_preferences', ''), ',')) AS pref
    FROM health_profiles pr WHERE pr.user_id = p_user_id
  ) t WHERE pref IS NOT NULL AND pref != '';

  -- Get restrictions
  SELECT ARRAY_AGG(DISTINCT restr) INTO v_restrictions
  FROM (
    SELECT unnest(string_to_array(COALESCE(fp.data->>'food_restrictions', ''), ',')) AS restr
    FROM user_preferences fp WHERE fp.user_id = p_user_id
    UNION
    SELECT unnest(string_to_array(COALESCE(pr.data->>'food_restrictions', ''), ',')) AS restr
    FROM health_profiles pr WHERE pr.user_id = p_user_id
  ) t WHERE restr IS NOT NULL AND restr != '';

  -- Get user objective
  SELECT COALESCE(hp.data->>'objective', '') INTO v_objective
  FROM health_profiles hp WHERE hp.user_id = p_user_id
  LIMIT 1;

  -- Get rejected recipes
  SELECT ARRAY_AGG(rl.recipe_id) INTO v_rejected_recipes
  FROM recipe_rejection_log rl
  WHERE rl.user_id = p_user_id;

  RETURN QUERY
  WITH recipe_scores AS (
    SELECT
      r.id,
      r.name,
      r.description,
      r.category,
      r.prep_time_minutes,
      r.servings,
      r.image_url,
      r.calories_kcal,
      r.protein_g,
      r.carbs_g,
      r.fat_g,
      r.premium_only,
      r.difficulty,
      CASE
        WHEN r.calories_kcal IS NOT NULL AND r.calories_kcal <= v_calories_remaining THEN 0.3
        ELSE 0.0
      END +
      CASE
        WHEN r.protein_g IS NOT NULL AND r.protein_g >= v_protein_remaining * 0.3 THEN 0.25
        WHEN r.protein_g IS NOT NULL AND r.protein_g >= v_protein_remaining * 0.15 THEN 0.15
        ELSE 0.0
      END +
      CASE
        WHEN v_objective ILIKE '%low carb%' OR v_objective ILIKE '%perda%' THEN
          CASE WHEN r.carbs_g IS NOT NULL AND r.carbs_g < 30 THEN 0.2 ELSE 0.0 END
        WHEN v_objective ILIKE '%ganho%' OR v_objective ILIKE '%massa%' THEN
          CASE WHEN r.protein_g IS NOT NULL AND r.protein_g > 30 THEN 0.2 ELSE 0.0 END
        ELSE 0.1
      END +
      CASE
        WHEN r.premium_only = false THEN 0.1
        ELSE 0.0
      END +
      CASE
        WHEN (p_meal_type IS NULL OR r.category = p_meal_type) THEN 0.15
        ELSE 0.0
      END AS score,
      CASE
        WHEN r.calories_kcal IS NOT NULL AND r.calories_kcal <= v_calories_remaining AND r.protein_g IS NOT NULL AND r.protein_g >= v_protein_remaining * 0.3
        THEN 'Refeição ideal para suas metas atuais'
        WHEN r.calories_kcal IS NOT NULL AND r.calories_kcal <= v_calories_remaining
        THEN 'Adequado para sua meta calórica restante'
        WHEN r.protein_g IS NOT NULL AND r.protein_g >= v_protein_remaining * 0.3
        THEN 'Rico em proteínas para sua meta'
        WHEN v_objective ILIKE '%low carb%' AND r.carbs_g IS NOT NULL AND r.carbs_g < 30
        THEN 'Opção low carb compatível'
        WHEN v_objective ILIKE '%perda%' OR v_objective ILIKE '%definicao%'
        THEN 'Opção leve para seu objetivo'
        WHEN v_objective ILIKE '%ganho%' OR v_objectile ILIKE '%massa%'
        THEN 'Opção nutritiva para ganho'
        ELSE 'Sugestão para completar seu dia'
      END AS match_reason
    FROM recipes r
    WHERE (p_meal_type IS NULL OR r.category = p_meal_type)
      AND (v_rejected_recipes IS NULL OR NOT (r.id = ANY(v_rejected_recipes)))
      AND (v_calories_remaining <= 0 OR r.calories_kcal IS NULL OR r.calories_kcal <= v_calories_remaining * 1.2)
    ORDER BY score DESC
    LIMIT p_limit
  )
  SELECT
    rs.id,
    rs.name,
    rs.description,
    rs.category,
    rs.prep_time_minutes,
    rs.servings,
    rs.image_url,
    rs.calories_kcal,
    rs.protein_g,
    rs.carbs_g,
    rs.fat_g,
    rs.premium_only,
    rs.difficulty,
    rs.score,
    rs.match_reason,
    ARRAY(
      SELECT rtd.tag
      FROM recipe_tags_direct rtd
      WHERE rtd.recipe_id = rs.id
    ) AS tags
  FROM recipe_scores rs
  ORDER BY rs.score DESC;
END;
$$;