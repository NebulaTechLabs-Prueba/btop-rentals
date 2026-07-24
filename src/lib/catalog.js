import { supabase } from './supabase.js';

// Carga los perfiles (staff/usuarios) desde Supabase. Público-legible (nombres).
export async function loadProfiles() {
  if (!supabase) return null;
  try {
    const { data, error } = await supabase.from('profiles').select('email,name,role');
    if (error || !Array.isArray(data) || data.length === 0) return null;
    return data;
  } catch {
    return null;
  }
}

// Carga la flota desde Supabase (lectura pública). Devuelve las filas crudas
// (snake_case) o null si no hay Supabase / error / vacío → el caller mantiene el seed.
export async function loadFleetUnits() {
  if (!supabase) return null;
  try {
    const { data, error } = await supabase
      .from('fleet_units')
      .select('*')
      .eq('active', true);
    if (error || !data || data.length === 0) return null;
    return data;
  } catch {
    return null;
  }
}

// ── Escritura persistente (admin edita flota/espacios → Supabase) ──
const num = (v, d = 0) => { const x = Number(v); return Number.isNaN(x) ? d : x; };

// App fleet object → fila normalizada de fleet_units
export function fleetToRow(v) {
  return {
    id: v.id, plate: v.plate || v.id, name: v.name || '', category: v.category || v.cat || '',
    year: v.year ? num(v.year, null) : null, make: v.make || null, model: v.model || null,
    status: v.status || 'available',
    daily: num(v.daily), weekly: num(v.weekly), monthly: num(v.monthly),
    deposit_daily: num(v.depD ?? v.depositDaily, 200), deposit_weekly: num(v.depW ?? v.depositWeekly, 300), deposit_monthly: num(v.depM ?? v.depositMonthly, 500),
    mile_daily: num(v.rateMile ?? v.mileDaily), mile_weekly: num(v.mileWeekly), mile_monthly: num(v.mileMonthly),
    mile_tiers: v.mileTiers || [], fuel_type: v.fuelType || null,
    specs: { transmission: v.transmission || '', eqCapacity: v.eqCapacity || '', shortDesc: v.shortDesc || v.desc || '' },
    active: v.active !== false,
  };
}
// App space object → fila de storage_spaces (solo campos propios; las rentas viven en space_rentals)
export function spaceToRow(s) {
  return {
    id: s.id, name: s.name || '', type: s.type || '', size: s.size || null, custom_size: s.customSize || null,
    max_weight: s.maxWeight || null, surface: s.surface || null, location: s.location || null, access: s.access || null, branch: s.branch || null,
    daily: num(s.daily), weekly: num(s.weekly), monthly: num(s.monthly), deposit: num(s.deposit),
    status: s.status || 'available', inventory_enabled: !!s.inventoryEnabled, total_stock: num(s.totalStock), notes: s.internalNotes || '', active: s.active !== false,
  };
}
// Diff genérico prev→next: upsert de lo cambiado, delete de lo removido. Best-effort, no bloquea la UI.
function syncTable(table, toRow, prev, next) {
  if (!supabase) return;
  try {
    const prevById = new Map(prev.map((r) => [r.id, r]));
    const changed = next.filter((r) => { const p = prevById.get(r.id); return !p || JSON.stringify(p) !== JSON.stringify(r); });
    if (changed.length) supabase.from(table).upsert(changed.map(toRow), { onConflict: 'id' }).then(({ error }) => { if (error) console.warn(`[${table} sync]`, error.message); });
    const nextIds = new Set(next.map((r) => r.id));
    const removed = prev.filter((r) => !nextIds.has(r.id));
    if (removed.length) supabase.from(table).delete().in('id', removed.map((r) => r.id)).then(({ error }) => { if (error) console.warn(`[${table} del]`, error.message); });
  } catch (e) { console.warn(`[${table} sync]`, e?.message); }
}
export function syncFleetUnits(prev, next) { syncTable('fleet_units', fleetToRow, prev, next); }
export function syncSpaces(prev, next) { syncTable('storage_spaces', spaceToRow, prev, next); }

// Carga los espacios de almacenamiento + sus rentas activas desde Supabase.
// Devuelve el arreglo ya con la forma que usa la app, o null (→ el caller mantiene el seed).
export async function loadSpaces() {
  if (!supabase) return null;
  try {
    const [sres, rres] = await Promise.all([
      supabase.from('storage_spaces').select('*').eq('active', true),
      supabase.from('space_rentals').select('*'),
    ]);
    const sp = sres.data;
    if (sres.error || !sp || sp.length === 0) return null;
    const rentals = rres.data || [];
    const n = (v, d) => (v == null ? (d ?? 0) : Number(v));
    return sp.map((s) => ({
      id: s.id, name: s.name, type: s.type, size: s.size, customSize: s.custom_size,
      maxWeight: s.max_weight, surface: s.surface, location: s.location, access: s.access, branch: s.branch,
      daily: n(s.daily), weekly: n(s.weekly), monthly: n(s.monthly), deposit: n(s.deposit),
      status: s.status || 'available', tenant: '', since: '',
      inventoryEnabled: !!s.inventory_enabled, totalStock: n(s.total_stock), active: s.active !== false,
      internalNotes: s.notes || '', docs: [],
      activeRentals: rentals
        .filter((r) => r.space_id === s.id)
        .map((r) => ({
          oid: r.oid, invNum: r.inv_num, tenant: r.tenant, tenantEmail: r.tenant_email,
          tenantPhone: r.tenant_phone, leaseStart: r.lease_start, leaseEnd: r.lease_end,
        })),
    }));
  } catch {
    return null;
  }
}
