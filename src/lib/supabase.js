import { createClient } from '@supabase/supabase-js';

// Frontend only ever sees the anon (public) key. The service-role key stays server-side.
const rawUrl = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Enmascarado del backend (opcional): enruta TODAS las llamadas (rest/auth/storage/functions/realtime)
// por el dominio propio en `/api`, para que la pestaña de red no muestre el proveedor del backend.
// Se activa con VITE_SUPABASE_PROXY=true y REQUIERE que el reverse-proxy tenga la ruta `/api/* -> Supabase`
// (ver deploy/Caddyfile). Por defecto está APAGADO → llamadas directas (no rompe nada si el proxy no está listo).
const proxyOn = String(import.meta.env.VITE_SUPABASE_PROXY || '').toLowerCase() === 'true';
const url = proxyOn && typeof window !== 'undefined' ? `${window.location.origin}/api` : rawUrl;

/** True once the Supabase env vars are present. Until then the app runs on localStorage. */
export const isSupabaseConfigured = Boolean(rawUrl && anonKey);

/**
 * Supabase client, or `null` when the env vars are absent.
 * Keeping it null (instead of throwing) lets the current app keep working on
 * localStorage during the phased migration — nothing breaks before creds exist.
 */
export const supabase = isSupabaseConfigured
  ? createClient(url, anonKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    })
  : null;
