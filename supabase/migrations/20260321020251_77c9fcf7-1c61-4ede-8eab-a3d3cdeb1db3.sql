
-- Drop ALL existing RLS policies
DROP POLICY IF EXISTS "Users can view own org" ON public.organizations;
DROP POLICY IF EXISTS "Movements select org" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements insert org" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements update org" ON public.stock_movements;
DROP POLICY IF EXISTS "Movements delete org" ON public.stock_movements;
DROP POLICY IF EXISTS "Suppliers select org" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers insert org" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers update org" ON public.suppliers;
DROP POLICY IF EXISTS "Suppliers delete org" ON public.suppliers;
DROP POLICY IF EXISTS "Categories select org" ON public.categories;
DROP POLICY IF EXISTS "Categories insert org" ON public.categories;
DROP POLICY IF EXISTS "Categories update org" ON public.categories;
DROP POLICY IF EXISTS "Categories delete org" ON public.categories;
DROP POLICY IF EXISTS "Users manage own tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Roles viewable by authenticated" ON public.user_roles;
DROP POLICY IF EXISTS "Clients select org" ON public.clients;
DROP POLICY IF EXISTS "Clients insert org" ON public.clients;
DROP POLICY IF EXISTS "Clients update org" ON public.clients;
DROP POLICY IF EXISTS "Clients delete org" ON public.clients;
DROP POLICY IF EXISTS "Products select org" ON public.products;
DROP POLICY IF EXISTS "Products insert org" ON public.products;
DROP POLICY IF EXISTS "Products update org" ON public.products;
DROP POLICY IF EXISTS "Products delete org" ON public.products;
DROP POLICY IF EXISTS "Notifications select org" ON public.notifications;
DROP POLICY IF EXISTS "Notifications insert org" ON public.notifications;
DROP POLICY IF EXISTS "Notifications update org" ON public.notifications;
DROP POLICY IF EXISTS "Warehouses select org" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses insert org" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses update org" ON public.warehouses;
DROP POLICY IF EXISTS "Warehouses delete org" ON public.warehouses;
DROP POLICY IF EXISTS "Profiles select same org" ON public.profiles;
DROP POLICY IF EXISTS "Profiles insert own" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;

-- Simple RLS: all authenticated users can read/write everything
-- warehouses
CREATE POLICY "auth_select" ON public.warehouses FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.warehouses FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.warehouses FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.warehouses FOR DELETE TO authenticated USING (true);

-- products
CREATE POLICY "auth_select" ON public.products FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.products FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.products FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.products FOR DELETE TO authenticated USING (true);

-- categories
CREATE POLICY "auth_select" ON public.categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.categories FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.categories FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.categories FOR DELETE TO authenticated USING (true);

-- suppliers
CREATE POLICY "auth_select" ON public.suppliers FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.suppliers FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.suppliers FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.suppliers FOR DELETE TO authenticated USING (true);

-- clients
CREATE POLICY "auth_select" ON public.clients FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.clients FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.clients FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.clients FOR DELETE TO authenticated USING (true);

-- stock_movements
CREATE POLICY "auth_select" ON public.stock_movements FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.stock_movements FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.stock_movements FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.stock_movements FOR DELETE TO authenticated USING (true);

-- notifications
CREATE POLICY "auth_select" ON public.notifications FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.notifications FOR UPDATE TO authenticated USING (true);
CREATE POLICY "auth_delete" ON public.notifications FOR DELETE TO authenticated USING (true);

-- profiles
CREATE POLICY "auth_select" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "auth_update" ON public.profiles FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- user_roles
CREATE POLICY "auth_select" ON public.user_roles FOR SELECT TO authenticated USING (true);

-- fcm_tokens
CREATE POLICY "auth_all" ON public.fcm_tokens FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- organizations
CREATE POLICY "auth_select" ON public.organizations FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert" ON public.organizations FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update" ON public.organizations FOR UPDATE TO authenticated USING (true);

-- Update trigger: new users get 'employee' role instead of 'admin'
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  user_name text;
BEGIN
  user_name := COALESCE(NEW.raw_user_meta_data ->> 'display_name', '');
  
  INSERT INTO public.profiles (user_id, display_name)
  VALUES (NEW.id, user_name)
  ON CONFLICT (user_id) DO UPDATE SET display_name = user_name;
  
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'employee')
  ON CONFLICT (user_id, role) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Re-attach trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
