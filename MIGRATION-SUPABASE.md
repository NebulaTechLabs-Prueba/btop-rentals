# BTOP Rentals — Production migration plan (Supabase + Hetzner)

From a browser-only demo (localStorage) to a real multi-user app. Frontend stays static
on Hetzner/Nginx (see `DEPLOY-HETZNER.md`); the backend is **managed Supabase**.

## Confirmed decisions
- **Backend:** Supabase (managed) — Postgres + Auth + Storage + Edge Functions.
- **Email:** Resend (via an Edge Function).
- **Catalog:** admin edits fleet & storage spaces **persistently** (they become DB tables).
- **Code:** extract a **data layer** into `src/lib/` (done — Phase 0).
- **"Demo":** the word gets removed as each phase replaces the demo scaffolding
  (see the de-demo checklist at the bottom). Repo rename/migration is the owner's action.

## Guiding principle — a data layer, not a rewrite
`useRemoteState(table, initial)` keeps the exact `[value, setValue]` API of
`usePersistentState`, so modules migrate one at a time without touching component logic:

```js
const [orders, setOrders] = usePersistentState('btop_orders_v3', [])   // before
const [orders, setOrders] = useRemoteState('orders', [])               // after (Phase 1)
```

When `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` are **absent**, everything still runs on
localStorage — so nothing breaks until credentials exist.

## What's in place (Phase 0 — done)
- `src/lib/supabase.js` — Supabase client (or `null` when env is blank).
- `src/lib/persistence.js` — `usePersistentState` (moved out of the big file) + `useRemoteState` seam.
- `src/lib/db.js` — generic `table(name)` repository (list/insert/update/upsert/remove) + `subscribe()`.
- `supabase/migrations/0001_init.sql` — full schema + RLS (baseline).
- `@supabase/supabase-js` dependency; `.env.example` documents the vars.
- Reference migration: `carts` now uses `useRemoteState` (identical behavior today).

## Data model
See `supabase/migrations/0001_init.sql`. Tables: `profiles`, `contacts`, `fleet_units`,
`storage_spaces` + `space_rentals`, `orders`, `deliveries`, `bookings`, `carts`,
`contracts`, `credit_lines`, `invoices`, `messages`, `posts`, `notifications`,
`signatures`, `saved_payment_methods`, `client_documents`, `deposit_preferences`,
`email_log`, and a singleton `settings` (company / commission / contract / deposit / email
template). RLS: catalog is world-readable, staff manage operations, clients see only
their own records.

## Phases

### Phase 1 — Persistence
1. Create the Supabase project; `supabase link`; `supabase db push` (runs `0001_init.sql`).
2. Seed: load the real inventory (`FLEET_SEED`, storage yard) + base settings via a seed script.
3. Migrate module-by-module `usePersistentState` → `useRemoteState`, order:
   fleet/spaces → contacts → orders/deliveries/bookings → carts → contracts/invoices/credit → settings.
4. Admin fleet/space editors now write to `fleet_units` / `storage_spaces` (persistent catalog).

### Phase 2 — Auth
- Supabase Auth (email+password). `profiles.role` drives the existing role routing.
- **Magic-link invites already in the UI** → `signInWithOtp` / invite (native fit).
- Password reset (staff & clients) → `resetPasswordForEmail`.
- Remove hardcoded `USERS_INIT` and the login demo-credentials block.
- Finalize RLS against real sessions.

### Phase 3 — Payments (Stripe)
- Edge Functions `create-checkout-session` + `stripe-webhook` (frontend seam already exists).
- Secrets in Supabase; webhook updates `orders.status`. Flip `STRIPE_LIVE`.
- Replace the hard-coded "demo value" revenue KPI with real payment queries.

### Phase 4 — Email (Resend) + Files (Storage)
- Edge Function using **Resend** to send the signed contract PDF + invoices, triggered when
  the contract sending policy is met.
- Storage buckets `client-documents`, `signatures`, `contracts` (RLS-scoped); move
  signatures/docs/PDFs off data-URIs/localStorage.

## Configuring the backend (flip the switch)
```bash
# .env (local) or Nginx build env on the VPS
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```
Rebuild; `useRemoteState` starts using Supabase once the per-table repositories are wired (Phase 1).

## De-demo checklist (removing the word "demo")
- [ ] **Repo/URL** — rename `btop-admin-demo` → e.g. `btop-rentals`, or new repo (owner action).
      Base path is already `/` for the domain; no `/…-demo/` subpath in production.
- [ ] **Login screen** — remove the "Demo: …/…" credential hints + "Accesos demo" quick-fill (Phase 2, with real Auth).
- [ ] **Settings → "Demo Data" / "Reset demo data"** — remove or repurpose once data lives in Supabase (Phase 1).
- [ ] **KPIs** — replace "(demo value)" revenue text with live payment data (Phase 3).
- [ ] **Copy/comments** — sweep remaining "demo" strings (blog placeholder, upload toast) during the relevant phase.
