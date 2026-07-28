-- Fase 2 del plan de migración Firebase->Supabase: access_codes.
-- Traducción de firestore.rules:263-277 y 1097-1128 (ambos bloques
-- describen la MISMA autorización; Firestore necesitaba duplicar el
-- código en /access_codes y /gyms/{gymId}/access_codes solo para poder
-- consultar "códigos activos de este gym" sin un índice compuesto.
-- Postgres no tiene ese problema: una sola tabla + índice por gym_id
-- cubre ambos casos, sin doble escritura.

create table if not exists public.access_codes (
  value           text primary key,
  gym_id          text not null,
  type            text not null,
  generated_by    text not null,
  created_at      timestamptz not null default now(),
  expires_at      timestamptz not null,
  is_used         boolean not null default false,
  used_by         text,
  used_at         timestamptz
);

create index if not exists access_codes_gym_id_idx on public.access_codes (gym_id);

alter table public.access_codes enable row level security;

-- read: solo staff del gym o admin (firestore.rules:264/1099-1105)
drop policy if exists "access_codes_select" on public.access_codes;
create policy "access_codes_select"
  on public.access_codes for select
  using (
    public.is_admin()
    or public.is_staff_of_gym(gym_id)
  );

-- create: solo owner/admin, siempre dentro de su propio gym (firestore.rules:268/1108-1113)
drop policy if exists "access_codes_insert" on public.access_codes;
create policy "access_codes_insert"
  on public.access_codes for insert
  with check (
    public.is_admin()
    or public.is_owner_of_gym(gym_id)
  );

-- update: solo staff/admin puede actualizar (consumir/revocar) (firestore.rules:272/1120-1126)
-- Nota: la regla original también prohíbe cambiar gymId en el update;
-- eso requeriría un trigger (RLS no compara la fila vieja vs nueva),
-- fuera de alcance de esta traducción 1:1.
drop policy if exists "access_codes_update" on public.access_codes;
create policy "access_codes_update"
  on public.access_codes for update
  using (
    public.is_admin()
    or public.is_staff_of_gym(gym_id)
  );

-- delete: solo owner/admin (firestore.rules:276/1129-1132)
drop policy if exists "access_codes_delete" on public.access_codes;
create policy "access_codes_delete"
  on public.access_codes for delete
  using (
    public.is_admin()
    or public.is_owner_of_gym(gym_id)
  );
