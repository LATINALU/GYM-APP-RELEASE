// Supabase Edge Function: intercambia un ID token real de Firebase Auth por
// un JWT de Supabase/PostgREST, sin que ningún secreto de firma viva en el
// cliente Flutter (ver lib/src/infrastructure/services/supabase_jwt_bridge.dart).
//
// Reemplaza la primera versión del piloto (JWT firmado en el cliente con un
// secreto embebido — riesgo documentado: cualquiera que decompile la app
// podía forjar tokens de cualquier UID/rol/gym). Acá la firma de Firebase se
// valida contra las claves públicas reales de Google antes de emitir nada.
//
// Deploy (requiere Supabase CLI + acceso al VPS, no se ejecuta desde acá):
//   supabase functions deploy firebase-token-exchange
// Variables de entorno que necesita esta función (nunca en el cliente):
//   FIREBASE_PROJECT_ID  — el projectId de Firebase (gain-wave)
//   SUPABASE_JWT_SECRET  — el mismo JWT_SECRET del stack Supabase self-hosted
//
// NOTA: este intercambio confía en los custom claims `role`/`gymId` que ya
// vienen en el ID token de Firebase (los mismos que lee
// AuthStateNotifier._resolveProfile en el cliente). Si en el futuro esos
// claims dejan de setearse ahí, esta función necesita resolverlos desde
// Firestore en su lugar.

import { SignJWT, createRemoteJWKSet, jwtVerify } from "npm:jose@5";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
const SUPABASE_JWT_SECRET = Deno.env.get("SUPABASE_JWT_SECRET");
const ACCESS_TOKEN_TTL_SECONDS = 3600;

const googleJwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!FIREBASE_PROJECT_ID || !SUPABASE_JWT_SECRET) {
    return new Response("Server misconfigured", { status: 500 });
  }

  let idToken: string | undefined;
  try {
    const body = await req.json();
    idToken = typeof body?.idToken === "string" ? body.idToken : undefined;
  } catch {
    return new Response("Invalid JSON body", { status: 400 });
  }

  if (!idToken) {
    return new Response("Missing idToken", { status: 400 });
  }

  let payload;
  try {
    const verified = await jwtVerify(idToken, googleJwks, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
    });
    payload = verified.payload;
  } catch (err) {
    return new Response(`Invalid Firebase ID token: ${err}`, { status: 401 });
  }

  const uid = payload.sub;
  if (!uid) {
    return new Response("Token missing sub claim", { status: 401 });
  }

  const appRole = typeof payload["role"] === "string" ? payload["role"] : "client";
  const gymId = typeof payload["gymId"] === "string" ? payload["gymId"] : null;

  const accessToken = await new SignJWT({
    role: "authenticated",
    app_role: appRole,
    gym_id: gymId,
  })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(uid)
    .setIssuedAt()
    .setExpirationTime(`${ACCESS_TOKEN_TTL_SECONDS}s`)
    .sign(new TextEncoder().encode(SUPABASE_JWT_SECRET));

  return new Response(
    JSON.stringify({ access_token: accessToken, expires_in: ACCESS_TOKEN_TTL_SECONDS }),
    { headers: { "Content-Type": "application/json" } },
  );
});
