-- Auth module alignment for HAMVIT (incremental, non-destructive)

-- Enums required by auth/profile model
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM ('user', 'nutritionist', 'admin', 'super_admin');
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_plan') THEN
    CREATE TYPE public.user_plan AS ENUM ('free', 'premium_lifetime', 'admin');
  END IF;
END$$;

-- Profiles structure alignment
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS role public.user_role NOT NULL DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS premium_active boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS onboarding_completed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE public.profiles
SET user_id = COALESCE(user_id, id),
    display_name = COALESCE(display_name, full_name)
WHERE user_id IS NULL OR display_name IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'plan'
      AND udt_name <> 'user_plan'
  ) THEN
    ALTER TABLE public.profiles ALTER COLUMN plan DROP DEFAULT;
    ALTER TABLE public.profiles
      ALTER COLUMN plan TYPE public.user_plan
      USING (
        CASE
          WHEN plan::text = 'premium_lifetime' THEN 'premium_lifetime'::public.user_plan
          WHEN plan::text = 'admin' THEN 'admin'::public.user_plan
          ELSE 'free'::public.user_plan
        END
      );
    ALTER TABLE public.profiles ALTER COLUMN plan SET DEFAULT 'free'::public.user_plan;
  END IF;
END$$;

ALTER TABLE public.profiles
  ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_user_id_uidx ON public.profiles(user_id);

-- user_entitlements alignment
ALTER TABLE IF EXISTS public.user_entitlements
  ADD COLUMN IF NOT EXISTS entitlement_key text,
  ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS source_payment_id uuid,
  ADD COLUMN IF NOT EXISTS starts_at timestamptz,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

UPDATE public.user_entitlements
SET entitlement_key = COALESCE(entitlement_key, plan::text),
    starts_at = COALESCE(starts_at, granted_at, now())
WHERE entitlement_key IS NULL OR starts_at IS NULL;

CREATE INDEX IF NOT EXISTS user_entitlements_user_active_idx
  ON public.user_entitlements(user_id, active);

-- RLS mandatory
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_entitlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own
ON public.profiles
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = user_id AND auth.uid() = id);

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own
ON public.profiles
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_entitlements_select_own ON public.user_entitlements;
CREATE POLICY user_entitlements_select_own
ON public.user_entitlements
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_entitlements_insert_service_role ON public.user_entitlements;
CREATE POLICY user_entitlements_insert_service_role
ON public.user_entitlements
FOR INSERT
WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS user_entitlements_update_service_role ON public.user_entitlements;
CREATE POLICY user_entitlements_update_service_role
ON public.user_entitlements
FOR UPDATE
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS user_entitlements_delete_service_role ON public.user_entitlements;
CREATE POLICY user_entitlements_delete_service_role
ON public.user_entitlements
FOR DELETE
USING (auth.role() = 'service_role');

-- Sensitive fields protection (role/plan/premium) against self-escalation
CREATE OR REPLACE FUNCTION public.prevent_profile_sensitive_updates()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF auth.role() <> 'service_role' THEN
    IF NEW.id <> OLD.id OR NEW.user_id <> OLD.user_id THEN
      RAISE EXCEPTION 'Nao e permitido alterar identificadores do perfil.';
    END IF;

    IF NEW.role <> OLD.role THEN
      RAISE EXCEPTION 'Nao e permitido alterar role pelo app cliente.';
    END IF;

    IF NEW.plan <> OLD.plan THEN
      RAISE EXCEPTION 'Nao e permitido alterar plano pelo app cliente.';
    END IF;

    IF COALESCE(NEW.premium_active, false) <> COALESCE(OLD.premium_active, false) THEN
      RAISE EXCEPTION 'Nao e permitido ativar premium manualmente pelo app cliente.';
    END IF;
  END IF;

  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_prevent_sensitive_updates ON public.profiles;
CREATE TRIGGER trg_profiles_prevent_sensitive_updates
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.prevent_profile_sensitive_updates();
