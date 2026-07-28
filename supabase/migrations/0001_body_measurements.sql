-- Piloto Supabase: mediciones corporales (body_measurements)
-- Traducción de firestore.rules:762-785. Ver plan de arquitectura para contexto completo.
--
-- IMPORTANTE: user_id es el UID de Firebase (string, no UUID). No usar auth.uid()
-- (castea a ::uuid y falla). Las políticas comparan auth.jwt() ->> 'sub' como texto.
-- El puente JWT (lib/src/infrastructure/services/supabase_jwt_bridge.dart) firma
-- claims {sub, app_role, gym_id} equivalentes a los custom claims de Firebase.

create table if not exists public.body_measurements (
  id                    text primary key,
  user_id               text not null,
  gym_id                text,
  date                  timestamptz not null default now(),
  weight_kg             numeric,
  body_fat_percentage   numeric,
  height_cm             numeric,
  chest_cm              numeric,
  waist_cm              numeric,
  hips_cm                numeric,
  biceps_left_cm        numeric,
  biceps_right_cm       numeric,
  thigh_left_cm         numeric,
  thigh_right_cm        numeric,
  calf_left_cm          numeric,
  calf_right_cm         numeric,
  shoulders_cm          numeric,
  neck_cm                numeric,
  forearm_left_cm       numeric,
  forearm_right_cm      numeric,
  notes                 text,
  photo_url             text,
  created_at            timestamptz not null default now()
);

create index if not exists body_measurements_user_date_idx
  on public.body_measurements (user_id, date desc);

alter table public.body_measurements enable row level security;

-- read: admin, dueño del registro, o staff del mismo gym (firestore.rules:763-773)
drop policy if exists "body_measurements_select" on public.body_measurements;
create policy "body_measurements_select"
  on public.body_measurements for select
  using (
    (auth.jwt() ->> 'app_role') = 'admin'
    or (auth.jwt() ->> 'sub') = user_id
    or (
      gym_id is not null
      and (auth.jwt() ->> 'gym_id') = gym_id
      and (auth.jwt() ->> 'app_role') in ('owner', 'employee')
    )
  );

-- insert: admin o dueño (firestore.rules:774-777)
drop policy if exists "body_measurements_insert" on public.body_measurements;
create policy "body_measurements_insert"
  on public.body_measurements for insert
  with check (
    (auth.jwt() ->> 'app_role') = 'admin'
    or (auth.jwt() ->> 'sub') = user_id
  );

-- update/delete: admin o dueño (firestore.rules:778-784)
drop policy if exists "body_measurements_update" on public.body_measurements;
create policy "body_measurements_update"
  on public.body_measurements for update
  using (
    (auth.jwt() ->> 'app_role') = 'admin'
    or (auth.jwt() ->> 'sub') = user_id
  );

drop policy if exists "body_measurements_delete" on public.body_measurements;
create policy "body_measurements_delete"
  on public.body_measurements for delete
  using (
    (auth.jwt() ->> 'app_role') = 'admin'
    or (auth.jwt() ->> 'sub') = user_id
  );
