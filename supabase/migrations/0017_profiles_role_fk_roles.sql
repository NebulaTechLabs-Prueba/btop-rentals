-- El CHECK rígido (admin/sede/sales/client) impedía asignar roles custom: los upserts de
-- accept-invite / admin-user fallaban en silencio y el rol quedaba en 'client'.
-- Se reemplaza por integridad referencial contra la tabla roles.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_fk foreign key (role) references public.roles(key) on update cascade on delete set default;
alter table public.profiles alter column role set default 'client';
