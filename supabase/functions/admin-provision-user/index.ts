// Supabase Edge Function: da de alta un usuario nuevo (owner/employee/
// client) EN NOMBRE de un admin, sin pisar la sesión de ese admin en el
// cliente. Equivalente Supabase de `provisionUser` en
// firebase_auth_repository.dart (que usaba una app Firebase secundaria
// para lo mismo).
//
// Por qué existe esta función en vez de resolverlo en el cliente
// Flutter: crear un usuario "por otro" sin loguearse como él requiere
// la Admin API de GoTrue (`auth.admin.createUser`), que exige el
// `service_role` key — ese secreto NUNCA debe vivir en el cliente
// (bypassea RLS por completo). Acá vive solo en el entorno de esta
// función, igual que SUPABASE_JWT_SECRET en firebase-token-exchange.
//
// Deploy (requiere Supabase CLI + acceso al VPS, no se ejecuta desde
// acá): supabase functions deploy admin-provision-user
// Variables de entorno que necesita (nunca en el cliente):
//   SUPABASE_URL          — URL interna del stack (Kong)
//   SUPABASE_SERVICE_ROLE_KEY — service_role key del stack

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response("Server misconfigured", { status: 500 });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const callerToken = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!callerToken) {
    return new Response("Missing Authorization header", { status: 401 });
  }

  let body: {
    email?: string;
    password?: string;
    fullName?: string;
    role?: string;
    gymId?: string;
    phone?: string;
  };
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON body", { status: 400 });
  }

  const { email, password, fullName, role, gymId, phone } = body;
  if (!email || !password || !fullName || !role || !gymId) {
    return new Response(
      "Missing required fields: email, password, fullName, role, gymId",
      { status: 400 },
    );
  }
  if (!["owner", "employee", "client"].includes(role)) {
    return new Response(
      "role must be one of: owner, employee, client (admin provisioning not supported here)",
      { status: 400 },
    );
  }

  const serviceClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // 1. Verificar que quien llama es realmente un admin. Se valida el JWT
  //    del caller contra GoTrue (getUser hace la verificación real de
  //    firma/expiración) y se chequea la tabla admins con el
  //    service_role client (bypassea RLS a propósito, es una lectura
  //    de control de acceso, no un bypass de negocio).
  const { data: callerData, error: callerError } = await serviceClient.auth
    .getUser(callerToken);
  if (callerError || !callerData.user) {
    return new Response("Invalid caller token", { status: 401 });
  }

  const { data: adminRow } = await serviceClient
    .from("admins")
    .select("id")
    .eq("id", callerData.user.id)
    .maybeSingle();
  if (!adminRow) {
    return new Response("Caller is not an admin", { status: 403 });
  }

  // 2. Verificar que el gym destino existe (paridad con la validación
  //    de firestore.rules en pending_registrations: "el gym existe").
  const { data: gymRow } = await serviceClient
    .from("gyms")
    .select("id")
    .eq("id", gymId)
    .eq("is_active", true)
    .maybeSingle();
  if (!gymRow) {
    return new Response("Target gym not found", { status: 404 });
  }

  // 3. Crear el usuario en GoTrue sin afectar la sesión del admin que
  //    llama (Admin API, requiere service_role).
  const { data: created, error: createError } = await serviceClient.auth.admin
    .createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    });
  if (createError || !created.user) {
    return new Response(
      `Failed to create user: ${createError?.message ?? "unknown error"}`,
      { status: 500 },
    );
  }

  // 4. Insertar la fila en gym_members con el mismo shape que
  //    UserMapper.toSupabase (ver lib/src/infrastructure/mappers/user_mapper.dart).
  const [firstName, ...rest] = fullName.trim().split(/\s+/);
  const { error: insertError } = await serviceClient.from("gym_members")
    .insert({
      id: created.user.id,
      gym_id: gymId,
      email,
      first_name: firstName,
      last_name: rest.join(" "),
      role,
      phone: phone ?? null,
      is_active: true,
      membership_status: role === "client" ? "pending" : "approved",
    });

  if (insertError) {
    // Rollback: no dejar un usuario de Auth huérfano sin fila en gym_members.
    await serviceClient.auth.admin.deleteUser(created.user.id);
    return new Response(
      `Failed to persist gym_members row: ${insertError.message}`,
      { status: 500 },
    );
  }

  return new Response(
    JSON.stringify({ id: created.user.id, email, role, gym_id: gymId }),
    { status: 201, headers: { "Content-Type": "application/json" } },
  );
});
