-- Add a "type" column to warehouses to support armory-specific warehouse categorization.
-- This column is used by the armory module to distinguish between types like "عهدة شخصية".
ALTER TABLE public.warehouses
  ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'عام';

UPDATE public.warehouses
SET type = 'عام'
WHERE type IS NULL;
