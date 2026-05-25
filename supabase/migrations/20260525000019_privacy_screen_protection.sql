-- HAMVIT privacy screen protection settings

ALTER TABLE IF EXISTS public.user_preferences
  ADD COLUMN IF NOT EXISTS screenshot_protection_enabled boolean,
  ADD COLUMN IF NOT EXISTS app_blur_enabled boolean,
  ADD COLUMN IF NOT EXISTS hide_recent_apps_preview boolean;

UPDATE public.user_preferences
SET
  screenshot_protection_enabled = COALESCE(
    screenshot_protection_enabled,
    (data->'privacy_protection'->>'screenshot_protection_enabled')::boolean,
    true
  ),
  app_blur_enabled = COALESCE(
    app_blur_enabled,
    (data->'privacy_protection'->>'app_blur_enabled')::boolean,
    true
  ),
  hide_recent_apps_preview = COALESCE(
    hide_recent_apps_preview,
    (data->'privacy_protection'->>'hide_recent_apps_preview')::boolean,
    true
  );

CREATE INDEX IF NOT EXISTS idx_user_preferences_privacy_screen_protection
  ON public.user_preferences(user_id, updated_at DESC);
