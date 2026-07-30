-- ── Sistema de roles con capacidades por sección (enforced en RLS) ──
-- profiles.role = KEY del rol (sistema: admin/sede/sales/client, o custom).
-- app_metadata.role (JWT) = base → sigue manejando ruteo; las CAPACIDADES finas viven aquí.
create table if not exists public.roles (
  key text primary key,
  name text not null,
  base text not null default 'sales',            -- panel/vista: admin | office | sede | sales | client
  capabilities jsonb not null default '{}'::jsonb, -- { seccion: 'none'|'view'|'manage' }
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.roles enable row level security;

insert into public.roles (key,name,base,capabilities,is_system) values
 ('admin','Super Admin','admin','{"fleet":"manage","spaces":"manage","contacts":"manage","bookings":"manage","payments":"manage","credit":"manage","invoices":"manage","contracts":"manage","commissions":"manage","posts":"manage","messages":"manage","carts":"manage","deliveries":"manage","users":"manage","settings":"manage"}'::jsonb,true),
 ('sede','Fleet Manager','sede','{"fleet":"manage","spaces":"manage","bookings":"manage","deliveries":"manage","contacts":"view","invoices":"view","contracts":"view"}'::jsonb,true),
 ('sales','Sales Rep','sales','{"contacts":"manage","bookings":"manage","carts":"manage","commissions":"view","invoices":"view"}'::jsonb,true),
 ('client','Client','client','{}'::jsonb,true)
on conflict (key) do nothing;

-- Capacidades del usuario actual (join profiles→roles). SECURITY DEFINER evita recursión RLS.
create or replace function public.auth_caps()
returns jsonb language sql stable security definer set search_path=public as $$
  select coalesce(r.capabilities,'{}'::jsonb) from public.profiles p join public.roles r on r.key = p.role where p.id = auth.uid();
$$;

-- ¿tiene al menos `min_level` en `section`? admin siempre true. manage>view>none.
create or replace function public.has_cap(section text, min_level text)
returns boolean language sql stable security definer set search_path=public as $$
  select case
    when public.is_admin() then true
    else case coalesce(public.auth_caps()->>section,'none')
      when 'manage' then true
      when 'view' then (min_level = 'view')
      else false
    end
  end;
$$;

revoke all on function public.auth_caps() from public;   grant execute on function public.auth_caps() to authenticated;
revoke all on function public.has_cap(text,text) from public; grant execute on function public.has_cap(text,text) to authenticated;

drop policy if exists roles_read on public.roles;
create policy roles_read on public.roles for select to authenticated using (true);
drop policy if exists roles_write on public.roles;
create policy roles_write on public.roles for all to authenticated
  using (public.has_cap('users','manage')) with check (public.has_cap('users','manage'));

-- Nota: is_admin/is_staff NO se tocan (siguen leyendo el JWT). Un rol 'office' recibe JWT base 'sales'
-- (staff, no admin); sus permisos REALES los da has_cap() vía la tabla roles. El panel recortado se
-- decide en el cliente leyendo roles.base. Las tablas sensibles se migran a has_cap por etapas.
