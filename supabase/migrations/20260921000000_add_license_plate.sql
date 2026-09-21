-- Add license_plate column to dlt_manual_overrides
-- Allows overriding the license plate for DLT transmission

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='dlt_manual_overrides' AND column_name='license_plate') THEN
    ALTER TABLE dlt_manual_overrides ADD COLUMN license_plate TEXT;
  END IF;
END $$;

COMMENT ON COLUMN dlt_manual_overrides.license_plate IS 'Override license plate for DLT (format: ABC-1234)';
