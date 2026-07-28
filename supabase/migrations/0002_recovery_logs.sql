-- Fase 1 del plan de migración Firebase->Supabase: recovery_logs.
-- Traducción de firestore.rules:810-832. Requiere 0000_rls_helpers.sql
-- aplicado antes que este archivo.
--
-- gym_id se mantiene nullable por paridad con la regla original
-- (resource.data.gymId), aunque hoy RecoveryLog (dominio) no lo puebla
-- todavía — mismo criterio que gym_id en body_measurements (0001).

create table if not exists public.recovery_logs (
  id                    text primary key,
  user_id               text not null,
  gym_id                text,
  date                  timestamptz not null default now(),
  sleep_hours           numeric not null default 0,
  sleep_quality         text not null default 'fair',
  hydration_liters      numeric not null default 0,
  stress_level          integer not null default 5,
  muscle_soreness       jsonb not null default '{}'::jsonb,
  energy_level          integer not null default 5,
  motivation_level      integer not null default 5,
  heart_rate_resting    numeric,
  notes                 text,
  created_at            timestamptz not null default now()
);

create index if not exists recovery_logs_user_date_idx
  on public.recovery_logs (user_id, date desc);

alter table public.recovery_logs enable row level security;

-- read: admin, dueño del registro, o staff del mismo gym (firestore.rules:811-821)
drop policy if exists "recovery_logs_select" on public.recovery_logs;
create policy "recovery_logs_select"
  on public.recovery_logs for select
  using (
    public.is_admin()
    or public.is_current_user(user_id)
    or (gym_id is not null and public.is_staff_of_gym(gym_id))
  );

-- create: admin o dueño (firestore.rules:822-825)
drop policy if exists "recovery_logs_insert" on public.recovery_logs;
create policy "recovery_logs_insert"
  on public.recovery_logs for insert
  with check (
    public.is_admin()
    or public.is_current_user(user_id)
  );

-- update/delete: admin o dueño (firestore.rules:826-831)
drop policy if exists "recovery_logs_update" on public.recovery_logs;
create policy "recovery_logs_update"
  on public.recovery_logs for update
  using (
    public.is_admin()
    or public.is_current_user(user_id)
  );

drop policy if exists "recovery_logs_delete" on public.recovery_logs;
create policy "recovery_logs_delete"
  on public.recovery_logs for delete
  using (
    public.is_admin()
    or public.is_current_user(user_id)
  );
