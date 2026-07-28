-- Fase 3 del plan de migración Firebase->Supabase: identidad
-- (public.gyms + public.gym_members). Traducción de firestore.rules
-- para /gyms/{gymId} (líneas ~198-209), /users/{userId} (líneas
-- 160-190) y las subcolecciones /gyms/{gymId}/{owners|employees|clients}
-- (líneas ~214-242).
--
-- DISEÑO: una sola tabla gym_members reemplaza TRES copias por usuario
-- que mantenía Firestore (gyms/{gymId}/owners|employees|clients/{uid} +
-- users/{uid} raíz + un tercer 'user/{uid}' legacy que resultó ser
-- código muerto sin lectores, no migrado). El campo `role` distingue
-- owner/employee/client — el propio `User` (dominio) ya es una sola
-- clase para los tres roles, así que esto no es una simplificación
-- forzada, es el modelo que el dominio ya usaba.
--
-- Cuentas admin NO viven en esta tabla (gym_id es NOT NULL acá): no hay
-- ningún flujo en el código que cree un `User` (dominio) con rol admin
-- — AuthStateNotifier resuelve admin leyendo un doc suelto sin pasar
-- por UserRepositoryPort. Eso se resuelve en la Fase 4 (reescritura de
-- AuthStateNotifier), no acá.
--
-- HALLAZGO para tener en cuenta en la Fase 4: las reglas de Firestore
-- para creación combinaban la regla raíz (users/{uid}: admin, o el
-- propio usuario con rol 'client' únicamente) con la regla anidada por
-- rol (ej. clients: staff-del-gym o admin). Combinadas con AND (la app
-- escribe ambos documentos en el mismo batch), un miembro de staff
-- NUNCA podría crear el doc de un cliente nuevo vía este mismo path,
-- porque la regla raíz exige que el creador sea uid()==userId o admin.
-- Verificado en firebase_auth_repository.dart: el alta real de un
-- cliente nuevo pasa por autoregistro (root doc, self+client) y la
-- aprobación/asignación a un gym es un paso aparte — nunca ambos
-- documentos se crean en la misma operación por un actor distinto al
-- propio usuario. Achica la posibilidad de encontrarse con este AND
-- restrictivo en la práctica. Acá se traduce la INTENCIÓN de las
-- reglas anidadas (staff puede gestionar employees/clients de su gym)
-- en vez de la composición literal, que haría inservible la gestión de
-- staff sobre su propio gym.

create table if not exists public.gyms (
  id                      text primary key,
  code                    text not null unique,
  name                    text not null,
  address                 text,
  phone                   text,
  logo_url                text,
  is_active               boolean not null default true,
  -- Poblados hoy directo por AdminGymsLiveScreen (raw Firestore update,
  -- no pasan por el dominio Gym/GymMapper) — ver commit d7c0640.
  platform_plan_id        text,
  platform_plan_status    text,
  created_at              timestamptz not null default now()
);

alter table public.gyms enable row level security;

drop policy if exists "gyms_select" on public.gyms;
create policy "gyms_select"
  on public.gyms for select
  using (
    public.is_admin()
    or public.is_staff_of_gym(id)
    or public.is_member_of_gym(id)
  );

drop policy if exists "gyms_insert" on public.gyms;
create policy "gyms_insert"
  on public.gyms for insert
  with check (public.is_admin());

drop policy if exists "gyms_update" on public.gyms;
create policy "gyms_update"
  on public.gyms for update
  using (
    public.is_admin()
    or public.is_owner_of_gym(id)
  );

drop policy if exists "gyms_delete" on public.gyms;
create policy "gyms_delete"
  on public.gyms for delete
  using (public.is_admin());


create table if not exists public.gym_members (
  id                          text primary key,
  gym_id                      text not null references public.gyms(id),
  email                       text not null,
  first_name                  text not null,
  last_name                   text not null default '',
  role                        text not null check (role in ('owner', 'employee', 'client')),
  phone                       text,
  is_active                   boolean not null default true,
  membership_status           text not null default 'approved',
  membership_expires_at       timestamptz,
  member_number               text,
  member_number_assigned_at   timestamptz,
  weight                      numeric,
  height                      numeric,
  fitness_goal                text,
  last_login_at               timestamptz,
  created_at                  timestamptz not null default now()
);

-- Un email = una cuenta en toda la plataforma (mismo supuesto que el
-- lookup global users/{uid} de Firestore).
create unique index if not exists gym_members_email_idx on public.gym_members (lower(email));
create index if not exists gym_members_gym_role_idx on public.gym_members (gym_id, role, is_active);

alter table public.gym_members enable row level security;

-- read: uno mismo, admin, o (si es employee/client) staff del gym.
-- Los owners NO son legibles por isStaffOfGym en la regla original
-- (owners: isOwnerOfGym o admin, sin rama de staff) — un empleado no
-- puede leer el registro del dueño de su propio gym.
drop policy if exists "gym_members_select" on public.gym_members;
create policy "gym_members_select"
  on public.gym_members for select
  using (
    public.is_current_user(id)
    or public.is_admin()
    or (role in ('employee', 'client') and public.is_staff_of_gym(gym_id))
  );

-- create: admin siempre; alta de employee requiere ser dueño del gym;
-- alta de client admite cualquier staff (owner o employee) del gym.
-- Las filas de rol 'owner' solo las crea admin (alta/onboarding de un
-- gym nuevo).
drop policy if exists "gym_members_insert" on public.gym_members;
create policy "gym_members_insert"
  on public.gym_members for insert
  with check (
    public.is_admin()
    or (role = 'employee' and public.is_owner_of_gym(gym_id))
    or (role = 'client' and public.is_staff_of_gym(gym_id))
  );

-- update: uno mismo (ver trigger más abajo que bloquea auto-cambiar
-- role/gym_id), admin, dueño del gym sobre sus employees, o staff
-- sobre los clients de su gym.
drop policy if exists "gym_members_update" on public.gym_members;
create policy "gym_members_update"
  on public.gym_members for update
  using (
    public.is_current_user(id)
    or public.is_admin()
    or (role = 'employee' and public.is_owner_of_gym(gym_id))
    or (role = 'client' and public.is_staff_of_gym(gym_id))
  );

-- delete: solo admin (firestore.rules /users/{uid}: "Only admins can
-- delete users" — regla explícita y sin ambigüedad, a diferencia del
-- create/update donde sí hubo que interpretar la intención).
drop policy if exists "gym_members_delete" on public.gym_members;
create policy "gym_members_delete"
  on public.gym_members for delete
  using (public.is_admin());

-- Blindaje anti-escalación de privilegios: un usuario puede actualizar
-- sus propios campos no sensibles, pero NUNCA su propio role o gym_id
-- (RLS no puede comparar fila vieja vs nueva en una sola condición, por
-- eso esto vive en un trigger, no en la policy). Traduce literalmente
-- el comentario de seguridad en firestore.rules:165-176.
create or replace function public.gym_members_prevent_self_privilege_escalation()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if public.is_current_user(old.id) then
    if new.role is distinct from old.role or new.gym_id is distinct from old.gym_id then
      raise exception 'No podés cambiar tu propio rol o gimnasio';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists gym_members_prevent_self_privilege_escalation on public.gym_members;
create trigger gym_members_prevent_self_privilege_escalation
  before update on public.gym_members
  for each row
  execute function public.gym_members_prevent_self_privilege_escalation();
