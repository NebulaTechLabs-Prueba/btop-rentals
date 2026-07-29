-- Espeja el estado de baneo (auth) en profiles para que la UI lo lea al recargar.
alter table public.profiles add column if not exists disabled boolean not null default false;
