import { useState, useEffect } from 'react';
import { isSupabaseConfigured } from './supabase.js';

/**
 * localStorage-backed state — the original persistence primitive.
 * Kept as the fallback layer so the app always works, even before Supabase exists.
 */
export function usePersistentState(key, initial) {
  const [v, setV] = useState(() => {
    try {
      const s = window.localStorage.getItem(key);
      if (s != null) return JSON.parse(s);
    } catch (e) {}
    return typeof initial === 'function' ? initial() : initial;
  });
  useEffect(() => {
    try {
      window.localStorage.setItem(key, JSON.stringify(v));
    } catch (e) {}
  }, [key, v]);
  return [v, setV];
}

/**
 * Migration seam. Preserves the exact `[value, setValue]` API of usePersistentState
 * so a module can move to the backend without changing its call shape:
 *
 *   const [orders, setOrders] = usePersistentState('btop_orders_v3', [])
 *   const [orders, setOrders] = useRemoteState('orders', [])   // ← Phase 1
 *
 * - Supabase NOT configured → identical to usePersistentState (localStorage).
 * - Supabase configured      → (Phase 1) hydrate from `table` + write through via ./db.js.
 *
 * Today it always delegates to localStorage so behavior is unchanged until the
 * per-table repositories and Auth (Phase 2) are wired. `table` doubles as the storage key.
 */
export function useRemoteState(table, initial, opts = {}) {
  const localKey = opts.localKey || `btop_${table}`;
  // Phase 1 will branch here on isSupabaseConfigured and delegate to src/lib/db.js.
  // Referenced now only to keep the seam explicit in one place.
  void isSupabaseConfigured;
  return usePersistentState(localKey, initial);
}
