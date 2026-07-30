-- Backstop a nivel DB: un contacto por correo (case-insensitive). Evita duplicados por cualquier vía.
create unique index if not exists contacts_email_unique on public.contacts (lower(email)) where email is not null and email <> '';
