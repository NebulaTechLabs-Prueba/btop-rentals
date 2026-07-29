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

// ── Bucket PRIVADO para documentos de cliente (PII). No público: descarga vía signed URL. ──
const PRIVATE_BUCKET = 'client-docs';

/** Sube un archivo al bucket privado. Devuelve { path, name, size } (sin URL pública). */
export async function uploadPrivate(file, prefix = 'docs') {
  if (!supabase) throw new Error('Storage no disponible');
  if (!file) throw new Error('Sin archivo');
  const ext = (file.name.split('.').pop() || 'bin').toLowerCase().replace(/[^a-z0-9]/g, '');
  const path = `${prefix}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
  const { error } = await supabase.storage.from(PRIVATE_BUCKET).upload(path, file, { cacheControl: '3600', upsert: false });
  if (error) throw error;
  return { path, name: file.name, size: file.size };
}

/** Genera una signed URL temporal para ver/descargar un archivo privado (RLS: dueño o staff). */
export async function signedUrl(path, expiresIn = 300) {
  if (!supabase || !path) return null;
  try {
    const { data, error } = await supabase.storage.from(PRIVATE_BUCKET).createSignedUrl(path, expiresIn);
    if (error) return null;
    return data.signedUrl;
  } catch (e) { return null; }
}

/** Borra un archivo privado por su path (best-effort). */
export async function removePrivate(path) {
  if (!supabase || !path) return;
  try { await supabase.storage.from(PRIVATE_BUCKET).remove([path]); } catch (e) { /* best-effort */ }
}
