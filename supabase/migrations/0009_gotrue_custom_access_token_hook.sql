-- Fase 4 del plan de migración Firebase->Supabase: Custom Access Token
-- Hook de GoTrue. Esta función la invoca GoTrue en cada emisión de
-- token (login, refresh) para inyectar los claims `app_role`/`gym_id`
-- que ya esperan TODAS las políticas RLS escritas desde 0001 en
-- adelante (auth.jwt() ->> 'app_role' / 'gym_id'). Sin este hook, un
-- usuario logueado con GoTrue tendría un JWT sin esos claims y ninguna
-- policy lo dejaría pasar de las que ya se migraron.
--
-- Requiere activarse en la config de GoTrue (env var
-- GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_URI apuntando a
-- 'pg-functions://postgres/public/custom_access_token_hook') y
-- reiniciar el contenedor supabase-auth — eso SÍ toca el VPS, pedir
-- confirmación explícita antes de aplicarlo ahí. Este archivo solo dej
-- a la función lista en el esquema; no se auto-activa.
--
-- CUENTAS ADMIN: no viven en gym_members (Fase 3, gym_id NOT NULL, CHECK
-- role in owner/employee/client — a propósito, ningún flujo de la app
-- crea un User de dominio con rol admin). Se agrega acá una tabla nueva
-- y mínima public.admins (paridad con el doc suelto users/{uid} sin
-- gymId que usa Firestore hoy para administradores, sin subcolección
-- por-gym). El hook consulta primero gym_members y, si no encuentra
-- nada, admins.

create table if not exists public.admins (
  id            text primary key,
  email         text not null unique,
  created_at    timestamptz not null default now()
);

alter table public.admins enable row level security;

drop policy if exists "admins_select" on public.admins;
create policy "admins_select"
  on public.admins for select
  using (public.is_admin() or public.is_current_user(id));

-- Solo un admin existente puede promover a otro (paridad con
-- isAdmin()-only en firestore.rules para el rol admin — ver comentario
-- de seguridad en firestore.rules:165-176, la misma lógica anti-
-- escalación aplica acá: nadie se auto-asigna admin).
drop policy if exists "admins_insert" on public.admins;
create policy "admins_insert"
  on public.admins for insert
  with check (public.is_admin());

drop policy if exists "admins_delete" on public.admins;
create policy "admins_delete"
  on public.admins for delete
  using (public.is_admin());

-- SECURITY DEFINER es imprescindible acá, no un detalle de estilo:
-- GoTrue invoca esta función como el rol supabase_auth_admin, que NO
-- tiene BYPASSRLS (verificado: rolbypassrls=false). Sin
-- SECURITY DEFINER, el "select ... from gym_members" de abajo queda
-- sujeto a las policies de gym_members_select (que a su vez dependen
-- de auth.jwt(), inexistente en este momento porque el token todavía
-- se está emitiendo) — la fila queda invisible, `found` da false
-- SIEMPRE, y el hook nunca agrega app_role/gym_id, sin ningún error
-- visible. Se detectó exactamente así en el smoke test end-to-end (28
-- jul 2026): login exitoso, JWT sin los claims. La función se crea
-- como el dueño `postgres`, que sí tiene BYPASSRLS en este stack
-- self-hosted (verificado) — set search_path fijo por buena práctica
-- de seguridad en funciones SECURITY DEFINER (evita search_path hijacking).
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  claims jsonb;
  member_row public.gym_members%rowtype;
  is_admin_user boolean;
  user_id text;
begin
  user_id := event->>'user_id';
  claims := event->'claims';

  select * into member_row from public.gym_members where id = user_id;

  if found then
    claims := jsonb_set(claims, '{app_role}', to_jsonb(member_row.role));
    claims := jsonb_set(claims, '{gym_id}', to_jsonb(member_row.gym_id));
  else
    select exists(select 1 from public.admins where id = user_id) into is_admin_user;
    if is_admin_user then
      claims := jsonb_set(claims, '{app_role}', to_jsonb('admin'::text));
    end if;
    -- Si no está en ninguna de las dos tablas, el token sale sin
    -- app_role/gym_id (equivalente a un usuario sin doc en Firestore
    -- hoy: is_admin()/is_staff_of_gym()/etc. simplemente dan false).
  end if;

  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$;

-- Permisos requeridos por GoTrue para poder invocar el hook (ver docs
-- de Supabase Auth Hooks): el rol supabase_auth_admin necesita EXECUTE
-- en la función y SELECT en las tablas que lee. Se revoca de roles
-- públicos a propósito: este hook no debe ser invocable por usuarios
-- comunes ni anon, solo por el propio GoTrue.
revoke execute on function public.custom_access_token_hook from public, anon, authenticated;
grant execute on function public.custom_access_token_hook to supabase_auth_admin;
grant select on public.gym_members, public.admins to supabase_auth_admin;
