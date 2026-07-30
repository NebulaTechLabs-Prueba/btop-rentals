-- ── Etapa 3c: fleet/spaces por capacidad (lectura pública del catálogo se mantiene) ──
drop policy if exists admin_write_fleet on public.fleet_units;
create policy fleet_manage on public.fleet_units for all to authenticated using (public.has_cap('fleet','manage')) with check (public.has_cap('fleet','manage'));

drop policy if exists admin_write_spaces on public.storage_spaces;
create policy spaces_manage on public.storage_spaces for all to authenticated using (public.has_cap('spaces','manage')) with check (public.has_cap('spaces','manage'));

drop policy if exists staff_all_spacerent on public.space_rentals;
create policy spacerent_view on public.space_rentals for select to authenticated using (public.has_cap('spaces','view'));
create policy spacerent_manage on public.space_rentals for all to authenticated using (public.has_cap('spaces','manage')) with check (public.has_cap('spaces','manage'));
