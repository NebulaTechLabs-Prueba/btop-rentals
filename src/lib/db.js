import { supabase } from './supabase.js';

/**
 * Generic table repository — the single surface the app will use to reach the backend.
 * Every method returns `null` (a no-op) when Supabase is not configured, so callers can
 * safely fall back to their local state during the phased migration.
 *
 *   import { table } from './lib/db.js'
 *   const orders = table('orders')
 *   await orders.list({ status: 'Pending' })
 *   await orders.insert(row)
 *   await orders.update(oid, patch, 'oid')
 */
export function table(name) {
  return {
    async list(match) {
      if (!supabase) return null;
      let q = supabase.from(name).select('*');
      if (match) q = q.match(match);
      const { data, error } = await q;
      if (error) throw error;
      return data;
    },
    async insert(rows) {
      if (!supabase) return null;
      const { data, error } = await supabase.from(name).insert(rows).select();
      if (error) throw error;
      return data;
    },
    async update(id, patch, pk = 'id') {
      if (!supabase) return null;
      const { data, error } = await supabase.from(name).update(patch).eq(pk, id).select();
      if (error) throw error;
      return data;
    },
    async upsert(rows, onConflict) {
      if (!supabase) return null;
      const { data, error } = await supabase
        .from(name)
        .upsert(rows, onConflict ? { onConflict } : undefined)
        .select();
      if (error) throw error;
      return data;
    },
    async remove(id, pk = 'id') {
      if (!supabase) return null;
      const { error } = await supabase.from(name).delete().eq(pk, id);
      if (error) throw error;
      return true;
    },
  };
}

/** Subscribe to realtime changes on a table (Phase 1+). Returns an unsubscribe fn. */
export function subscribe(name, onChange) {
  if (!supabase) return () => {};
  const channel = supabase
    .channel(`public:${name}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: name }, onChange)
    .subscribe();
  return () => supabase.removeChannel(channel);
}
