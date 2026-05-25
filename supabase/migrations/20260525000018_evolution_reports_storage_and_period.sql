-- HAMVIT evolution reports: private PDF storage + generated_reports period metadata

ALTER TABLE IF EXISTS public.generated_reports
  ADD COLUMN IF NOT EXISTS period_type text;

UPDATE public.generated_reports
SET period_type = COALESCE(period_type, report_type, 'all')
WHERE period_type IS NULL;

CREATE INDEX IF NOT EXISTS generated_reports_user_type_period_idx
  ON public.generated_reports(user_id, report_type, period_type, created_at DESC);

INSERT INTO storage.buckets (id, name, public)
VALUES ('report-pdfs', 'report-pdfs', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "report pdfs owner read" ON storage.objects;
CREATE POLICY "report pdfs owner read"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'report-pdfs'
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "report pdfs owner write" ON storage.objects;
CREATE POLICY "report pdfs owner write"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'report-pdfs'
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "report pdfs owner update" ON storage.objects;
CREATE POLICY "report pdfs owner update"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'report-pdfs'
  AND owner = auth.uid()
)
WITH CHECK (
  bucket_id = 'report-pdfs'
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "report pdfs owner delete" ON storage.objects;
CREATE POLICY "report pdfs owner delete"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'report-pdfs'
  AND owner = auth.uid()
);
