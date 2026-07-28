-- Fase 2 del plan de migración Firebase->Supabase: pending_registrations.
-- Traducción de firestore.rules:245-260 (subcolección por-gym) y
-- 1066-1090 (colección global) — igual que en 0006_access_codes.sql,
-- Firestore necesitaba duplicar el documento en ambos lugares; acá una
-- sola tabla con columna target_gym_id + índice alcanza.
--
-- Las dos reglas de Firestore no son idénticas: la subcolección por-gym
-- permite `allow delete: if isStaffOfGym(gymId) || isAdmin()`, pero la
-- regla global (más estricta) exige `allow delete: if isAdmin()`. Como
-- el codigo de la app siempre escribe/borra AMBAS copias en la misma
-- operación, en la práctica el borrado ya requería admin de todos
-- modos (la copia global bloqueaba a cualquier no-admin aunque la copia
-- del gym lo permitiera). Se traduce con esa semántica real (admin-only
-- delete), no con la más permisiva de la subcolección.
--
-- No se agrega FK a gyms(id) todavía: la tabla public.gyms no existe
-- hasta la Fase 3 de este plan. Agregarla ahí cuando corresponda.
--
-- userNameLower (columna denormalizada en Firestore para simular
-- prefix-search) no se migra: Postgres hace case-insensitive prefix
-- match con ilike directo sobre user_name, sin necesitar la columna
-- espejo.

create table if not exists public.pending_registrations (
  id                  text primary key,
  user_id             text not null,
  user_email          text not null,
  user_name           text not null,
  user_phone          text,
  user_photo_url      text,
  target_gym_id       text,
  target_gym_name     text,
  target_gym_code     text,
  access_code_used    text,
  status              text not null default 'pendingReview',
  source              text not null default 'manualCode',
  message             text,
  fitness_goal        text,
  weight              numeric,
  height              numeric,
  reviewed_by         text,
  reviewed_at         timestamptz,
  rejection_reason    text,
  created_at          timestamptz not null default now(),
  expires_at          timestamptz,
  metadata            jsonb
);

create index if not exists pending_registrations_target_gym_idx
  on public.pending_registrations (target_gym_id, status, created_at desc);
create index if not exists pending_registrations_user_idx
  on public.pending_registrations (user_id, created_at desc);

alter table public.pending_registrations enable row level security;

-- read: dueño del registro, admin, o staff del gym destino (firestore.rules:1067-1074)
drop policy if exists "pending_registrations_select" on public.pending_registrations;
create policy "pending_registrations_select"
  on public.pending_registrations for select
  using (
    public.is_current_user(user_id)
    or public.is_admin()
    or (target_gym_id is not null and public.is_staff_of_gym(target_gym_id))
  );

-- create: solo el propio usuario, para sí mismo (firestore.rules:1075-1081;
-- la validación "el gym destino existe" queda para cuando exista public.gyms)
drop policy if exists "pending_registrations_insert" on public.pending_registrations;
create policy "pending_registrations_insert"
  on public.pending_registrations for insert
  with check (
    public.is_current_user(user_id)
  );

-- update: dueño del registro, admin, o staff del gym destino (firestore.rules:1082-1090)
drop policy if exists "pending_registrations_update" on public.pending_registrations;
create policy "pending_registrations_update"
  on public.pending_registrations for update
  using (
    public.is_current_user(user_id)
    or public.is_admin()
    or (target_gym_id is not null and public.is_staff_of_gym(target_gym_id))
  );

-- delete: solo admin (firestore.rules:1091, ver nota arriba sobre por qué
-- no se usa la variante más permisiva de la subcolección por-gym)
drop policy if exists "pending_registrations_delete" on public.pending_registrations;
create policy "pending_registrations_delete"
  on public.pending_registrations for delete
  using (
    public.is_admin()
  );
