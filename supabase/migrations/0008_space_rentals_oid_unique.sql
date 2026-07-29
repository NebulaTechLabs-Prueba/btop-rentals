-- Cada renta de espacio corresponde a una orden (oid). Único → permite upsert idempotente.
alter table public.space_rentals add constraint space_rentals_oid_key unique (oid);
