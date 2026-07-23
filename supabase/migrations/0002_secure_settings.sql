-- Write-only secrets store (Stripe secret & webhook keys, etc.)
-- Admin may write; NO select policy => only the service_role (Edge Functions)
-- can read the values. Not even admins can read them back from the client.
create table if not exists public.secure_settings (
  key text primary key,
  value text,
  updated_at timestamptz not null default now()
);
alter table public.secure_settings enable row level security;

drop policy if exists secure_settings_admin_insert on public.secure_settings;
drop policy if exists secure_settings_admin_update on public.secure_settings;
create policy secure_settings_admin_insert on public.secure_settings
  for insert to authenticated with check (public.is_admin());
create policy secure_settings_admin_update on public.secure_settings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
