-- Booking side-effects: al agendar una reserva (Sales/cliente) se crean registros en
-- deliveries y space_rentals. Esos INSERT deben permitirse a cualquier staff (efecto del booking),
-- mientras que VER/EDITAR/BORRAR (gestión de esas secciones) sigue gateado por capacidad.
create policy deliveries_insert_staff on public.deliveries for insert to authenticated with check (public.is_staff());
create policy spacerent_insert_staff on public.space_rentals for insert to authenticated with check (public.is_staff());
