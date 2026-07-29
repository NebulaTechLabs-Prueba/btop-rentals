import { supabase } from './supabase.js';

const BUCKET = 'fleet-media';

/**
 * Sube un archivo al bucket público `fleet-media` y devuelve { url, path, name }.
 * Lanza si falla (el caller muestra el error). `prefix` agrupa por unidad/tipo.
 */
export async function uploadMedia(file, prefix = 'misc') {
  if (!supabase) throw new Error('Storage no disponible');
  if (!file) throw new Error('Sin archivo');
  const ext = (file.name.split('.').pop() || 'bin').toLowerCase().replace(/[^a-z0-9]/g, '');
  const path = `${prefix}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
  const { error } = await supabase.storage.from(BUCKET).upload(path, file, { cacheControl: '3600', upsert: false });
  if (error) throw error;
  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  return { url: data.publicUrl, path, name: file.name };
}

/** Borra un archivo por su path (best-effort, no lanza). */
export async function removeMedia(path) {
  if (!supabase || !path) return;
  try { await supabase.storage.from(BUCKET).remove([path]); } catch (e) { /* best-effort */ }
}
