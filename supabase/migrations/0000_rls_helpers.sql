-- Helpers RLS compartidos para las migraciones de la Fase 1 en adelante
-- (ver plan de migración Firebase->Supabase). Espejo de las funciones de
-- autorización de firestore.rules (isAdmin, isOwnerOfGym, isStaffOfGym,
-- isMemberOfGym): mismo puñado de predicados reusados en las 43 reglas
-- del archivo original, ahora como funciones SQL reusadas en las
-- políticas RLS de cada tabla nueva.
--
-- IMPORTANTE: siempre auth.jwt() ->> '...' como TEXTO, nunca auth.uid()
-- (castea a ::uuid y rompe con IDs no-uuid como los UID de Firebase
-- durante la ventana de coexistencia, ver 0001_body_measurements.sql).
-- No se retroactivó 0001 a estos helpers para no tocar una migración
-- ya verificada/aplicada en el VPS; úsense desde 0002 en adelante.

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select (auth.jwt() ->> 'app_role') = 'admin';
$$;

create or replace function public.is_current_user(target_user_id text)
returns boolean
language sql
stable
as $$
  select (auth.jwt() ->> 'sub') = target_user_id;
$$;

create or replace function public.is_owner_of_gym(target_gym_id text)
returns boolean
language sql
stable
as $$
  select target_gym_id is not null
    and (auth.jwt() ->> 'gym_id') = target_gym_id
    and (auth.jwt() ->> 'app_role') = 'owner';
$$;

-- Owner o employee del gym (equivalente a isStaffOfGym en firestore.rules).
create or replace function public.is_staff_of_gym(target_gym_id text)
returns boolean
language sql
stable
as $$
  select target_gym_id is not null
    and (auth.jwt() ->> 'gym_id') = target_gym_id
    and (auth.jwt() ->> 'app_role') in ('owner', 'employee');
$$;

create or replace function public.is_member_of_gym(target_gym_id text)
returns boolean
language sql
stable
as $$
  select target_gym_id is not null
    and (auth.jwt() ->> 'gym_id') = target_gym_id
    and (auth.jwt() ->> 'app_role') = 'client';
$$;
