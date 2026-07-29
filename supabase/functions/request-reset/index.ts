import { createClient } from 'jsr:@supabase/supabase-js@2';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS' };
const json = (o: any, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const { email, base } = await req.json();
    if (!email) return json({ error: 'Falta el email' }, 400);
    const emailNorm = String(email).trim().toLowerCase();

    // Solo enviamos si la cuenta existe. Respondemos ok igual (no revelar si el correo está registrado).
    const { data: prof } = await admin.from('profiles').select('id, name, email').ilike('email', emailNorm).maybeSingle();
    if (!prof) return json({ ok: true });

    // Token de un solo uso + persistencia (expira en 1h por default de la tabla).
    const token = 'RST' + crypto.randomUUID().replace(/-/g, '');
    await admin.from('password_resets').insert({ token, email: prof.email });

    const baseUrl = (typeof base === 'string' && /^https?:\/\//.test(base)) ? base.replace(/\/+$/, '') : 'https://btop-rentals.com';
    const reset_url = `${baseUrl}/?reset=${token}`;

    // Correo branded bajo el dominio propio (respeta email_enabled). No expone el backend.
    try { await admin.functions.invoke('send-email', { body: { type: 'password-reset', to: prof.email, data: { name: prof.name || '', reset_url } } }); } catch (_e) { /* best-effort */ }
    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
