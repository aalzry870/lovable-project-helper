ALTER TABLE public.products ADD COLUMN min_quantity integer NOT NULL DEFAULT 2;
ALTER TABLE public.products ADD COLUMN unit text NOT NULL DEFAULT 'قطعة';