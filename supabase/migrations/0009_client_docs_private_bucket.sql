-- Bucket PRIVADO para documentos de verificación del cliente (licencia, seguro, etc. = PII).
-- No es público: se accede solo con signed URLs. RLS: el dueño ve/borra los suyos; el staff ve todos.
insert into storage.buckets (id, name, public) values ('client-docs','client-docs', false)
  on conflict (id) do nothing;

drop policy if exists client_docs_insert on storage.objects;
create policy client_docs_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'client-docs');

drop policy if exists client_docs_select on storage.objects;
create policy client_docs_select on storage.objects for select to authenticated
  using (bucket_id = 'client-docs' and (owner = auth.uid() or is_staff()));

drop policy if exists client_docs_delete on storage.objects;
create policy client_docs_delete on storage.objects for delete to authenticated
  using (bucket_id = 'client-docs' and (owner = auth.uid() or is_staff()));
