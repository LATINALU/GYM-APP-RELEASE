-- Fase 1 del plan de migración Firebase->Supabase: nutrition_plans.
-- Traducción de firestore.rules:753-774. Requiere 0000_rls_helpers.sql.
--
-- ADVERTENCIA (bug preexistente, NO se corrige acá, solo se traduce tal
-- cual): la regla original exige `resource.data.gymId is string` para
-- las ramas de staff/member, pero `NutritionPlan.toMap()` (dominio)
-- NUNCA escribe gymId — no hay ningún call-site que lo setee. En la
-- práctica, hoy en Firestore, un usuario no-admin no puede satisfacer
-- ninguna rama que dependa de gymId. Se traduce con la misma columna
-- nullable y el mismo comportamiento (si gym_id es null, las políticas
-- de staff/member no aplican) en vez de "arreglarlo" durante la
-- migración de datos — es una decisión de producto aparte, no algo
-- para decidir en silencio acá.

create table if not exists public.nutrition_plans (
  id                  text primary key,
  user_id             text not null,
  gym_id              text,
  name                text not null,
  description         text,
  target_calories     numeric not null default 0,
  target_protein_g    numeric not null default 0,
  target_carbs_g      numeric not null default 0,
  target_fat_g        numeric not null default 0,
  meals               jsonb not null default '[]'::jsonb,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now()
);

create index if not exists nutrition_plans_user_idx
  on public.nutrition_plans (user_id, created_at desc);

alter table public.nutrition_plans enable row level security;

-- read: admin, o (con gym_id seteado) staff o member del gym (firestore.rules:754-760)
drop policy if exists "nutrition_plans_select" on public.nutrition_plans;
create policy "nutrition_plans_select"
  on public.nutrition_plans for select
  using (
    public.is_admin()
    or (gym_id is not null and (public.is_staff_of_gym(gym_id) or public.is_member_of_gym(gym_id)))
  );

-- create/update: admin, o (con gym_id seteado) staff del gym (firestore.rules:761-767)
drop policy if exists "nutrition_plans_insert" on public.nutrition_plans;
create policy "nutrition_plans_insert"
  on public.nutrition_plans for insert
  with check (
    public.is_admin()
    or (gym_id is not null and public.is_staff_of_gym(gym_id))
  );

drop policy if exists "nutrition_plans_update" on public.nutrition_plans;
create policy "nutrition_plans_update"
  on public.nutrition_plans for update
  using (
    public.is_admin()
    or (gym_id is not null and public.is_staff_of_gym(gym_id))
  );

-- delete: admin, o (con gym_id seteado) dueño del gym (firestore.rules:768-774)
drop policy if exists "nutrition_plans_delete" on public.nutrition_plans;
create policy "nutrition_plans_delete"
  on public.nutrition_plans for delete
  using (
    public.is_admin()
    or (gym_id is not null and public.is_owner_of_gym(gym_id))
  );
