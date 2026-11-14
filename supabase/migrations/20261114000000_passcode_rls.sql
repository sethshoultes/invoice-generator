-- Passcode-gated row access (#2).
-- The anon key is public (it ships in the page), so RLS is the only guard. Every
-- request must carry an `x-app-passcode` header whose value matches the bcrypt hash
-- in private.app_passcode. `private` is not an API-exposed schema, so the hash
-- cannot be read over REST. With no hash row, or a wrong or missing header,
-- every table reads as empty and every write is refused.
--
-- Run once in the Supabase SQL editor. Then set the hash (never commit it; the
-- repo is public):
--   insert into private.app_passcode (hash) values ('<bcrypt hash>')
--   on conflict (id) do update set hash = excluded.hash;

create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public;

create table if not exists private.app_passcode (
  id boolean primary key default true check (id),  -- single row
  hash text not null
);
revoke all on private.app_passcode from public, anon, authenticated;

create or replace function private.passcode_ok() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from private.app_passcode p
    where p.hash = extensions.crypt(
      coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-app-passcode', ''),
      p.hash)
  );
$$;
revoke all on function private.passcode_ok() from public;
grant usage on schema private to anon, authenticated;
grant execute on function private.passcode_ok() to anon, authenticated;

-- Replace every existing policy on the app's tables (the "Allow all ..." ones) with
-- the passcode check. `(select ...)` makes Postgres evaluate it once per query, not per row.
do $$
declare
  t text;
  p record;
begin
  foreach t in array array['clients', 'invoices', 'line_items', 'recurring_items', 'settings', 'source_statements'] loop
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy "passcode required" on public.%I for all to anon, authenticated '
      'using ((select private.passcode_ok())) with check ((select private.passcode_ok()))', t);
  end loop;

  -- api_keys exists only in the local schema; if present, lock it with no policy at all.
  if to_regclass('public.api_keys') is not null then
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = 'api_keys' loop
      execute format('drop policy %I on public.api_keys', p.policyname);
    end loop;
    alter table public.api_keys enable row level security;
  end if;
end $$;
