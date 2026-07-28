import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart' hide User;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/auth_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Fase 4 de la migración Firebase->Supabase: implementa [AuthRepositoryPort]
/// contra `SupabaseClient.auth` (GoTrue) + `public.gym_members` (Fase 3).
///
/// A diferencia de los adaptadores anteriores, este NO tiene un flag
/// USE_SUPABASE_* propio: activarlo es el corte de Auth en sí (Fase 4),
/// que se hace una sola vez y no convive con Firebase Auth en paralelo
/// (ver plan, Fase 4 punto 8 — "una sesión es Firebase o es Supabase,
/// no ambas").
///
/// LIMITACIONES CONOCIDAS, documentadas en vez de resueltas en silencio:
///
/// - `signInWithGoogle`: GoTrue soporta OAuth, pero es un flujo por
///   redirect/deep-link (no un popup síncrono como Firebase Web) — el
///   resultado real llega más tarde vía `authStateChanges`, no como
///   valor de retorno de esta llamada. Además el stack self-hosted NO
///   tiene configurado todavía `GOTRUE_EXTERNAL_GOOGLE_*` (client
///   id/secret, redirect URL) — prerequisito de infra pendiente, fuera
///   de alcance de este commit. Implementado para lanzar el flujo, pero
///   la UI que lo llama va a necesitar ajustarse para esperar el
///   resultado por `authStateChanges` en vez de por el valor de retorno.
/// - `provisionUser`: el equivalente Firebase usaba una app secundaria
///   para crear la cuenta sin pisar la sesión del admin. En Supabase,
///   crear usuarios sin iniciar sesión como ellos requiere la Admin API
///   de GoTrue (`auth.admin.createUser`), que exige el `service_role`
///   key — ese secreto NUNCA debe vivir en el cliente Flutter (mismo
///   riesgo que ya se resolvió para el JWT bridge del piloto). Acá se
///   deja sin implementar (lanza [UnimplementedError]) hasta que exista
///   una Edge Function server-side equivalente a
///   `supabase/functions/firebase-token-exchange` que use el
///   service_role key del lado del servidor.
class SupabaseAuthRepository implements AuthRepositoryPort {
  final SupabaseClient _client;
  SupabaseAuthRepository(this._client);

  SupabaseQueryBuilder get _members => _client.from('gym_members');
  SupabaseQueryBuilder get _gyms => _client.from('gyms');

  Future<GymId?> _resolveGymIdFromCode(GymCode? gymCode) async {
    if (gymCode == null) return null;
    final row = await _gyms
        .select('id')
        .eq('code', gymCode.value)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return GymId(row['id'] as String);
  }

  Future<User?> _findMember(String id) async {
    final row = await _members.select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return UserMapper.fromSupabase(row);
  }

  @override
  FutureResult<AuthResult> login(AuthCredentials credentials) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: credentials.email.value,
        password: credentials.password,
      );
      final session = response.session;
      final gotrueUser = response.user;
      if (session == null || gotrueUser == null) {
        return left(AuthFailure.invalidCredentials());
      }

      final member = await _findMember(gotrueUser.id);
      if (member == null) {
        return left(AuthFailure.userNotFound());
      }

      final loggedInUser = member.recordLogin();
      await _members
          .update({'last_login_at': loggedInUser.lastLoginAt!.toIso8601String()})
          .eq('id', loggedInUser.id.value);

      return right(AuthResult(user: loggedInUser, token: session.accessToken));
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> register({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    GymId? gymId,
    double? weight,
    double? height,
    String? fitnessGoal,
  }) async {
    final effectiveGymId = gymId ?? const GymId('orphan-gym');
    try {
      final response = await _client.auth.signUp(
        email: email.value,
        password: password,
        data: {'full_name': name.fullName},
      );
      final gotrueUser = response.user;
      if (gotrueUser == null) {
        return left(const ServerFailure(
          message: 'Error al crear cuenta en Supabase Auth',
        ));
      }

      final baseUser = User.create(
        email: email,
        name: name,
        role: role,
        gymId: effectiveGymId,
        weight: weight,
        height: height,
        fitnessGoal: fitnessGoal,
      );
      final userWithId = User.restore(
        id: UserId(gotrueUser.id),
        email: baseUser.email,
        name: baseUser.name,
        role: baseUser.role,
        gymId: baseUser.gymId,
        phone: baseUser.phone,
        createdAt: baseUser.createdAt,
        isActive: true,
        membershipStatus: baseUser.membershipStatus,
        weight: baseUser.weight,
        height: baseUser.height,
        fitnessGoal: baseUser.fitnessGoal,
        membershipExpiresAt: baseUser.membershipExpiresAt,
        memberNumber: baseUser.memberNumber,
        memberNumberAssignedAt: baseUser.memberNumberAssignedAt,
      );

      await _members.insert(UserMapper.toSupabase(userWithId));

      final token = response.session?.accessToken ?? '';
      return right(AuthResult(user: userWithId, token: token));
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> signInWithGoogle({GymCode? gymCode}) async {
    try {
      final resolvedGymId = await _resolveGymIdFromCode(gymCode);
      if (gymCode != null && resolvedGymId == null) {
        return left(const ServerFailure(
          message: 'Gimnasio no encontrado con ese código',
        ));
      }

      // El paquete `supabase` (sin `_flutter`) no lanza el browser por
      // nosotros — solo construye la URL de OAuth (eso es responsabilidad
      // de supabase_flutter, que este proyecto evita a propósito, ver
      // pubspec.yaml). Se abre con url_launcher, ya dependencia del proyecto.
      final oauthResponse = await _client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
      );
      final uri = Uri.tryParse(oauthResponse.url);
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return left(const AuthFailure(
          message: 'No se pudo iniciar el acceso con Google',
        ));
      }

      // A diferencia de Firebase, acá no hay un resultado síncrono: el
      // flujo OAuth de GoTrue continúa por redirect/deep-link y el login
      // real se resuelve más tarde vía `authStateChanges`. Se documenta
      // como limitación conocida (ver comentario de clase) en vez de
      // simular un resultado que todavía no existe.
      return left(const ServerFailure(
        message: 'Acceso con Google iniciado; el resultado llega por authStateChanges',
        code: 'OAUTH_PENDING_REDIRECT',
      ));
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> provisionUser({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    required GymId gymId,
    PhoneNumber? phone,
  }) async {
    // Requiere una Edge Function server-side con el service_role key
    // (ver comentario de clase) — todavía no existe. No implementar
    // acá con el anon key: signUp() cambiaría la sesión del admin que
    // está provisionando al nuevo usuario, y usar el service_role key
    // directo desde el cliente expondría un secreto que salteA todo RLS.
    throw UnimplementedError(
      'provisionUser requiere una Edge Function server-side (service_role key) '
      'todavía no construida para el corte de Auth a Supabase.',
    );
  }

  @override
  FutureVoidResult logout() async {
    try {
      await _client.auth.signOut();
      return right(null);
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User?> getCurrentUser() async {
    try {
      final gotrueUser = _client.auth.currentUser;
      if (gotrueUser == null) {
        return right(null);
      }
      final member = await _findMember(gotrueUser.id);
      return right(member);
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _client.auth.currentSession != null;
  }

  @override
  FutureVoidResult sendPasswordReset(Email email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.value);
      return right(null);
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error al enviar email: $e'));
    }
  }

  @override
  FutureVoidResult changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final gotrueUser = _client.auth.currentUser;
      if (gotrueUser?.email == null) {
        return left(const AuthFailure(message: 'No hay sesión activa'));
      }

      // Re-autenticación: GoTrue no tiene un equivalente directo a
      // reauthenticateWithCredential de Firebase — se valida la
      // contraseña actual haciendo un login real contra ella antes de
      // cambiarla.
      await _client.auth.signInWithPassword(
        email: gotrueUser!.email!,
        password: currentPassword,
      );

      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return right(null);
    } on AuthException catch (e) {
      return left(_mapAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cambiar contraseña: $e'));
    }
  }

  @override
  FutureVoidResult updateProfile(User user) async {
    try {
      await _members.update(UserMapper.toSupabase(user)).eq('id', user.id.value);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final gotrueUser = state.session?.user;
      if (gotrueUser == null) return null;
      try {
        return await _findMember(gotrueUser.id);
      } catch (e) {
        return null;
      }
    });
  }

  AuthFailure _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return AuthFailure.invalidCredentials();
    }
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user_already_exists')) {
      return AuthFailure.emailAlreadyInUse();
    }
    if (message.contains('password') && message.contains('weak') ||
        message.contains('should be at least')) {
      return AuthFailure.weakPassword();
    }
    if (message.contains('user not found') || message.contains('user_not_found')) {
      return AuthFailure.userNotFound();
    }
    if (message.contains('rate limit') || message.contains('too many requests')) {
      return const AuthFailure(
        message: 'Demasiados intentos. Intenta más tarde.',
      );
    }
    if (kDebugMode) {
      debugPrint('[SupabaseAuthRepository] Error de auth sin mapear: ${e.message}');
    }
    return AuthFailure(message: 'Error de autenticación: ${e.message}');
  }
}
