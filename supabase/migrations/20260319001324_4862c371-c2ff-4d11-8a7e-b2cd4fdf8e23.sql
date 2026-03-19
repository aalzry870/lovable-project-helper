
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin'::app_role FROM auth.users WHERE email = 'mofeedzary123@gmail.com'
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO public.profiles (user_id, display_name)
SELECT id, 'المدير' FROM auth.users WHERE email = 'mofeedzary123@gmail.com'
ON CONFLICT DO NOTHING;
