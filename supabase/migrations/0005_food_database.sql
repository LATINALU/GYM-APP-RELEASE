-- Fase 1 del plan de migración Firebase->Supabase: food_database
-- (alimentos personalizados que el admin agrega por encima del catálogo
-- local FoodCatalog, lib/src/domain/data/food_catalog.dart — ese catálogo
-- NO migra, sigue siendo un asset local). Traducción de
-- firestore.rules:1224-1227: cualquier usuario autenticado puede leer,
-- solo admin puede escribir. No usa los helpers de gym (no es data
-- gym-scoped), por eso no depende de 0000_rls_helpers.sql para nada más
-- que is_admin().

create table if not exists public.food_database (
  id              text primary key,
  name            text not null,
  serving_size    numeric not null default 100,
  serving_unit    text not null default 'g',
  calories        numeric not null default 0,
  protein_g       numeric not null default 0,
  carbs_g         numeric not null default 0,
  fat_g           numeric not null default 0,
  fiber_g         numeric,
  sugar_g         numeric,
  sodium_mg       numeric,
  created_at      timestamptz not null default now()
);

create index if not exists food_database_name_idx on public.food_database (name);

alter table public.food_database enable row level security;

-- read: cualquier usuario autenticado (firestore.rules:1225)
drop policy if exists "food_database_select" on public.food_database;
create policy "food_database_select"
  on public.food_database for select
  using ((auth.jwt() ->> 'sub') is not null);

-- write: solo admin (firestore.rules:1226)
drop policy if exists "food_database_insert" on public.food_database;
create policy "food_database_insert"
  on public.food_database for insert
  with check (public.is_admin());

drop policy if exists "food_database_update" on public.food_database;
create policy "food_database_update"
  on public.food_database for update
  using (public.is_admin());

drop policy if exists "food_database_delete" on public.food_database;
create policy "food_database_delete"
  on public.food_database for delete
  using (public.is_admin());
