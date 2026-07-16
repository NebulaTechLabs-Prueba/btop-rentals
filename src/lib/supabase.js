import { createClient } from '@supabase/supabase-js';

// Frontend only ever sees the anon (public) key. The service-role key stays server-side.
const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

/** True once the Supabase env vars are present. Until then the app runs on localStorage. */
export const isSupabaseConfigured = Boolean(url && anonKey);

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
