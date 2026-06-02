alter table if exists public.activity_sessions
add column if not exists route_summary_json jsonb;

