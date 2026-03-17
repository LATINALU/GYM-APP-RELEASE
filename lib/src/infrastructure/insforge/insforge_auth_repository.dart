import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of AuthRepositoryPort
/// Replaces Firebase Auth with InsForge JWT-based authentication
class InsForgeAuthRepository implements AuthRepositoryPort {
  final InsForgeClient _client;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  User? _currentUser;

  InsForgeAuthRepository(this._client);

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  FutureResult<AuthResult> login(AuthCredentials credentials) async {
    try {
      final response = await _client.authLogin(
        credentials.email.value,
        credentials.password,
      );

      if (!response.isSuccess) {
        return Left(AuthFailure(message: response.error ?? 'Error de autenticación'));
      }

      final data = response.dataMap;
      // InsForge returns: {accessToken, refreshToken, user, csrfToken}
      final token = data['accessToken'] as String? ?? data['access_token'] as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String?;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      _client.setTokens(
        accessToken: token,
        refreshToken: refreshToken,
        userId: userData['id']?.toString(),
      );

      final user = _mapUser(userData);
      _currentUser = user;
      _authStateController.add(user);

      return Right(AuthResult(user: user, token: token));
    } catch (e) {
      debugPrint('[InsForgeAuth] Login error: $e');
      return Left(AuthFailure(message: 'Error de conexión: $e'));
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
    try {
      // InsForge expects: {email, password, name}
      // Additional fields (role, gym_id, etc.) are stored via PostgREST after registration
      final response = await _client.authRegister({
        'email': email.value,
        'password': password,
        'name': '${name.firstName} ${name.lastName}',
      });

      if (!response.isSuccess) {
        if (response.isConflict) {
          return const Left(AuthFailure(message: 'El email ya está registrado'));
        }
        return Left(AuthFailure(message: response.error ?? 'Error de registro'));
      }

      final data = response.dataMap;
      final token = data['accessToken'] as String? ?? data['access_token'] as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String?;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      _client.setTokens(
        accessToken: token,
        refreshToken: refreshToken,
        userId: userData['id']?.toString(),
      );

      final user = _mapUser(userData);
      _currentUser = user;
      _authStateController.add(user);

      // After InsForge registration, update user record with GYM-APP specific fields
      if (userData['id'] != null) {
        await _client.update('users', {
          'role': role.type.name,
          if (gymId != null) 'gym_id': gymId.value,
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
          'first_name': name.firstName,
          'last_name': name.lastName,
        }, 'id=eq.${userData['id']}');
      }

      return Right(AuthResult(user: user, token: token));
    } catch (e) {
      debugPrint('[InsForgeAuth] Register error: $e');
      return Left(AuthFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<AuthResult> signInWithGoogle({
    GymCode? gymCode,
  }) async {
    return const Left(
      AuthFailure(
        message: 'Google Sign-In no está disponible en el backend InsForge.',
      ),
    );
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
    return const Left(
      AuthFailure(
        message: 'El aprovisionamiento admin no está disponible en el backend InsForge.',
      ),
    );
  }

  @override
  FutureVoidResult logout() async {
    try {
      await _client.authLogout();
      _currentUser = null;
      _authStateController.add(null);
      return const Right(null);
    } catch (e) {
      // Even if server logout fails, clear local state
      _client.clearTokens();
      _currentUser = null;
      _authStateController.add(null);
      return const Right(null);
    }
  }

  @override
  FutureResult<User?> getCurrentUser() async {
    if (_currentUser != null) return Right(_currentUser);

    if (!_client.isAuthenticated) {
      return const Right(null);
    }

    try {
      final response = await _client.authMe();
      if (!response.isSuccess) {
        if (response.isUnauthorized) {
          // Try refresh
          final refreshed = await _tryRefreshToken();
          if (!refreshed) {
            _currentUser = null;
            _authStateController.add(null);
            return const Right(null);
          }
          // Retry
          final retryResponse = await _client.authMe();
          if (!retryResponse.isSuccess) return const Right(null);
          final user = _mapUser(retryResponse.dataMap);
          _currentUser = user;
          return Right(user);
        }
        return const Right(null);
      }

      final user = _mapUser(response.dataMap);
      _currentUser = user;
      return Right(user);
    } catch (e) {
      debugPrint('[InsForgeAuth] getCurrentUser error: $e');
      return const Right(null);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    if (_client.isAuthenticated) return true;
    await _client.restoreTokens();
    return _client.isAuthenticated;
  }

  @override
  FutureVoidResult sendPasswordReset(Email email) async {
    try {
      final response = await _client.authResetPassword(email.value);
      if (!response.isSuccess) {
        return Left(AuthFailure(message: response.error ?? 'Error enviando reset'));
      }
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _client.authChangePassword(currentPassword, newPassword);
      if (!response.isSuccess) {
        return Left(AuthFailure(message: response.error ?? 'Error cambiando contraseña'));
      }
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult updateProfile(User user) async {
    try {
      final response = await _client.update('users', {
        'first_name': user.name.firstName,
        'last_name': user.name.lastName,
        if (user.phone != null) 'phone': user.phone!.value,
        if (user.weight != null) 'weight': user.weight,
        if (user.height != null) 'height': user.height,
        if (user.fitnessGoal != null) 'fitness_goal': user.fitnessGoal,
      }, 'id=eq.${user.id.value}');

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error actualizando perfil'));
      }

      _currentUser = user;
      _authStateController.add(user);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Future<bool> _tryRefreshToken() async {
    try {
      final response = await _client.authRefresh();
      if (response.isSuccess) {
        final data = response.dataMap;
        _client.setTokens(
          accessToken: data['token'] ?? data['access_token'] ?? '',
          refreshToken: data['refresh_token'],
          userId: _client.currentUserId,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Map raw JSON to domain User entity
  User _mapUser(Map<String, dynamic> data) {
    final roleStr = data['role'] as String? ?? 'client';
    GymRole role;
    switch (roleStr) {
      case 'admin':
        role = const GymRole.admin();
        break;
      case 'owner':
        role = const GymRole.owner();
        break;
      case 'employee':
        role = const GymRole.employee();
        break;
      default:
        role = const GymRole.client();
    }

    final statusStr = data['membership_status'] as String? ?? 'pending';
    MembershipStatus status;
    switch (statusStr) {
      case 'approved':
        status = MembershipStatus.approved;
        break;
      case 'rejected':
        status = MembershipStatus.rejected;
        break;
      default:
        status = MembershipStatus.pending;
    }

    return User.restore(
      id: UserId(data['id'] as String),
      email: Email(data['email'] as String),
      name: PersonName(
        firstName: data['first_name'] as String? ?? '',
        lastName: data['last_name'] as String? ?? '',
      ),
      role: role,
      gymId: GymId(data['gym_id'] as String? ?? 'unassigned'),
      phone: data['phone'] != null ? PhoneNumber(data['phone'] as String) : null,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      lastLoginAt: data['last_login_at'] != null ? DateTime.tryParse(data['last_login_at'] as String) : null,
      isActive: data['is_active'] as bool? ?? true,
      membershipStatus: status,
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      fitnessGoal: data['fitness_goal'] as String?,
      membershipExpiresAt: data['membership_expires_at'] != null
          ? DateTime.tryParse(data['membership_expires_at'] as String)
          : null,
    );
  }

  void dispose() {
    _authStateController.close();
  }
}
