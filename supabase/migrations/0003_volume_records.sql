-- Fase 1 del plan de migración Firebase->Supabase: volume_records.
-- Traducción de firestore.rules:1233-1252. Requiere 0000_rls_helpers.sql
-- aplicado antes que este archivo.
--
-- A diferencia de recovery_logs, la regla original no tiene rama de
-- staff-del-gym (solo admin o dueño del registro) — no hace falta
-- columna gym_id acá.

create table if not exists public.volume_records (
  id            text primary key,
  user_id       text not null,
  week_start    timestamptz not null,
  volumes       jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);

create index if not exists volume_records_user_week_idx
  on public.volume_records (user_id, week_start desc);

alter table public.volume_records enable row level security;

-- read: admin o dueño del registro (firestore.rules:1234-1240)
drop policy if exists "volume_records_select" on public.volume_records;
create policy "volume_records_select"
  on public.volume_records for select
  using (
    public.is_admin()
    or public.is_current_user(user_id)
  );

-- create: admin o dueño (firestore.rules:1241-1244)
drop policy if exists "volume_records_insert" on public.volume_records;
create policy "volume_records_insert"
  on public.volume_records for insert
  with check (
    public.is_admin()
    or public.is_current_user(user_id)
  );

-- update/delete: admin o dueño (firestore.rules:1245-1251)
drop policy if exists "volume_records_update" on public.volume_records;
create policy "volume_records_update"
  on public.volume_records for update
  using (
    public.is_admin()
    or public.is_current_user(user_id)
  );

drop policy if exists "volume_records_delete" on public.volume_records;
create policy "volume_records_delete"
  on public.volume_records for delete
  using (
    public.is_admin()
    or public.is_current_user(user_id)
  );
