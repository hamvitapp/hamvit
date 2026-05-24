-- HAMVIT Reports / Analytics / PDF alignment

ALTER TABLE IF EXISTS public.generated_reports
  ADD COLUMN IF NOT EXISTS report_type text NOT NULL DEFAULT 'weekly',
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'ready',
  ADD COLUMN IF NOT EXISTS pdf_path text,
  ADD COLUMN IF NOT EXISTS summary_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS ready_at timestamptz;

UPDATE public.generated_reports
SET pdf_path = COALESCE(pdf_path, storage_path),
    ready_at = COALESCE(ready_at, created_at),
    status = COALESCE(status, 'ready')
WHERE pdf_path IS NULL OR ready_at IS NULL OR status IS NULL;

CREATE INDEX IF NOT EXISTS generated_reports_user_period_idx
  ON public.generated_reports(user_id, period_start DESC, period_end DESC);

ALTER TABLE IF EXISTS public.report_shares
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS shared_to_email text,
  ADD COLUMN IF NOT EXISTS shared_to_professional_id uuid,
  ADD COLUMN IF NOT EXISTS channel text;

UPDATE public.report_shares rs
SET user_id = COALESCE(rs.user_id, gr.user_id),
    channel = COALESCE(rs.channel, 'share_sheet')
FROM public.generated_reports gr
WHERE gr.id = rs.report_id
  AND (rs.user_id IS NULL OR rs.channel IS NULL);

CREATE INDEX IF NOT EXISTS report_shares_user_idx ON public.report_shares(user_id, shared_at DESC);

ALTER TABLE IF EXISTS public.professional_report_access
  ADD COLUMN IF NOT EXISTS report_id uuid REFERENCES public.generated_reports(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz;

CREATE INDEX IF NOT EXISTS professional_report_access_user_idx
  ON public.professional_report_access(user_id, granted_at DESC);

CREATE TABLE IF NOT EXISTS public.report_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  report_id uuid REFERENCES public.generated_reports(id) ON DELETE CASCADE,
  insight_type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  severity text NOT NULL DEFAULT 'info',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS report_insights_user_idx ON public.report_insights(user_id, created_at DESC);

ALTER TABLE public.generated_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professional_report_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_insights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS generated_reports_select_own ON public.generated_reports;
CREATE POLICY generated_reports_select_own
ON public.generated_reports
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS generated_reports_insert_own ON public.generated_reports;
CREATE POLICY generated_reports_insert_own
ON public.generated_reports
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS generated_reports_update_own ON public.generated_reports;
CREATE POLICY generated_reports_update_own
ON public.generated_reports
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS report_shares_select_own ON public.report_shares;
CREATE POLICY report_shares_select_own
ON public.report_shares
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS report_shares_insert_own ON public.report_shares;
CREATE POLICY report_shares_insert_own
ON public.report_shares
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS report_insights_select_own ON public.report_insights;
CREATE POLICY report_insights_select_own
ON public.report_insights
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS report_insights_insert_own ON public.report_insights;
CREATE POLICY report_insights_insert_own
ON public.report_insights
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS professional_report_access_select_own ON public.professional_report_access;
CREATE POLICY professional_report_access_select_own
ON public.professional_report_access
FOR SELECT
USING (auth.uid() = user_id);

-- Deterministic summary function for dashboards and PDFs.
CREATE OR REPLACE FUNCTION public.hamvit_report_summary(
  p_start date,
  p_end date
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
WITH me AS (
  SELECT auth.uid() AS uid
),
meal AS (
  SELECT
    COALESCE(sum(mi.calories), 0)::numeric(10,2) AS calories,
    COALESCE(sum(mi.protein_g), 0)::numeric(10,2) AS protein
  FROM public.meal_items mi
  JOIN public.meal_logs ml ON ml.id = mi.meal_log_id
  JOIN me ON me.uid = ml.user_id
  WHERE ml.consumed_at::date BETWEEN p_start AND p_end
),
hyd AS (
  SELECT COALESCE(sum(h.ml), 0)::numeric(10,2) AS water_ml
  FROM public.hydration_logs h
  JOIN me ON me.uid = h.user_id
  WHERE h.logged_at::date BETWEEN p_start AND p_end
),
hab AS (
  SELECT COALESCE(sum(CASE WHEN hl.done THEN 1 ELSE 0 END), 0)::int AS habits_done
  FROM public.habit_logs hl
  JOIN public.user_habits uh ON uh.id = hl.user_habit_id
  JOIN me ON me.uid = uh.user_id
  WHERE hl.logged_at::date BETWEEN p_start AND p_end
),
act AS (
  SELECT
    COALESCE(sum(a.distance_m), 0)::numeric(10,2) AS distance_m,
    COALESCE(
      sum(
        CASE
          WHEN a.started_at IS NOT NULL AND a.ended_at IS NOT NULL THEN extract(epoch from (a.ended_at - a.started_at))
          ELSE 0
        END
      ),
      0
    )::int AS duration_sec
  FROM public.activity_sessions a
  JOIN me ON me.uid = a.user_id
  WHERE a.started_at::date BETWEEN p_start AND p_end
),
wt AS (
  SELECT
    (SELECT w.weight_kg FROM public.weight_logs w JOIN me ON me.uid = w.user_id WHERE w.logged_at::date <= p_end ORDER BY w.logged_at DESC LIMIT 1) AS current_weight,
    (SELECT w.weight_kg FROM public.weight_logs w JOIN me ON me.uid = w.user_id WHERE w.logged_at::date < p_start ORDER BY w.logged_at DESC LIMIT 1) AS previous_weight
)
SELECT jsonb_build_object(
  'period_start', p_start,
  'period_end', p_end,
  'calories_total', meal.calories,
  'protein_total', meal.protein,
  'water_total_ml', hyd.water_ml,
  'habits_done', hab.habits_done,
  'distance_total_km', round((act.distance_m / 1000.0)::numeric, 2),
  'active_minutes', round((act.duration_sec / 60.0)::numeric, 0),
  'weight_current', wt.current_weight,
  'weight_delta', CASE WHEN wt.current_weight IS NOT NULL AND wt.previous_weight IS NOT NULL THEN round((wt.current_weight - wt.previous_weight)::numeric, 2) ELSE NULL END
)
FROM meal, hyd, hab, act, wt;
$$;

CREATE OR REPLACE FUNCTION public.hamvit_daily_consistency_heatmap(
  p_start date,
  p_end date
)
RETURNS TABLE (day date, score int)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
WITH me AS (
  SELECT auth.uid() AS uid
),
days AS (
  SELECT generate_series(p_start, p_end, interval '1 day')::date AS day
),
hab AS (
  SELECT hl.logged_at::date AS day, count(*) FILTER (WHERE hl.done) AS c
  FROM public.habit_logs hl
  JOIN public.user_habits uh ON uh.id = hl.user_habit_id
  JOIN me ON me.uid = uh.user_id
  WHERE hl.logged_at::date BETWEEN p_start AND p_end
  GROUP BY 1
),
hyd AS (
  SELECT h.logged_at::date AS day, count(*) AS c
  FROM public.hydration_logs h
  JOIN me ON me.uid = h.user_id
  WHERE h.logged_at::date BETWEEN p_start AND p_end
  GROUP BY 1
),
act AS (
  SELECT a.started_at::date AS day, count(*) AS c
  FROM public.activity_sessions a
  JOIN me ON me.uid = a.user_id
  WHERE a.started_at::date BETWEEN p_start AND p_end
  GROUP BY 1
)
SELECT
  d.day,
  LEAST(100, COALESCE(hab.c,0) * 25 + COALESCE(hyd.c,0) * 15 + COALESCE(act.c,0) * 20)::int AS score
FROM days d
LEFT JOIN hab ON hab.day = d.day
LEFT JOIN hyd ON hyd.day = d.day
LEFT JOIN act ON act.day = d.day
ORDER BY d.day;
$$;
