-- Write-only setter for secure_settings. SECURITY DEFINER so it can upsert
-- without a SELECT policy (secrets stay unreadable), but enforces admin inside.
create or replace function public.set_secret(p_key text, p_value text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized' using errcode = '42501';
  end if;
  if p_key is null or p_key = '' then
    raise exception 'invalid key';
  end if;
  insert into public.secure_settings(key, value, updated_at)
    values (p_key, p_value, now())
    on conflict (key) do update set value = excluded.value, updated_at = now();
end $$;

revoke all on function public.set_secret(text, text) from public, anon;
grant execute on function public.set_secret(text, text) to authenticated;
