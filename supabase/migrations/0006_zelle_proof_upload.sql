-- El comprobante de pago Zelle lo sube el cliente/invitado durante el checkout público.
-- Se permite INSERT SOLO bajo el prefijo `zelle/` del bucket fleet-media (nada más).
drop policy if exists zelle_proof_insert on storage.objects;
create policy zelle_proof_insert on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'fleet-media' and (storage.foldername(name))[1] = 'zelle');
