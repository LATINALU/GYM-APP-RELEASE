import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/user_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of UserRepositoryPort
class InsForgeUserRepository implements UserRepositoryPort {
  final InsForgeClient _client;

  InsForgeUserRepository(this._client);

  @override
  FutureResult<User> findByIdGlobal(UserId id) async {
    try {
      final response = await _client.from('users', query: 'id=eq.${id.value}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Usuario no encontrado'));
      }
      return Right(_mapUser(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<User> findById({required UserId id, required GymId gymId, required GymRoleType role}) async {
    try {
      final response = await _client.from('users',
          query: 'id=eq.${id.value}&gym_id=eq.${gymId.value}&role=eq.${role.name}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Usuario no encontrado'));
      }
      return Right(_mapUser(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<User> findByEmail(Email email) async {
    try {
      final response = await _client.from('users', query: 'email=eq.${email.value}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return Left(NotFoundFailure(message: 'Usuario con email ${email.value} no encontrado'));
      }
      return Right(_mapUser(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<User>> findByRole({required GymId gymId, required GymRole role}) async {
    try {
      final response = await _client.from('users',
          query: 'gym_id=eq.${gymId.value}&role=eq.${role.type.name}&select=*&order=created_at.desc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo usuarios'));
      }
      final users = response.dataList.map((u) => _mapUser(u as Map<String, dynamic>)).toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<User>> findAllActive(GymId gymId) async {
    try {
      final response = await _client.from('users',
          query: 'gym_id=eq.${gymId.value}&is_active=eq.true&select=*&order=created_at.desc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo usuarios activos'));
      }
      final users = response.dataList.map((u) => _mapUser(u as Map<String, dynamic>)).toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult save(User user) async {
    try {
      final data = _toMap(user);
      // Upsert: try insert, if conflict update
      final response = await _client.insert('users', data);
      if (response.isConflict) {
        // Already exists, update instead
        final updateResp = await _client.update('users', data, 'id=eq.${user.id.value}');
        if (!updateResp.isSuccess) {
          return Left(ServerFailure(message: updateResp.error ?? 'Error actualizando usuario'));
        }
      } else if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error guardando usuario'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult delete({required UserId id, required GymId gymId, required GymRoleType role}) async {
    try {
      final response = await _client.delete('users', 'id=eq.${id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error eliminando usuario'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  Future<bool> existsByEmail(Email email) async {
    try {
      final response = await _client.from('users', query: 'email=eq.${email.value}&select=id');
      return response.isSuccess && response.dataList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  FutureResult<List<User>> searchByName({required String query, required GymId gymId}) async {
    try {
      final response = await _client.from('users',
          query: 'gym_id=eq.${gymId.value}&or=(first_name.ilike.*$query*,last_name.ilike.*$query*)&select=*&order=first_name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando usuarios'));
      }
      final users = response.dataList.map((u) => _mapUser(u as Map<String, dynamic>)).toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<User>> findPendingUsers(GymId gymId) async {
    try {
      final response = await _client.from('users',
          query: 'gym_id=eq.${gymId.value}&membership_status=eq.pending&select=*&order=created_at.desc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo usuarios pendientes'));
      }
      final users = response.dataList.map((u) => _mapUser(u as Map<String, dynamic>)).toList();
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPERS
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> _toMap(User user) {
    return {
      'id': user.id.value,
      'email': user.email.value,
      'first_name': user.name.firstName,
      'last_name': user.name.lastName,
      'role': user.role.type.name,
      'gym_id': user.gymId.value,
      'phone': user.phone?.value,
      'is_active': user.isActive,
      'membership_status': user.membershipStatus.name,
      'weight': user.weight,
      'height': user.height,
      'fitness_goal': user.fitnessGoal,
      'membership_expires_at': user.membershipExpiresAt?.toIso8601String(),
      'last_login_at': user.lastLoginAt?.toIso8601String(),
    };
  }

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
}
