-- ── Etapa 3a: enforcement por capacidad en tablas staff-only (preserva políticas de cliente/anon) ──
-- Patrón: SELECT = has_cap(view); INSERT/UPDATE/DELETE = has_cap(manage). admin siempre pasa.

drop policy if exists staff_all_credit on public.credit_lines;
create policy credit_view on public.credit_lines for select to authenticated using (public.has_cap('credit','view'));
create policy credit_manage on public.credit_lines for all to authenticated using (public.has_cap('credit','manage')) with check (public.has_cap('credit','manage'));

drop policy if exists staff_all_deliveries on public.deliveries;
create policy deliveries_view on public.deliveries for select to authenticated using (public.has_cap('deliveries','view'));
create policy deliveries_manage on public.deliveries for all to authenticated using (public.has_cap('deliveries','manage')) with check (public.has_cap('deliveries','manage'));

drop policy if exists staff_all_contracts on public.contracts;
create policy contracts_view on public.contracts for select to authenticated using (public.has_cap('contracts','view'));
create policy contracts_manage on public.contracts for all to authenticated using (public.has_cap('contracts','manage')) with check (public.has_cap('contracts','manage'));

drop policy if exists staff_all_contacts on public.contacts;
create policy contacts_view on public.contacts for select to authenticated using (public.has_cap('contacts','view'));
create policy contacts_manage on public.contacts for all to authenticated using (public.has_cap('contacts','manage')) with check (public.has_cap('contacts','manage'));

drop policy if exists staff_all_invoices on public.invoices;
create policy invoices_view on public.invoices for select to authenticated using (public.has_cap('invoices','view'));
create policy invoices_manage on public.invoices for all to authenticated using (public.has_cap('invoices','manage')) with check (public.has_cap('invoices','manage'));

drop policy if exists staff_all_messages on public.messages;
create policy messages_view on public.messages for select to authenticated using (public.has_cap('messages','view'));
create policy messages_manage on public.messages for all to authenticated using (public.has_cap('messages','manage')) with check (public.has_cap('messages','manage'));

drop policy if exists invites_staff on public.invites;
create policy invites_users on public.invites for all to authenticated using (public.has_cap('users','manage')) with check (public.has_cap('users','manage'));

drop policy if exists admin_write_posts on public.posts;
create policy posts_manage on public.posts for all to authenticated using (public.has_cap('posts','manage')) with check (public.has_cap('posts','manage'));
drop policy if exists read_posts on public.posts;
create policy read_posts on public.posts for select to public using ((status = 'published') or public.has_cap('posts','view'));
