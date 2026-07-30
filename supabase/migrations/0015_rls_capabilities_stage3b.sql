-- ── Etapa 3b: tablas compartidas con cliente (carts/orders) + bookings + settings ──

-- carts → 'carts' (conserva las políticas de dueño existentes)
drop policy if exists staff_all_carts on public.carts;
create policy carts_staff_view on public.carts for select to authenticated using (public.has_cap('carts','view'));
create policy carts_staff_manage on public.carts for all to authenticated using (public.has_cap('carts','manage')) with check (public.has_cap('carts','manage'));

-- bookings → 'bookings' (staff-only)
drop policy if exists staff_all_bookings on public.bookings;
create policy bookings_view on public.bookings for select to authenticated using (public.has_cap('bookings','view'));
create policy bookings_manage on public.bookings for all to authenticated using (public.has_cap('bookings','manage')) with check (public.has_cap('bookings','manage'));

-- orders: lectura amplia (staff + dueño); la APROBACIÓN (update/delete) exige 'payments'.
drop policy if exists staff_all_orders on public.orders;
drop policy if exists client_insert_orders on public.orders;
drop policy if exists client_read_orders on public.orders;
drop policy if exists client_update_orders on public.orders;
create policy orders_read on public.orders for select to public using ((customer_email = (auth.jwt() ->> 'email')) or public.is_staff());
create policy orders_insert on public.orders for insert to public with check ((customer_email = (auth.jwt() ->> 'email')) or public.is_staff());
create policy orders_update on public.orders for update to public using ((customer_email = (auth.jwt() ->> 'email')) or public.has_cap('payments','manage')) with check ((customer_email = (auth.jwt() ->> 'email')) or public.has_cap('payments','manage'));
create policy orders_delete on public.orders for delete to public using (public.has_cap('payments','manage'));

-- settings: escritura por 'settings:manage' (incluye admin), o commission_policy con 'commissions:manage'.
drop policy if exists admin_write_settings on public.settings;
create policy settings_write on public.settings for all to authenticated
  using (public.has_cap('settings','manage') or (key='commission_policy' and public.has_cap('commissions','manage')))
  with check (public.has_cap('settings','manage') or (key='commission_policy' and public.has_cap('commissions','manage')));
