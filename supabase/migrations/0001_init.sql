-- BTOP Rentals — initial schema (Phase 1: persistence)
-- Managed Supabase (Postgres). Run with the Supabase CLI: `supabase db push`.
-- Types stay close to the app's current shapes; nested/flexible data uses jsonb.

-- ─────────────────────────────────────────────────────────────
-- Helpers: role of the current user (set in Phase 2 — Auth)
-- ─────────────────────────────────────────────────────────────
create or replace function public.auth_role() returns text
  language sql stable as $$ select coalesce((select role from public.profiles where id = auth.uid()), 'anon') $$;

create or replace function public.is_staff() returns boolean
  language sql stable as $$ select public.auth_role() in ('admin','sede','sales') $$;

create or replace function public.is_admin() returns boolean
  language sql stable as $$ select public.auth_role() = 'admin' $$;

-- updated_at trigger
create or replace function public.touch_updated_at() returns trigger
  language plpgsql as $$ begin new.updated_at = now(); return new; end $$;

-- ─────────────────────────────────────────────────────────────
-- Identity
-- ─────────────────────────────────────────────────────────────
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  name text,
  phone text,
  role text not null default 'client' check (role in ('admin','sede','sales','client')),
  created_at timestamptz not null default now()
);

-- CRM contacts (may or may not have an account)
create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  company text,
  city text,
  id_doc text,
  has_account boolean not null default false,
  disabled boolean not null default false,
  created_by text,
  total_spent numeric default 0,
  orders_count int default 0,
  registered date default now(),
  meta jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- Catalog (admin-editable, persistent)
-- ─────────────────────────────────────────────────────────────
create table public.fleet_units (
  id text primary key,               -- e.g. "u990", "u3287_1"
  plate text,
  name text not null,
  category text not null,
  year int,
  make text,
  model text,
  status text not null default 'available',
  daily numeric, weekly numeric, monthly numeric,
  deposit_daily numeric, deposit_weekly numeric, deposit_monthly numeric,
  mile_daily numeric default 0, mile_weekly numeric default 0, mile_monthly numeric default 0,
  mile_tiers jsonb default '[]'::jsonb,
  fuel_type text,
  specs jsonb default '{}'::jsonb,   -- eqCapacity, transmission, shortDesc, etc.
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table public.storage_spaces (
  id text primary key,
  name text not null,
  type text, size text, custom_size text, max_weight text, surface text,
  location text, access text, branch text,
  daily numeric, weekly numeric, monthly numeric, deposit numeric default 0,
  status text not null default 'available',
  inventory_enabled boolean not null default false,
  total_stock int default 0,
  active boolean not null default true,
  notes text,
  updated_at timestamptz not null default now()
);

create table public.space_rentals (
  id uuid primary key default gen_random_uuid(),
  space_id text not null references public.storage_spaces(id) on delete cascade,
  oid text, inv_num text,
  tenant text, tenant_email text, tenant_phone text,
  lease_start date, lease_end date,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- Operations
-- ─────────────────────────────────────────────────────────────
create table public.orders (
  oid text primary key,
  gid text,                          -- one cart/purchase = one group
  inv_num text,
  status text not null default 'Pending',
  pay_state text,
  phase text,
  customer_id uuid references public.contacts(id) on delete set null,
  customer_name text,                -- denormalized for history (was un)
  customer_email text,               -- (was ue)
  unit_id text,
  unit_label text,                   -- (was un2)
  plate text,
  unit_type text,
  start_date date, end_date date,
  days int, qty int default 1,
  total numeric, deposit numeric, reservation_paid numeric,
  mile_rate numeric default 0, miles numeric default 0,
  pay_method text,
  pay_detail jsonb,
  sales_rep text,                    -- profile email of the booking rep
  by_sales boolean default false,
  commission_paid boolean default false,
  settlement_status text, settlement_total numeric, settlement_paid boolean default false, settlement_notes text,
  approved_at timestamptz,
  expires_at timestamptz,
  ordered_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.deliveries (
  id text primary key,
  oid text references public.orders(oid) on delete cascade,
  inv_num text, client text, vehicle text, vid text, plate text,
  start_date date, end_date date,
  status text default 'pending',
  inspection jsonb default '{}'::jsonb,  -- miles/fuel/condition/notes in+out, damage, staff
  created_at timestamptz not null default now()
);

create table public.bookings (   -- availability blocks: rentals + maintenance
  id uuid primary key default gen_random_uuid(),
  vid text, vname text,
  start_date date, end_date date,
  type text default 'rental',      -- 'rental' | 'maintenance'
  client text,
  meta jsonb default '{}'::jsonb
);

create table public.carts (
  code text primary key,
  owner text, email text, phone text, user_role text,
  status text default 'active',
  items jsonb default '[]'::jsonb,
  order_refs jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────
-- Billing / documents
-- ─────────────────────────────────────────────────────────────
create table public.contracts (
  id text primary key,
  gid text, contract_num text, oid text,
  client text, email text,
  title text, body text, footer text,
  lessee_sig jsonb, lessor_sig jsonb,
  sent boolean default false, sent_at timestamptz,
  order_numbers jsonb default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table public.credit_lines (
  id text primary key,
  client_name text, email text,
  credit_limit numeric, terms int default 30,
  active boolean default true,
  granted_at timestamptz not null default now()
);

create table public.invoices (
  id text primary key,
  date date, due date,
  client text, email text, phone text,
  items jsonb default '[]'::jsonb,   -- product/deposit line items
  tax numeric default 0, discount numeric default 0,
  status text default 'draft', notes text, currency text default 'USD', source text,
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  from_name text, from_email text, subject text, body text,
  status text default 'new', section text,
  created_at timestamptz not null default now()
);

create table public.posts (
  id text primary key,
  title text, slug text, excerpt text, body text,
  author text, status text, category text,
  tags jsonb default '[]'::jsonb, featured boolean default false,
  published_on date, meta jsonb default '{}'::jsonb
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  type text, text text, section text,
  read boolean default false,
  created_at timestamptz not null default now()
);

-- Per-user attachments (files themselves live in Storage buckets)
create table public.signatures (
  email text primary key,
  name text, storage_path text, consent boolean default false,
  saved_at timestamptz not null default now()
);

create table public.saved_payment_methods (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  type text, label text, is_default boolean default false, status text default 'active',
  detail jsonb default '{}'::jsonb
);

create table public.client_documents (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text, storage_path text, kind text,
  uploaded_at timestamptz not null default now()
);

create table public.deposit_preferences (
  email text primary key,
  method text, detail jsonb default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.email_log (
  id uuid primary key default gen_random_uuid(),
  to_email text, subject text, template text, body text, meta jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Singleton settings (company info, commission/contract/deposit policy, email template)
create table public.settings (
  key text primary key,              -- 'company' | 'commission_policy' | 'contract_policy' | 'deposit_policy' | 'email_template' | 'contract_template'
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- updated_at triggers
create trigger t_contacts_touch before update on public.contacts for each row execute function public.touch_updated_at();
create trigger t_orders_touch   before update on public.orders   for each row execute function public.touch_updated_at();
create trigger t_carts_touch    before update on public.carts    for each row execute function public.touch_updated_at();

-- ─────────────────────────────────────────────────────────────
-- Row-Level Security (baseline; refined in Phase 2 — Auth)
-- Public catalog is world-readable; staff manage everything;
-- clients see only their own orders/invoices/docs.
-- ─────────────────────────────────────────────────────────────
alter table public.profiles              enable row level security;
alter table public.contacts              enable row level security;
alter table public.fleet_units           enable row level security;
alter table public.storage_spaces        enable row level security;
alter table public.space_rentals         enable row level security;
alter table public.orders                enable row level security;
alter table public.deliveries            enable row level security;
alter table public.bookings              enable row level security;
alter table public.carts                 enable row level security;
alter table public.contracts             enable row level security;
alter table public.credit_lines          enable row level security;
alter table public.invoices              enable row level security;
alter table public.messages              enable row level security;
alter table public.posts                 enable row level security;
alter table public.notifications         enable row level security;
alter table public.signatures            enable row level security;
alter table public.saved_payment_methods enable row level security;
alter table public.client_documents      enable row level security;
alter table public.deposit_preferences   enable row level security;
alter table public.email_log             enable row level security;
alter table public.settings              enable row level security;

-- Public read for the storefront catalog + published content
create policy read_fleet   on public.fleet_units     for select using (true);
create policy read_spaces  on public.storage_spaces  for select using (true);
create policy read_posts   on public.posts           for select using (status = 'published' or public.is_staff());
create policy read_company on public.settings        for select using (key in ('company') or public.is_staff());

-- Staff: full access to operational tables
create policy staff_all_contacts   on public.contacts        for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_orders     on public.orders          for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_deliveries on public.deliveries      for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_bookings   on public.bookings        for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_carts      on public.carts           for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_contracts  on public.contracts       for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_credit     on public.credit_lines    for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_invoices   on public.invoices        for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_messages   on public.messages        for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_notif      on public.notifications   for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_emaillog   on public.email_log       for all using (public.is_staff()) with check (public.is_staff());
create policy staff_all_spacerent  on public.space_rentals   for all using (public.is_staff()) with check (public.is_staff());

-- Catalog + posts + settings: only admin writes
create policy admin_write_fleet  on public.fleet_units    for all using (public.is_admin()) with check (public.is_admin());
create policy admin_write_spaces on public.storage_spaces for all using (public.is_admin()) with check (public.is_admin());
create policy admin_write_posts  on public.posts          for all using (public.is_admin()) with check (public.is_admin());
create policy admin_write_settings on public.settings     for all using (public.is_admin()) with check (public.is_admin());

-- Profiles: a user reads/updates their own; admin manages all
create policy own_profile   on public.profiles for select using (id = auth.uid() or public.is_admin());
create policy update_profile on public.profiles for update using (id = auth.uid() or public.is_admin());
create policy admin_profiles on public.profiles for all using (public.is_admin()) with check (public.is_admin());

-- Clients: read their own orders/invoices, manage their own docs/sigs/prefs/payments
create policy client_read_orders   on public.orders   for select using (customer_email = auth.jwt()->>'email' or public.is_staff());
create policy client_read_invoices on public.invoices for select using (email = auth.jwt()->>'email' or public.is_staff());
create policy own_signatures on public.signatures for all
  using (email = auth.jwt()->>'email' or public.is_staff())
  with check (email = auth.jwt()->>'email' or public.is_staff());
create policy own_documents on public.client_documents for all
  using (email = auth.jwt()->>'email' or public.is_staff())
  with check (email = auth.jwt()->>'email' or public.is_staff());
create policy own_payments on public.saved_payment_methods for all
  using (email = auth.jwt()->>'email' or public.is_staff())
  with check (email = auth.jwt()->>'email' or public.is_staff());
create policy own_deposit_pref on public.deposit_preferences for all
  using (email = auth.jwt()->>'email' or public.is_staff())
  with check (email = auth.jwt()->>'email' or public.is_staff());
