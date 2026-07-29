import { createClient } from 'jsr:@supabase/supabase-js@2';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS' };
const json = (o: any, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const { token, password } = await req.json();
    if (!token || !password || String(password).length < 6) return json({ error: 'Token o contraseña inválidos (mín. 6 caracteres).' }, 400);

    const { data: rows } = await admin.from('password_resets').select('*').eq('token', token).eq('status', 'active').limit(1);
    const rec = (rows || [])[0];
    if (!rec) return json({ error: 'Este enlace de reset es inválido o ya fue usado.' }, 400);
    if (new Date(rec.expires_at).getTime() < Date.now()) return json({ error: 'El enlace expiró. Solicita uno nuevo.' }, 400);

    const { data: prof } = await admin.from('profiles').select('id').ilike('email', rec.email).maybeSingle();
    if (!prof) return json({ error: 'Cuenta no encontrada.' }, 404);

    const { error } = await admin.auth.admin.updateUserById(prof.id, { password: String(password) });
    if (error) return json({ error: error.message }, 400);

    await admin.from('password_resets').update({ status: 'used', used_at: new Date().toISOString() }).eq('token', token);
    return json({ ok: true, email: rec.email });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
