
-- Make product_id, quantity, unit nullable for multi-product movements
ALTER TABLE public.stock_movements ALTER COLUMN product_id DROP NOT NULL;
ALTER TABLE public.stock_movements ALTER COLUMN quantity DROP NOT NULL;
ALTER TABLE public.stock_movements ALTER COLUMN unit DROP NOT NULL;

-- Add items column for multi-product movements
ALTER TABLE public.stock_movements ADD COLUMN IF NOT EXISTS items jsonb;
