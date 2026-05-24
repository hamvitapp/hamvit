-- Mercado Pago hardening and premium lifetime payment alignment (idempotent)

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
    CREATE TYPE public.payment_status AS ENUM (
      'pending',
      'approved',
      'rejected',
      'cancelled',
      'refunded',
      'chargeback'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE public.payment_method AS ENUM ('pix', 'credit_card');
  END IF;
END$$;

ALTER TABLE IF EXISTS public.payments
  ADD COLUMN IF NOT EXISTS provider_payment_id text,
  ADD COLUMN IF NOT EXISTS provider_preference_id text,
  ADD COLUMN IF NOT EXISTS method public.payment_method,
  ADD COLUMN IF NOT EXISTS amount_cents integer,
  ADD COLUMN IF NOT EXISTS currency text NOT NULL DEFAULT 'BRL',
  ADD COLUMN IF NOT EXISTS coupon_id uuid,
  ADD COLUMN IF NOT EXISTS raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS external_reference text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

UPDATE public.payments
SET amount_cents = COALESCE(amount_cents, ROUND(COALESCE(amount_brl, 0) * 100)::int),
    updated_at = now()
WHERE amount_cents IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'payments'
      AND column_name = 'status'
      AND udt_name <> 'payment_status'
  ) THEN
    ALTER TABLE public.payments ALTER COLUMN status DROP DEFAULT;
    ALTER TABLE public.payments
      ALTER COLUMN status TYPE public.payment_status
      USING (
        CASE
          WHEN status::text IN ('approved', 'rejected', 'cancelled', 'refunded', 'chargeback') THEN status::text::public.payment_status
          ELSE 'pending'::public.payment_status
        END
      );
  END IF;
END$$;

ALTER TABLE public.payments
  ALTER COLUMN status SET DEFAULT 'pending'::public.payment_status,
  ALTER COLUMN amount_cents SET NOT NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'payments'
      AND column_name = 'coupon_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'payments_coupon_id_fkey'
      AND conrelid = 'public.payments'::regclass
  ) THEN
    ALTER TABLE public.payments
      ADD CONSTRAINT payments_coupon_id_fkey
      FOREIGN KEY (coupon_id) REFERENCES public.professional_coupons(id) ON DELETE SET NULL;
  END IF;
END$$;

CREATE UNIQUE INDEX IF NOT EXISTS payments_provider_payment_unique
  ON public.payments(provider, provider_payment_id)
  WHERE provider_payment_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS payments_provider_preference_unique
  ON public.payments(provider, provider_preference_id)
  WHERE provider_preference_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS payments_external_reference_unique
  ON public.payments(external_reference)
  WHERE external_reference IS NOT NULL;

CREATE INDEX IF NOT EXISTS payments_user_status_created_idx
  ON public.payments(user_id, status, created_at DESC);

ALTER TABLE IF EXISTS public.payment_webhooks
  ADD COLUMN IF NOT EXISTS event_type text,
  ADD COLUMN IF NOT EXISTS provider_event_id text,
  ADD COLUMN IF NOT EXISTS processed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS payment_webhooks_provider_event_unique
  ON public.payment_webhooks(provider, provider_event_id)
  WHERE provider_event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS payment_webhooks_processed_idx
  ON public.payment_webhooks(processed, created_at DESC);

ALTER TABLE IF EXISTS public.user_entitlements
  ADD COLUMN IF NOT EXISTS source_payment_id uuid,
  ADD COLUMN IF NOT EXISTS entitlement_key text,
  ADD COLUMN IF NOT EXISTS starts_at timestamptz,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

UPDATE public.user_entitlements
SET entitlement_key = COALESCE(entitlement_key, plan::text),
    starts_at = COALESCE(starts_at, granted_at, now())
WHERE entitlement_key IS NULL OR starts_at IS NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_entitlements'
      AND column_name = 'source_payment_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_entitlements_source_payment_id_fkey'
      AND conrelid = 'public.user_entitlements'::regclass
  ) THEN
    ALTER TABLE public.user_entitlements
      ADD CONSTRAINT user_entitlements_source_payment_id_fkey
      FOREIGN KEY (source_payment_id) REFERENCES public.payments(id) ON DELETE SET NULL;
  END IF;
END$$;

CREATE UNIQUE INDEX IF NOT EXISTS user_entitlements_user_key_unique
  ON public.user_entitlements(user_id, entitlement_key);

ALTER TABLE IF EXISTS public.professional_commissions
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS amount_cents integer,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'approved',
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS paid_at timestamptz;

UPDATE public.professional_commissions
SET amount_cents = COALESCE(amount_cents, ROUND(COALESCE(amount_brl, 0) * 100)::int)
WHERE amount_cents IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'professional_commissions_payment_id_fkey'
      AND conrelid = 'public.professional_commissions'::regclass
  ) THEN
    ALTER TABLE public.professional_commissions
      ADD CONSTRAINT professional_commissions_payment_id_fkey
      FOREIGN KEY (payment_id) REFERENCES public.payments(id) ON DELETE SET NULL;
  END IF;
END$$;

CREATE UNIQUE INDEX IF NOT EXISTS professional_commissions_payment_unique
  ON public.professional_commissions(payment_id)
  WHERE payment_id IS NOT NULL;

ALTER TABLE IF EXISTS public.patient_professional_links
  ADD COLUMN IF NOT EXISTS coupon_id uuid,
  ADD COLUMN IF NOT EXISTS linked_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'patient_professional_links'
      AND column_name = 'coupon_id'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'patient_professional_links_coupon_id_fkey'
      AND conrelid = 'public.patient_professional_links'::regclass
  ) THEN
    ALTER TABLE public.patient_professional_links
      ADD CONSTRAINT patient_professional_links_coupon_id_fkey
      FOREIGN KEY (coupon_id) REFERENCES public.professional_coupons(id) ON DELETE SET NULL;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS patient_professional_links_user_active_idx
  ON public.patient_professional_links(user_id, active);

ALTER TABLE IF EXISTS public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payment_webhooks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS payments_select_own ON public.payments;
CREATE POLICY payments_select_own
ON public.payments
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS payment_webhooks_select_admin_only ON public.payment_webhooks;
CREATE POLICY payment_webhooks_select_admin_only
ON public.payment_webhooks
FOR SELECT
USING (
  auth.role() = 'service_role'
  OR EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.user_id = auth.uid()
      AND p.role IN ('admin', 'super_admin')
  )
);

DROP POLICY IF EXISTS payment_webhooks_insert_service_role ON public.payment_webhooks;
CREATE POLICY payment_webhooks_insert_service_role
ON public.payment_webhooks
FOR INSERT
WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS payment_webhooks_update_service_role ON public.payment_webhooks;
CREATE POLICY payment_webhooks_update_service_role
ON public.payment_webhooks
FOR UPDATE
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');
