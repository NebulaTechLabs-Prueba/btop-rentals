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

    // Valida el token (activo) usando el service role.
    const { data: invRows } = await admin.from('invites').select('*').eq('token', token).eq('status', 'active').limit(1);
    const inv = (invRows || [])[0];
    if (!inv || !inv.email) return json({ error: 'Esta invitación es inválida o ya fue usada. Solicita una nueva.' }, 400);
    const role = inv.role || 'client';

    // Crea la cuenta YA CONFIRMADA (no depende de la confirmación por email).
    const { data: created, error: ce } = await admin.auth.admin.createUser({ email: inv.email, password: String(password), email_confirm: true, user_metadata: { name: inv.name || '' } });
    if (ce || !created?.user) {
      const msg = (ce?.message || '').toLowerCase();
      if (msg.includes('already') || msg.includes('registered') || msg.includes('exists')) return json({ error: 'Ya existe una cuenta con este correo. Por favor inicia sesión.' }, 409);
      return json({ error: ce?.message || 'No se pudo crear la cuenta.' }, 400);
    }
    const uid = created.user.id;
    await admin.auth.admin.updateUserById(uid, { app_metadata: { role } });
    await admin.from('profiles').upsert({ id: uid, email: inv.email, name: inv.name || inv.email.split('@')[0], role });

    // Registra el contacto (autoritativo, deduplica por email) en la forma que hidrata la app (columna data jsonb).
    const nowDate = new Date().toISOString().split('T')[0];
    const { data: exRows } = await admin.from('contacts').select('id, data').eq('email', inv.email).limit(1);
    const ex = (exRows || [])[0];
    if (ex) {
      const d = { ...(ex.data || {}), name: inv.name || ex.data?.name, email: inv.email, phone: (ex.data?.phone) || inv.phone || '', hasAccount: true };
      await admin.from('contacts').update({ has_account: true, name: inv.name || undefined, data: d }).eq('id', ex.id);
    } else {
      const cid = crypto.randomUUID();
      const d = { id: cid, name: inv.name || '', email: inv.email, phone: inv.phone || '', city: '', company: '', idDoc: '', registered: nowDate, lastOrder: '', totalSpent: 0, orders: 0, hasAccount: true };
      await admin.from('contacts').insert({ id: cid, name: inv.name || '', email: inv.email, phone: inv.phone || '', has_account: true, registered: nowDate, data: d });
    }

    // Marca la invitación como usada.
    await admin.from('invites').update({ status: 'used', used_at: new Date().toISOString() }).eq('token', token);
    return json({ ok: true, email: inv.email, name: inv.name || '' });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
