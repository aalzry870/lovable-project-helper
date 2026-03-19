-- Create admin_update_role function
CREATE OR REPLACE FUNCTION public.admin_update_role(_user_id UUID, _role app_role)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check caller is admin
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Only admins can update roles';
  END IF;
  
  -- Upsert the role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (_user_id, _role)
  ON CONFLICT (user_id, role) DO NOTHING;
  
  -- Remove other roles
  DELETE FROM public.user_roles WHERE user_id = _user_id AND role != _role;
END;
$$;

-- Create admin_delete_user function
CREATE OR REPLACE FUNCTION public.admin_delete_user(_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check caller is admin
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;
  
  -- Delete profile and roles (cascading from auth.users won't work here)
  DELETE FROM public.user_roles WHERE user_id = _user_id;
  DELETE FROM public.profiles WHERE user_id = _user_id;
END;
$$;