-- carts uses the jsonb-blob collection pattern like the other tables; add the column.
alter table public.carts add column if not exists data jsonb not null default '{}'::jsonb;
