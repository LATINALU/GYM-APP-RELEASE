import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../../../core/auth/auth_state_notifier.dart';

/// Puente de identidad Firebase Auth -> Supabase/PostgREST para el piloto
/// del módulo Mediciones. Firma un JWT HS256 corto con los claims que las
/// políticas RLS de `body_measurements` esperan (sub/app_role/gym_id),
/// tomados del perfil ya resuelto por [AuthStateNotifier] desde los custom
/// claims de Firebase.
///
/// RIESGO ACEPTADO PARA ESTE PILOTO: el secreto de firma vive embebido en el
/// cliente Flutter, por lo que cualquiera que decompile la app podría forjar
/// tokens como cualquier UID/rol/gym. Es aceptable solo con datos de prueba y
/// un único tester detrás de este piloto interno. Antes de extender este
/// patrón a otras tablas o a usuarios reales, reemplazar por un intercambio
/// de token server-side (endpoint o Supabase Edge Function que valide el ID
/// token real de Firebase con el Firebase Admin SDK antes de emitir el JWT
/// puente).
class SupabaseJwtBridge {
  final String _signingSecret;
  final AuthStateNotifier _authStateNotifier;

  SupabaseJwtBridge({
    required String signingSecret,
    AuthStateNotifier? authStateNotifier,
  }) : _signingSecret = signingSecret,
       _authStateNotifier = authStateNotifier ?? AuthStateNotifier.instance;

  /// Devuelve un JWT firmado a partir del perfil actual, o null si no hay
  /// sesión (SupabaseClient.accessToken debe devolver null en ese caso para
  /// que las llamadas queden como rol `anon`).
  String? mintAccessToken() {
    final profile = _authStateNotifier.profile;
    final uid = profile?.uid;
    if (uid == null || uid.isEmpty) return null;

    final jwt = JWT({
      'sub': uid,
      'role': 'authenticated',
      'app_role': profile?.role?.type.name ?? 'client',
      'gym_id': profile?.gymId?.value,
    });

    return jwt.sign(
      SecretKey(_signingSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: const Duration(hours: 1),
    );
  }
}
