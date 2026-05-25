-- HAMVIT biometric auth preferences

ALTER TABLE IF EXISTS public.user_preferences
  ADD COLUMN IF NOT EXISTS biometric_unlock_enabled boolean,
  ADD COLUMN IF NOT EXISTS biometric_sensitive_screens_enabled boolean,
  ADD COLUMN IF NOT EXISTS last_biometric_unlock_at bigint;

UPDATE public.user_preferences
SET
  biometric_unlock_enabled = COALESCE(
    biometric_unlock_enabled,
    (data->'security'->'biometric'->>'biometric_unlock_enabled')::boolean,
    false
  ),
  biometric_sensitive_screens_enabled = COALESCE(
    biometric_sensitive_screens_enabled,
    (data->'security'->'biometric'->>'biometric_sensitive_screens_enabled')::boolean,
    false
  ),
  last_biometric_unlock_at = COALESCE(
    last_biometric_unlock_at,
    (EXTRACT(EPOCH FROM (data->'security'->'biometric'->>'last_biometric_unlock_at')::timestamptz) * 1000)::bigint
  );

CREATE INDEX IF NOT EXISTS idx_user_preferences_biometric_auth
  ON public.user_preferences(user_id, biometric_unlock_enabled, biometric_sensitive_screens_enabled);