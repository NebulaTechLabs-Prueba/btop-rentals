import { createClient } from 'jsr:@supabase/supabase-js@2';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS' };
const json = (o: any, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    // El llamante debe ser admin (rol leído del JWT).
    const token = (req.headers.get('Authorization') || '').replace('Bearer ', '');
    const { data: me } = await admin.auth.getUser(token);
    if (!me?.user || me.user.app_metadata?.role !== 'admin') return json({ error: 'Solo un administrador puede gestionar cuentas.' }, 403);

    const { action, email, role, active, password } = await req.json();
    if (!email) return json({ error: 'Falta el email' }, 400);

    const { data: prof } = await admin.from('profiles').select('id, role').eq('email', email).maybeSingle();
    if (!prof) return json({ error: 'Usuario no encontrado' }, 404);
    if (prof.id === me.user.id) return json({ error: 'No puedes modificar tu propia cuenta.' }, 400);
    // Protege a los administradores existentes (coincide con el bloqueo de la UI).
    if (prof.role === 'admin') return json({ error: 'La cuenta de administrador está protegida.' }, 403);

    if (action === 'role') {
      // `role` es la KEY del rol; resolvemos su base desde la tabla roles.
      const { data: roleRow } = await admin.from('roles').select('key, base').eq('key', role).maybeSingle();
      if (!roleRow) return json({ error: 'Rol no encontrado' }, 400);
      const base = roleRow.base || 'sales';
      if (base === 'admin') return json({ error: 'No se puede asignar el rol de administrador total desde aquí.' }, 403);
      const jwtRole = base === 'sede' ? 'sede' : base === 'client' ? 'client' : 'sales'; // office→sales
      const { error: e1 } = await admin.auth.admin.updateUserById(prof.id, { app_metadata: { role: jwtRole, panel: base } });
      if (e1) return json({ error: e1.message }, 400);
      await admin.from('profiles').update({ role }).eq('id', prof.id);
      return json({ ok: true, role, base });
    }
    if (action === 'status') {
      const ban = active === false ? '876000h' : 'none';
      const { error: e2 } = await admin.auth.admin.updateUserById(prof.id, { ban_duration: ban });
      if (e2) return json({ error: e2.message }, 400);
      await admin.from('profiles').update({ disabled: active === false }).eq('id', prof.id);
      return json({ ok: true, active: active !== false });
    }
    if (action === 'set_password') {
      if (!password || String(password).length < 6) return json({ error: 'La contraseña debe tener al menos 6 caracteres.' }, 400);
      const { error: e3 } = await admin.auth.admin.updateUserById(prof.id, { password: String(password) });
      if (e3) return json({ error: e3.message }, 400);
      return json({ ok: true });
    }
    return json({ error: 'Acción inválida' }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
