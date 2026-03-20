
-- 1. Create organizations table
CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT 'مؤسستي',
  created_at timestamptz NOT NULL DEFAULT now(),
  owner_id uuid NOT NULL
);
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 2. Add organization_id to all data tables
ALTER TABLE public.profiles ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.warehouses ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.categories ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.suppliers ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.clients ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.stock_movements ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;

-- 3. Create security definer function to get user's org_id
CREATE OR REPLACE FUNCTION public.get_user_org_id(_user_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organization_id FROM public.profiles WHERE user_id = _user_id LIMIT 1
$$;

-- 4. Migrate existing data: create org for existing admin
DO $$
DECLARE
  admin_uid uuid;
  new_org_id uuid;
BEGIN
  SELECT user_id INTO admin_uid FROM public.user_roles WHERE role = 'admin' LIMIT 1;
  
  IF admin_uid IS NOT NULL THEN
    new_org_id := gen_random_uuid();
    INSERT INTO public.organizations (id, name, owner_id) VALUES (new_org_id, 'مؤسستي', admin_uid);
    
    UPDATE public.profiles SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.warehouses SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.products SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.categories SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.suppliers SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.clients SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.stock_movements SET organization_id = new_org_id WHERE organization_id IS NULL;
    UPDATE public.notifications SET organization_id = new_org_id WHERE organization_id IS NULL;
  END IF;
END $$;

-- 5. Create trigger: auto-create org + profile + admin role on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_org_id uuid;
  user_name text;
BEGIN
  user_name := COALESCE(NEW.raw_user_meta_data ->> 'display_name', '');
  
  IF EXISTS (SELECT 1 FROM public.profiles WHERE user_id = NEW.id AND organization_id IS NOT NULL) THEN
    RETURN NEW;
  END IF;
  
  new_org_id := gen_random_uuid();
  INSERT INTO public.organizations (id, name, owner_id) VALUES (new_org_id, 'مؤسسة ' || user_name, NEW.id);
  
  INSERT INTO public.profiles (user_id, display_name, organization_id)
  VALUES (NEW.id, user_name, new_org_id)
  ON CONFLICT (user_id) DO UPDATE SET organization_id = new_org_id, display_name = user_name;
  
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'admin')
  ON CONFLICT (user_id, role) DO NOTHING;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Update RLS policies with org isolation

-- Organizations
CREATE POLICY "Users can view own org" ON public.organizations FOR SELECT TO authenticated
  USING (id = public.get_user_org_id(auth.uid()));

-- Profiles
DROP POLICY IF EXISTS "Profiles viewable by authenticated" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Profiles select same org" ON public.profiles FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Profiles insert own" ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "Profiles update own" ON public.profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- Warehouses
DROP POLICY IF EXISTS "Warehouses select" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses insert" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses update" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses delete" ON public.warehouses;

CREATE POLICY "Warehouses select org" ON public.warehouses FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Warehouses insert org" ON public.warehouses FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Warehouses update org" ON public.warehouses FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Warehouses delete org" ON public.warehouses FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Products
DROP POLICY IF EXISTS "Products select" ON public.products;
DROP POLICY IF EXISTS "Products insert" ON public.products;
DROP POLICY IF EXISTS "Products update" ON public.products;
DROP POLICY IF EXISTS "Products delete" ON public.products;

CREATE POLICY "Products select org" ON public.products FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Products insert org" ON public.products FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Products update org" ON public.products FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Products delete org" ON public.products FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Categories
DROP POLICY IF EXISTS "Categories select" ON public.categories;
DROP POLICY IF EXISTS "Categories insert" ON public.categories;
DROP POLICY IF EXISTS "Categories update" ON public.categories;
DROP POLICY IF EXISTS "Categories delete" ON public.categories;

CREATE POLICY "Categories select org" ON public.categories FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Categories insert org" ON public.categories FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Categories update org" ON public.categories FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Categories delete org" ON public.categories FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Suppliers
DROP POLICY IF EXISTS "Suppliers select" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers insert" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers update" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers delete" ON public.suppliers;

CREATE POLICY "Suppliers select org" ON public.suppliers FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Suppliers insert org" ON public.suppliers FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Suppliers update org" ON public.suppliers FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Suppliers delete org" ON public.suppliers FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Clients
DROP POLICY IF EXISTS "Clients select" ON public.clients;
DROP POLICY IF EXISTS "Clients insert" ON public.clients;
DROP POLICY IF EXISTS "Clients update" ON public.clients;
DROP POLICY IF EXISTS "Clients delete" ON public.clients;

CREATE POLICY "Clients select org" ON public.clients FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Clients insert org" ON public.clients FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Clients update org" ON public.clients FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Clients delete org" ON public.clients FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Stock Movements
DROP POLICY IF EXISTS "Movements select" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements insert" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements update" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements delete" ON public.stock_movements;

CREATE POLICY "Movements select org" ON public.stock_movements FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Movements insert org" ON public.stock_movements FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Movements update org" ON public.stock_movements FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Movements delete org" ON public.stock_movements FOR DELETE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));

-- Notifications
DROP POLICY IF EXISTS "Notifications select" ON public.notifications;
DROP POLICY IF EXISTS "Notifications insert" ON public.notifications;
DROP POLICY IF EXISTS "Notifications update" ON public.notifications;

CREATE POLICY "Notifications select org" ON public.notifications FOR SELECT TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Notifications insert org" ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (organization_id = public.get_user_org_id(auth.uid()));
CREATE POLICY "Notifications update org" ON public.notifications FOR UPDATE TO authenticated
  USING (organization_id = public.get_user_org_id(auth.uid()));
