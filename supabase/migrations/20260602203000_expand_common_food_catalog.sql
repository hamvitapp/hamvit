-- Expand the initial catalog with common Brazilian foods.
-- Approximate values per 100 g or 100 ml, based on TACO/UNICAMP references.
-- Keep verified=false until reviewed by a nutrition professional.

insert into public.foods
  (name, calories, protein_g, carbs_g, fats_g, source, verified, serving_grams)
select seed.*
from (values
  -- Bebidas
  ('Café coado sem açúcar', 9, 0.7, 1.5, 0.1, 'taco_reference_seed', false, 100),
  ('Café expresso sem açúcar', 9, 0.7, 1.5, 0.1, 'taco_reference_seed', false, 100),
  ('Café com leite integral sem açúcar', 36, 2.0, 3.0, 1.8, 'taco_reference_seed', false, 100),
  ('Suco de laranja natural', 37, 0.7, 8.8, 0.1, 'taco_reference_seed', false, 100),
  ('Água de coco', 22, 0.0, 5.3, 0.0, 'taco_reference_seed', false, 100),

  -- Carnes bovinas
  ('Carne bovina acém cozido', 215, 27.3, 0.0, 10.9, 'taco_reference_seed', false, 100),
  ('Carne bovina alcatra grelhada', 241, 31.9, 0.0, 11.6, 'taco_reference_seed', false, 100),
  ('Carne bovina contrafilé grelhado', 278, 32.4, 0.0, 15.5, 'taco_reference_seed', false, 100),
  ('Carne bovina coxão mole cozido', 219, 32.4, 0.0, 8.9, 'taco_reference_seed', false, 100),
  ('Carne bovina coxão duro cozido', 217, 31.9, 0.0, 9.0, 'taco_reference_seed', false, 100),
  ('Carne bovina filé mignon grelhado', 220, 32.8, 0.0, 8.8, 'taco_reference_seed', false, 100),
  ('Carne bovina músculo cozido', 194, 31.2, 0.0, 6.7, 'taco_reference_seed', false, 100),
  ('Carne bovina patinho grelhado', 219, 35.9, 0.0, 7.3, 'taco_reference_seed', false, 100),
  ('Carne bovina picanha grelhada', 289, 26.4, 0.0, 19.5, 'taco_reference_seed', false, 100),
  ('Carne moída refogada', 212, 26.7, 0.0, 10.9, 'taco_reference_seed', false, 100),

  -- Carnes suínas
  ('Carne suína bisteca grelhada', 280, 28.9, 0.0, 17.4, 'taco_reference_seed', false, 100),
  ('Carne suína costela assada', 402, 30.2, 0.0, 30.3, 'taco_reference_seed', false, 100),
  ('Carne suína lombo assado', 210, 35.7, 0.0, 6.4, 'taco_reference_seed', false, 100),
  ('Carne suína pernil assado', 262, 32.1, 0.0, 13.9, 'taco_reference_seed', false, 100),
  ('Carne suína filé mignon grelhado', 207, 35.7, 0.0, 5.8, 'taco_reference_seed', false, 100),
  ('Linguiça suína assada', 296, 23.2, 0.0, 22.1, 'taco_reference_seed', false, 100),

  -- Frango e ovos
  ('Frango coxa assada com pele', 215, 28.5, 0.0, 10.4, 'taco_reference_seed', false, 100),
  ('Frango coxa assada sem pele', 188, 29.6, 0.0, 7.0, 'taco_reference_seed', false, 100),
  ('Frango sobrecoxa assada com pele', 260, 28.7, 0.0, 15.2, 'taco_reference_seed', false, 100),
  ('Frango sobrecoxa assada sem pele', 233, 29.2, 0.0, 12.0, 'taco_reference_seed', false, 100),
  ('Frango peito cozido sem pele', 163, 31.5, 0.0, 3.2, 'taco_reference_seed', false, 100),
  ('Frango peito assado sem pele', 159, 32.0, 0.0, 2.5, 'taco_reference_seed', false, 100),
  ('Frango inteiro assado com pele', 234, 27.9, 0.0, 12.9, 'taco_reference_seed', false, 100),
  ('Ovo mexido', 240, 15.6, 1.2, 18.6, 'taco_reference_seed', false, 100),
  ('Ovo frito', 240, 15.6, 1.2, 18.6, 'taco_reference_seed', false, 100),

  -- Peixes
  ('Tilápia grelhada', 128, 26.0, 0.0, 2.7, 'taco_reference_seed', false, 100),
  ('Salmão grelhado', 229, 23.9, 0.0, 14.0, 'taco_reference_seed', false, 100),
  ('Sardinha assada', 164, 32.2, 0.0, 3.0, 'taco_reference_seed', false, 100),
  ('Atum em conserva em água', 116, 25.5, 0.0, 0.8, 'taco_reference_seed', false, 100),

  -- Frutas
  ('Abacate', 96, 1.2, 6.0, 8.4, 'taco_reference_seed', false, 100),
  ('Abacaxi', 48, 0.9, 12.3, 0.1, 'taco_reference_seed', false, 100),
  ('Acerola', 33, 0.9, 8.0, 0.2, 'taco_reference_seed', false, 100),
  ('Banana nanica', 92, 1.4, 23.8, 0.1, 'taco_reference_seed', false, 100),
  ('Goiaba vermelha', 54, 1.1, 13.0, 0.4, 'taco_reference_seed', false, 100),
  ('Kiwi', 51, 1.3, 11.5, 0.6, 'taco_reference_seed', false, 100),
  ('Laranja pera', 37, 1.0, 8.9, 0.1, 'taco_reference_seed', false, 100),
  ('Mamão papaia', 40, 0.5, 10.4, 0.1, 'taco_reference_seed', false, 100),
  ('Manga', 72, 0.4, 19.4, 0.2, 'taco_reference_seed', false, 100),
  ('Melancia', 33, 0.9, 8.1, 0.0, 'taco_reference_seed', false, 100),
  ('Melão', 29, 0.7, 7.5, 0.0, 'taco_reference_seed', false, 100),
  ('Morango', 30, 0.9, 6.8, 0.3, 'taco_reference_seed', false, 100),
  ('Pera', 53, 0.6, 14.0, 0.1, 'taco_reference_seed', false, 100),
  ('Uva', 53, 0.7, 13.6, 0.2, 'taco_reference_seed', false, 100),

  -- Cereais, raízes e massas
  ('Macarrão cozido', 102, 3.4, 20.3, 0.5, 'taco_reference_seed', false, 100),
  ('Pão de forma integral', 253, 9.4, 49.9, 3.7, 'taco_reference_seed', false, 100),
  ('Tapioca pronta', 289, 0.4, 71.9, 0.0, 'taco_reference_seed', false, 100),
  ('Batata inglesa cozida', 52, 1.2, 11.9, 0.0, 'taco_reference_seed', false, 100),
  ('Mandioca cozida', 125, 0.6, 30.1, 0.3, 'taco_reference_seed', false, 100),
  ('Milho verde cozido', 98, 3.2, 17.1, 2.4, 'taco_reference_seed', false, 100),
  ('Farofa pronta', 406, 2.1, 80.3, 9.1, 'taco_reference_seed', false, 100),
  ('Cuscuz de milho cozido', 113, 2.2, 25.3, 0.7, 'taco_reference_seed', false, 100),

  -- Leguminosas e vegetais
  ('Feijão preto cozido', 77, 4.5, 14.0, 0.5, 'taco_reference_seed', false, 100),
  ('Lentilha cozida', 93, 6.3, 16.3, 0.5, 'taco_reference_seed', false, 100),
  ('Grão de bico cozido', 164, 8.9, 27.4, 2.6, 'taco_reference_seed', false, 100),
  ('Brócolis cozido', 25, 2.1, 4.4, 0.5, 'taco_reference_seed', false, 100),
  ('Cenoura cozida', 30, 0.8, 6.7, 0.2, 'taco_reference_seed', false, 100),
  ('Abobrinha cozida', 15, 1.1, 3.0, 0.2, 'taco_reference_seed', false, 100),
  ('Beterraba cozida', 32, 1.3, 7.2, 0.1, 'taco_reference_seed', false, 100),
  ('Couve refogada', 90, 1.7, 8.7, 6.6, 'taco_reference_seed', false, 100),

  -- Laticínios e itens de café da manhã
  ('Leite desnatado', 35, 3.4, 5.0, 0.1, 'taco_reference_seed', false, 100),
  ('Queijo minas frescal', 264, 17.4, 3.2, 20.2, 'taco_reference_seed', false, 100),
  ('Requeijão cremoso', 257, 9.6, 2.4, 23.4, 'taco_reference_seed', false, 100),
  ('Manteiga com sal', 726, 0.4, 0.1, 82.4, 'taco_reference_seed', false, 100),
  ('Granola', 471, 10.0, 64.0, 20.0, 'taco_reference_seed', false, 100),
  ('Whey protein concentrado', 400, 80.0, 8.0, 6.0, 'reference_seed', false, 100),

  -- Preparações comuns
  ('Arroz com feijão', 126, 4.3, 22.8, 1.8, 'taco_reference_seed', false, 100),
  ('Purê de batata', 90, 1.5, 11.8, 4.3, 'taco_reference_seed', false, 100),
  ('Salada de legumes cozidos', 35, 1.4, 7.1, 0.3, 'taco_reference_seed', false, 100)
) as seed(name, calories, protein_g, carbs_g, fats_g, source, verified, serving_grams)
where not exists (
  select 1 from public.foods existing
  where lower(existing.name) = lower(seed.name)
);

-- Useful default portions for faster entry.
insert into public.food_portions (food_id, label, grams)
select food.id, portion.label, portion.grams
from public.foods food
join (values
  ('Café coado sem açúcar', '1 xícara pequena', 50),
  ('Café coado sem açúcar', '1 xícara', 100),
  ('Café com leite integral sem açúcar', '1 xícara', 200),
  ('Leite integral', '1 copo', 200),
  ('Leite desnatado', '1 copo', 200),
  ('Ovo cozido', '1 unidade', 50),
  ('Ovo mexido', '1 unidade', 50),
  ('Ovo frito', '1 unidade', 50),
  ('Banana prata', '1 unidade média', 65),
  ('Banana nanica', '1 unidade média', 86),
  ('Maçã', '1 unidade média', 130),
  ('Kiwi', '1 unidade média', 75),
  ('Pão francês', '1 unidade', 50),
  ('Pão de forma integral', '1 fatia', 25),
  ('Tapioca pronta', '1 unidade média', 80),
  ('Queijo minas frescal', '1 fatia', 30),
  ('Queijo muçarela', '1 fatia', 20),
  ('Requeijão cremoso', '1 colher de sopa', 30),
  ('Manteiga com sal', '1 ponta de faca', 5)
) as portion(food_name, label, grams)
  on lower(food.name) = lower(portion.food_name)
where not exists (
  select 1 from public.food_portions existing
  where existing.food_id = food.id
    and lower(existing.label) = lower(portion.label)
);

insert into public.food_portions (food_id, label, grams)
select food.id, '100 g', 100
from public.foods food
where not exists (
  select 1 from public.food_portions portion
  where portion.food_id = food.id and lower(portion.label) = '100 g'
);
