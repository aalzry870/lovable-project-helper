-- Create app_role enum
CREATE TYPE public.app_role AS ENUM ('admin', 'employee');

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles viewable by authenticated" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Create user_roles table
CREATE TABLE public.user_roles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL DEFAULT 'employee',
  UNIQUE (user_id, role)
);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Roles viewable by authenticated" ON public.user_roles FOR SELECT TO authenticated USING (true);

-- Security definer function for role checks
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role
  )
$$;

-- Create categories table
CREATE TABLE public.categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories select" ON public.categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "Categories insert" ON public.categories FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Categories update" ON public.categories FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Categories delete" ON public.categories FOR DELETE TO authenticated USING (true);

-- Create warehouses table
CREATE TABLE public.warehouses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT '',
  location TEXT NOT NULL DEFAULT '',
  manager TEXT NOT NULL DEFAULT '',
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.warehouses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Warehouses select" ON public.warehouses FOR SELECT TO authenticated USING (true);
CREATE POLICY "Warehouses insert" ON public.warehouses FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Warehouses update" ON public.warehouses FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Warehouses delete" ON public.warehouses FOR DELETE TO authenticated USING (true);

-- Create suppliers table
CREATE TABLE public.suppliers (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Suppliers select" ON public.suppliers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Suppliers insert" ON public.suppliers FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Suppliers update" ON public.suppliers FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Suppliers delete" ON public.suppliers FOR DELETE TO authenticated USING (true);

-- Create clients table
CREATE TABLE public.clients (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Clients select" ON public.clients FOR SELECT TO authenticated USING (true);
CREATE POLICY "Clients insert" ON public.clients FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Clients update" ON public.clients FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Clients delete" ON public.clients FOR DELETE TO authenticated USING (true);

-- Create products table
CREATE TABLE public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  category_id UUID REFERENCES public.categories(id),
  quantity INTEGER NOT NULL DEFAULT 0,
  warehouse_id UUID REFERENCES public.warehouses(id),
  description TEXT NOT NULL DEFAULT '',
  image TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Products select" ON public.products FOR SELECT TO authenticated USING (true);
CREATE POLICY "Products insert" ON public.products FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Products update" ON public.products FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Products delete" ON public.products FOR DELETE TO authenticated USING (true);

-- Create stock_movements table
CREATE TABLE public.stock_movements (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  warehouse_id UUID NOT NULL REFERENCES public.warehouses(id),
  type TEXT NOT NULL,
  product_id UUID REFERENCES public.products(id),
  quantity INTEGER,
  unit TEXT,
  entity_id UUID NOT NULL,
  entity_type TEXT NOT NULL,
  date TEXT NOT NULL,
  notes TEXT,
  items JSONB,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Movements select" ON public.stock_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY "Movements insert" ON public.stock_movements FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Movements update" ON public.stock_movements FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Movements delete" ON public.stock_movements FOR DELETE TO authenticated USING (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.warehouses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.suppliers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clients;
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_movements;