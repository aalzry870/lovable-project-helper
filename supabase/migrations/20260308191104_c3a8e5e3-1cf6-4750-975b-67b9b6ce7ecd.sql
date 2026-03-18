
-- Create admin account: first drop the trigger temporarily to handle custom role
-- We'll use a different approach: create a function that can promote a user to admin
CREATE OR REPLACE FUNCTION public.promote_to_admin(_email text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _user_id uuid;
BEGIN
  SELECT id INTO _user_id FROM auth.users WHERE email = _email;
  IF _user_id IS NOT NULL THEN
    UPDATE public.user_roles SET role = 'admin' WHERE user_id = _user_id;
    IF NOT FOUND THEN
      INSERT INTO public.user_roles (user_id, role) VALUES (_user_id, 'admin');
    END IF;
  END IF;
END;
$$;
