-- Passcode-gated row access (#2).
-- The anon key is public (it ships in the page), so RLS is the only guard. Every
-- request must carry an `x-app-passcode` header whose value matches the bcrypt hash
-- in private.app_passcode. `private` is not an API-exposed schema, so the hash
-- cannot be read over REST. With no hash row, or a wrong or missing header,
-- every table reads as empty and every write is refused.
--
-- Run this file, then the hash upsert, BACK TO BACK in the Supabase SQL editor:
-- between the two the live page shows empty lists. Never commit the hash (the
-- repo is public):
--   insert into private.app_passcode (hash) values ('<bcrypt hash of the trimmed passcode>')
--   on conflict (id) do update set hash = excluded.hash;
-- Locked out, or changing the passcode: re-run that upsert with the new hash.

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
      btrim(coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-app-passcode', '')),
      p.hash)
  );
$$;
revoke all on function private.passcode_ok() from public;
grant usage on schema private to anon, authenticated;
grant execute on function private.passcode_ok() to anon, authenticated;

-- Lets the page tell "passcode not accepted" from "no data". It answers nothing a
-- REST read of any table does not already answer, at the same one-bcrypt cost.
create or replace function public.app_passcode_ok() returns boolean
language sql stable set search_path = ''
as $$ select private.passcode_ok() $$;
revoke all on function public.app_passcode_ok() from public;
grant execute on function public.app_passcode_ok() to anon, authenticated;

-- Replace every existing policy on the app's tables (the "Allow all ..." ones)
-- with the passcode check. `(select ...)` makes Postgres evaluate it once per
-- query, not per row. RLS does not govern TRUNCATE, REFERENCES or TRIGGER, so
-- those grants go.
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
    execute format('alter table public.%I force row level security', t);
    execute format('revoke truncate, references, trigger on public.%I from anon, authenticated', t);
    execute format(
      'create policy "passcode required" on public.%I for all to anon, authenticated '
      'using ((select private.passcode_ok())) with check ((select private.passcode_ok()))', t);
  end loop;

  -- A view runs as its owner and so skips RLS: these two read every row with the
  -- anon key alone. Make them run as the caller, so the policies apply through them.
  foreach t in array array['invoice_summary', 'client_invoice_history'] loop
    if to_regclass('public.' || t) is not null then
      execute format('alter view public.%I set (security_invoker = true)', t);
    end if;
  end loop;

  -- api_keys exists only in the local schema; if present, lock it entirely.
  if to_regclass('public.api_keys') is not null then
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = 'api_keys' loop
      execute format('drop policy %I on public.api_keys', p.policyname);
    end loop;
    alter table public.api_keys enable row level security;
    revoke all on public.api_keys from anon, authenticated;
  end if;
end $$;

-- After running, expect no rows from either (RLS off, or an allow-all policy left):
--   select tablename from pg_tables where schemaname = 'public' and not rowsecurity;
--   select tablename, policyname from pg_policies where schemaname = 'public' and qual = 'true';
