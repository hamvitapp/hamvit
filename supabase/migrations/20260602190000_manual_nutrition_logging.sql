-- Detailed manual nutrition logging with immutable nutritional snapshots.

alter table if exists public.foods
  add column if not exists verified boolean not null default false,
  add column if not exists serving_grams numeric(10,2) not null default 100,
  add column if not exists updated_at timestamptz not null default now();

alter table if exists public.meal_items
  add column if not exists food_name_snapshot text,
  add column if not exists portion_label text,
  add column if not exists quantity numeric(10,2),
  add column if not exists grams numeric(10,2),
  add column if not exists calories_kcal numeric(10,2),
  add column if not exists fat_g numeric(10,2),
  add column if not exists created_at timestamptz not null default now();

update public.meal_items
set calories_kcal = coalesce(calories_kcal, calories),
    fat_g = coalesce(fat_g, fats_g)
where calories_kcal is null or fat_g is null;

create index if not exists foods_name_lower_idx
  on public.foods (lower(name));

create index if not exists food_portions_food_label_idx
  on public.food_portions (food_id, lower(label));

alter table public.foods enable row level security;
alter table public.food_portions enable row level security;

drop policy if exists foods_authenticated_read on public.foods;
create policy foods_authenticated_read
  on public.foods for select
  to authenticated
  using (true);

drop policy if exists food_portions_authenticated_read on public.food_portions;
create policy food_portions_authenticated_read
  on public.food_portions for select
  to authenticated
  using (true);

insert into public.foods
  (name, calories, protein_g, carbs_g, fats_g, source, verified, serving_grams)
select seed.*
from (values
  ('Arroz branco cozido', 128, 2.5, 28.1, 0.2, 'seed_initial', false, 100),
  ('Arroz integral cozido', 124, 2.6, 25.8, 1.0, 'seed_initial', false, 100),
  ('Feijão carioca cozido', 76, 4.8, 13.6, 0.5, 'seed_initial', false, 100),
  ('Peito de frango grelhado', 159, 32.0, 0.0, 2.5, 'seed_initial', false, 100),
  ('Carne bovina grelhada', 219, 32.0, 0.0, 9.0, 'seed_initial', false, 100),
  ('Ovo cozido', 146, 13.3, 0.6, 9.5, 'seed_initial', false, 100),
  ('Banana prata', 98, 1.3, 26.0, 0.1, 'seed_initial', false, 100),
  ('Maçã', 56, 0.3, 15.2, 0.0, 'seed_initial', false, 100),
  ('Aveia em flocos', 394, 13.9, 66.6, 8.5, 'seed_initial', false, 100),
  ('Leite integral', 61, 3.2, 4.7, 3.3, 'seed_initial', false, 100),
  ('Iogurte natural integral', 51, 4.1, 1.9, 3.0, 'seed_initial', false, 100),
  ('Pão francês', 300, 8.0, 58.6, 3.1, 'seed_initial', false, 100),
  ('Queijo muçarela', 330, 22.6, 3.0, 25.2, 'seed_initial', false, 100),
  ('Batata doce cozida', 77, 0.6, 18.4, 0.1, 'seed_initial', false, 100),
  ('Alface', 11, 1.3, 1.7, 0.2, 'seed_initial', false, 100),
  ('Tomate', 15, 1.1, 3.1, 0.2, 'seed_initial', false, 100)
) as seed(name, calories, protein_g, carbs_g, fats_g, source, verified, serving_grams)
where not exists (
  select 1 from public.foods existing
  where lower(existing.name) = lower(seed.name)
);

insert into public.food_portions (food_id, label, grams)
select food.id, '100 g', 100
from public.foods food
where not exists (
  select 1 from public.food_portions portion
  where portion.food_id = food.id and lower(portion.label) = '100 g'
);

create or replace function public.register_manual_meal(
  p_meal_type text,
  p_consumed_at timestamptz,
  p_items jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_meal_id uuid;
  v_item jsonb;
  v_food public.foods%rowtype;
  v_grams numeric(10,2);
  v_ratio numeric(12,6);
  v_calories numeric(10,2);
  v_protein numeric(10,2);
  v_carbs numeric(10,2);
  v_fat numeric(10,2);
  v_total_calories numeric(10,2) := 0;
  v_total_protein numeric(10,2) := 0;
  v_total_carbs numeric(10,2) := 0;
  v_total_fat numeric(10,2) := 0;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Adicione ao menos um alimento';
  end if;

  insert into public.meal_logs
    (user_id, meal_type, consumed_at, meal_date, created_at, updated_at)
  values
    (v_user_id, p_meal_type, p_consumed_at, p_consumed_at::date, now(), now())
  returning id into v_meal_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    select * into v_food
    from public.foods
    where id = (v_item->>'food_id')::uuid;

    if not found then
      raise exception 'Alimento não encontrado';
    end if;

    v_grams := greatest(coalesce((v_item->>'grams')::numeric, 0), 0);
    if v_grams <= 0 then
      raise exception 'Informe uma quantidade válida';
    end if;
    v_ratio := v_grams / 100.0;
    v_calories := round(coalesce(v_food.calories, 0) * v_ratio, 2);
    v_protein := round(coalesce(v_food.protein_g, 0) * v_ratio, 2);
    v_carbs := round(coalesce(v_food.carbs_g, 0) * v_ratio, 2);
    v_fat := round(coalesce(v_food.fats_g, 0) * v_ratio, 2);

    insert into public.meal_items (
      meal_log_id, food_id, food_name_snapshot, portion_label, quantity, grams,
      calories, calories_kcal, protein_g, carbs_g, fats_g, fat_g
    ) values (
      v_meal_id, v_food.id, v_food.name, coalesce(v_item->>'portion_label', 'gramas'),
      coalesce((v_item->>'quantity')::numeric, v_grams), v_grams,
      v_calories, v_calories, v_protein, v_carbs, v_fat, v_fat
    );

    v_total_calories := v_total_calories + v_calories;
    v_total_protein := v_total_protein + v_protein;
    v_total_carbs := v_total_carbs + v_carbs;
    v_total_fat := v_total_fat + v_fat;
  end loop;

  update public.meal_logs
  set total_calories_kcal = v_total_calories,
      total_protein_g = v_total_protein,
      total_carbs_g = v_total_carbs,
      total_fat_g = v_total_fat,
      updated_at = now()
  where id = v_meal_id;

  return v_meal_id;
end;
$$;

grant execute on function public.register_manual_meal(text, timestamptz, jsonb)
  to authenticated;
