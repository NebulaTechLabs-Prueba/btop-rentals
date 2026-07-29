import { createClient } from 'jsr:@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || Deno.env.get('Btop-Resend') || Deno.env.get('Btop_Resend') || Deno.env.get('BTOP_RESEND');
const FROM = Deno.env.get('EMAIL_FROM') || 'BTOP Rentals <no-reply@btop-rentals.com>';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const B = { navy: '#0A1628', chip: '#1E3A5F', blue: '#1B4DDB', muted: '#6B7280', border: '#E5E7EB' };

function shell(body: string, badge: any, company: any) {
  const badgeHtml = badge
    ? `<td align="right"><span style="display:inline-block;padding:5px 12px;border-radius:20px;background:${badge.bg};color:${badge.fg};font-size:11px;font-weight:700;">${badge.text}</span></td>`
    : '';
  return `<!doctype html><html><body style="margin:0;padding:0;background:#F3F4F6;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F3F4F6;padding:24px 0;"><tr><td align="center">
<table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 16px rgba(11,37,69,.08);">
<tr><td style="background:${B.navy};padding:28px 32px;"><table width="100%"><tr>
<td><table cellpadding="0" cellspacing="0"><tr><td style="background:${B.chip};border-radius:10px;padding:8px 12px;"><span style="color:#fff;font-weight:800;font-size:18px;letter-spacing:.5px;">BTOP</span></td><td style="padding-left:12px;color:#93C5FD;font-size:11px;font-weight:700;letter-spacing:2px;">RENTALS</td></tr></table></td>
${badgeHtml}
</tr></table></td></tr>
<tr><td style="padding:36px 32px 8px;">${body}</td></tr>
<tr><td style="padding:24px 32px 28px;border-top:1px solid ${B.border};"><p style="margin:0;font-size:12px;line-height:1.7;color:#9CA3AF;"><strong style="color:${B.muted};">${company.name || 'BTOP Rentals'}</strong><br>${company.address || ''}<br>${company.phone || ''} · ${company.email || ''}</p></td></tr>
</table></td></tr></table></body></html>`;
}

const btn = (url: string, label: string) => `<table cellpadding="0" cellspacing="0" style="margin:8px 0 24px;"><tr><td style="border-radius:12px;background:${B.blue};"><a href="${url}" style="display:inline-block;padding:14px 28px;font-size:15px;font-weight:700;color:#fff;text-decoration:none;border-radius:12px;">${label}</a></td></tr></table>`;
const rowT = (k: string, v: string, strong?: boolean) => `<tr><td style="padding:10px 18px;font-size:13px;color:${B.muted};border-top:1px solid #EEF0F2;">${k}</td><td style="padding:10px 18px;font-size:${strong ? '15px' : '13px'};color:${strong ? B.blue : '#111827'};font-weight:${strong ? 800 : 700};text-align:right;border-top:1px solid #EEF0F2;">${v}</td></tr>`;
const box = (rows: string) => `<table width="100%" cellpadding="0" cellspacing="0" style="background:#F9FAFB;border:1px solid ${B.border};border-radius:12px;margin:0 0 20px;">${rows}</table>`;
const P = (t: string) => `<p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#374151;">${t}</p>`;
const H = (t: string) => `<h1 style="margin:0 0 12px;font-size:22px;color:${B.navy};">${t}</h1>`;
const esc = (s: any = '') => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const textToHtml = (t: any = '') => esc(t).split(/\n{2,}/).map((par: string) => `<p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#374151;">${par.replace(/\n/g, '<br>')}</p>`).join('');

function build(type: string, d: any) {
  switch (type) {
    case 'reservation-confirmed':
      // Si el admin editó la plantilla (asunto/saludo/cuerpo), se usa DENTRO del diseño branded.
      if (d.custom_body) {
        const greet = d.custom_greeting ? `<p style="margin:0 0 16px;font-size:16px;font-weight:700;color:${B.navy};">${esc(d.custom_greeting)}</p>` : '';
        return { subject: d.custom_subject || `Reservation ${d.order_number} confirmed`, badge: { text: 'CONFIRMED', bg: '#065F46', fg: '#D1FAE5' },
          body: greet + textToHtml(d.custom_body) };
      }
      return { subject: `Reservation ${d.order_number} confirmed`, badge: { text: 'CONFIRMED', bg: '#065F46', fg: '#D1FAE5' },
        body: H('Reservation confirmed') + P(`Hi ${d.client_name || ''}, your reservation is confirmed.`) + box(rowT('Order', d.order_number) + rowT('Item', d.item) + rowT('Dates', `${d.start} → ${d.end}`) + rowT('Total', d.total, true)) + P('Questions? Reply to this email.') };
    case 'payment-validated':
      return { subject: `Payment received — ${d.order_number}`, badge: { text: '✓ PAYMENT RECEIVED', bg: '#065F46', fg: '#D1FAE5' },
        body: H('Payment confirmed') + P(`Hi ${d.client_name || ''}, we've received and validated your payment.`) + box(rowT('Order', d.order_number) + rowT('Method', d.method) + rowT('Amount', d.amount, true)) };
    case 'payment-rejected':
      return { subject: `Action needed — payment for ${d.order_number}`, badge: { text: '✕ NOT VERIFIED', bg: '#991B1B', fg: '#FEE2E2' },
        body: H("We couldn't verify your payment") + P(`Hi ${d.client_name || ''}, we were unable to verify the payment for order <strong>${d.order_number}</strong>.`) + btn(d.resubmit_url || '#', 'Re-submit payment') };
    case 'rental-agreement':
      return { subject: `Your rental agreement ${d.contract_number}`,
        body: H('Your rental agreement') + P(`Hi ${d.client_name || ''}, your signed agreement <strong>${d.contract_number}</strong> is attached to this email as a PDF.`) + btn(d.download_url || '#', 'Open BTOP Rentals') };
    case 'invoice':
      return { subject: `Invoice ${d.invoice_number}`,
        body: H(`Invoice ${d.invoice_number}`) + P(`Hi ${d.client_name || ''}, here is your invoice.`) + box(rowT('Amount due', d.amount_due, true) + rowT('Due date', d.due_date)) + btn(d.pay_url || '#', 'View & pay invoice') };
    case 'reply':
      // Respuesta manual del staff a un mensaje del formulario de contacto.
      return { subject: d.subject || 'Reply from BTOP Rentals',
        body: H('Reply from BTOP Rentals') + (d.client_name ? `<p style="margin:0 0 16px;font-size:16px;font-weight:700;color:${B.navy};">Hi ${esc(d.client_name)},</p>` : '') + textToHtml(d.message) + P('Questions? Just reply to this email.') };
    case 'account-invite':
      // Invitación de cuenta (cliente o staff). El enlace va bajo el dominio propio (no expone el backend).
      return { subject: 'You’re invited to BTOP Rentals', badge: { text: 'INVITATION', bg: '#1E3A5F', fg: '#DBEAFE' },
        body: H('You’re invited') + P(`Hi ${esc(d.name || '')}, you’ve been invited to create your BTOP Rentals account${d.role_label ? ` as <strong>${esc(d.role_label)}</strong>` : ''}. Click below to set your password and activate it.`) + btn(d.invite_url || '#', 'Activate account') + P('If the button doesn’t work, copy and paste this link into your browser:') + `<p style="margin:0 0 20px;font-size:13px;line-height:1.5;color:${B.blue};word-break:break-all;">${esc(d.invite_url || '')}</p>` };
    default:
      return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    if (!RESEND_API_KEY) return new Response(JSON.stringify({ error: 'RESEND_API_KEY not set' }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } });
    const { type, to, data, attachment } = await req.json();
    const tpl = build(type, data || {});
    if (!tpl || !to) return new Response(JSON.stringify({ error: 'invalid type or missing recipient' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } });
    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const { data: rows } = await admin.from('settings').select('key,value').in('key', ['company', 'email_enabled']);
    const company = rows?.find((r: any) => r.key === 'company')?.value || { name: 'BTOP Rentals', address: '9807 Mines Rd #9, Laredo TX 78045', phone: '+1 469 690 712', email: 'btoprentals@gmail.com' };
    const enabled = rows?.find((r: any) => r.key === 'email_enabled')?.value === true;
    if (!enabled) {
      await admin.from('email_log').insert({ to_email: to, subject: tpl.subject, template: type, meta: { skipped: true, reason: 'email_enabled=false' } });
      return new Response(JSON.stringify({ ok: true, skipped: true }), { status: 200, headers: { ...cors, 'Content-Type': 'application/json' } });
    }
    const html = shell(tpl.body, (tpl as any).badge, company);
    const payload: any = { from: FROM, to: [to], subject: tpl.subject, html };
    if (attachment && attachment.content && attachment.filename) payload.attachments = [{ filename: attachment.filename, content: attachment.content }];
    const r = await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
    const out = await r.json().catch(() => ({}));
    await admin.from('email_log').insert({ to_email: to, subject: tpl.subject, template: type, meta: { id: out?.id, ok: r.ok, attached: !!payload.attachments } });
    return new Response(JSON.stringify({ ok: r.ok, id: out?.id, error: out?.error }), { status: r.ok ? 200 : 502, headers: { ...cors, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } });
  }
});
