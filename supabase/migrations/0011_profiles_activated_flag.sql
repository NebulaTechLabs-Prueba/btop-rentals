-- "activated" = la cuenta realmente se activó (confirmó email / inició sesión), no solo fue invitada.
alter table public.profiles add column if not exists activated boolean not null default false;
-- Backfill: marca activadas las cuentas de auth ya confirmadas o que alguna vez iniciaron sesión.
update public.profiles p set activated = true
  from auth.users u
  where p.id = u.id and (u.email_confirmed_at is not null or u.last_sign_in_at is not null);
