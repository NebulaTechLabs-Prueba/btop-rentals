-- Reset de contraseña por flujo propio (sin GoTrue): token de un solo uso, 1h de validez.
-- Solo lo tocan las Edge Functions (service role); RLS activo sin políticas = denegado a clientes.
create table if not exists public.password_resets (
  token text primary key,
  email text not null,
  status text not null default 'active',  -- active | used
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '1 hour'),
  used_at timestamptz
);
alter table public.password_resets enable row level security;
