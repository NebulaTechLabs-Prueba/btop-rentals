-- Invitaciones de cuenta (magic-link). El staff las crea; el invitado (anónimo) valida su token vía RPC.
create table if not exists public.invites (
  token text primary key,
  email text not null,
  name text,
  phone text,
  role text not null default 'client',
  status text not null default 'active',   -- active | used
  invited_by text,
  created_at timestamptz not null default now(),
  used_at timestamptz
);
alter table public.invites enable row level security;

drop policy if exists invites_staff on public.invites;
create policy invites_staff on public.invites for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- RPC: valida un token y devuelve SOLO esa invitación (no expone la tabla). Callable por anon.
create or replace function public.get_invite(p_token text)
returns table(email text, name text, phone text, role text)
language sql security definer set search_path = public as $$
  select email, name, phone, role from public.invites where token = p_token and status = 'active' limit 1;
$$;
revoke all on function public.get_invite(text) from public;
grant execute on function public.get_invite(text) to anon, authenticated;

-- RPC: marca la invitación como usada tras crear la cuenta.
create or replace function public.consume_invite(p_token text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.invites set status = 'used', used_at = now() where token = p_token and status = 'active';
end $$;
revoke all on function public.consume_invite(text) from public;
grant execute on function public.consume_invite(text) to anon, authenticated;
