import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const authHeader = req.headers.get('Authorization')!

    // Client with user's token to verify identity
    const userClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user: caller }, error: authError } = await userClient.auth.getUser()
    if (authError || !caller) {
      return new Response(JSON.stringify({ error: 'غير مصرح' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Admin client
    const adminClient = createClient(supabaseUrl, serviceRoleKey)

    // Check caller is admin
    const { data: roleData } = await adminClient
      .from('user_roles')
      .select('role')
      .eq('user_id', caller.id)
      .single()

    if (roleData?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'فقط المدير يمكنه إنشاء موظفين' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get caller's org
    const { data: callerProfile } = await adminClient
      .from('profiles')
      .select('organization_id')
      .eq('user_id', caller.id)
      .single()

    if (!callerProfile?.organization_id) {
      return new Response(JSON.stringify({ error: 'لا توجد مؤسسة مرتبطة' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const orgId = callerProfile.organization_id

    // Check employee count (max 3)
    const { count } = await adminClient
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', orgId)
      .neq('user_id', caller.id)

    if ((count ?? 0) >= 3) {
      return new Response(JSON.stringify({ error: 'الحد الأقصى 3 موظفين لكل مؤسسة' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { email, password, displayName } = await req.json()

    if (!email || !password || !displayName) {
      return new Response(JSON.stringify({ error: 'البريد وكلمة المرور والاسم مطلوبون' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Create user with admin API
    const { data: newUser, error: createError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: displayName },
    })

    if (createError) {
      return new Response(JSON.stringify({ error: createError.message }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Create profile with same org (the trigger will try to create a new org, so we need to handle this)
    // First delete any org created by the trigger for this user
    const { data: autoProfile } = await adminClient
      .from('profiles')
      .select('organization_id')
      .eq('user_id', newUser.user.id)
      .single()

    if (autoProfile?.organization_id && autoProfile.organization_id !== orgId) {
      // Delete the auto-created org
      await adminClient.from('organizations').delete().eq('id', autoProfile.organization_id)
    }

    // Update profile to use the admin's org
    await adminClient
      .from('profiles')
      .update({ organization_id: orgId, display_name: displayName })
      .eq('user_id', newUser.user.id)

    // Update role to employee
    await adminClient
      .from('user_roles')
      .update({ role: 'employee' })
      .eq('user_id', newUser.user.id)

    return new Response(JSON.stringify({ success: true, userId: newUser.user.id }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
