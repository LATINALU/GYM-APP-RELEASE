import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/user_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import 'firebase/firebase_user_repository.dart';
import '../mappers/mappers.dart';

/// Decorator around [FirebaseUserRepository] that adds offline-first caching.
/// When online: fetches from Firestore and updates the local cache.
/// When offline: returns cached data from Hive, or a failure if never synced.
class CachedUserRepository implements UserRepositoryPort {
  final FirebaseUserRepository _remote;
  final LocalCacheService _cache;
  final ConnectivityService _connectivity;

  static const String _collection = 'users';

  CachedUserRepository(this._remote, this._cache, this._connectivity);

  @override
  FutureResult<User> findByIdGlobal(UserId id) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.get(_collection, id.value);
      if (cached != null) {
        return right(UserMapper.fromFirestore(cached, id.value));
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin usuario en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findByIdGlobal(id);
    result.fold((_) => null, (user) {
      _cache.put(_collection, id.value, UserMapper.toFirestore(user));
    });
    return result;
  }

  @override
  FutureResult<User> findById({
    required UserId id,
    required GymId gymId,
    required GymRoleType role,
  }) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.get(_collection, id.value);
      if (cached != null) {
        return right(UserMapper.fromFirestore(cached, id.value));
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin usuario en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findById(id: id, gymId: gymId, role: role);
    result.fold((_) => null, (user) {
      _cache.put(_collection, id.value, UserMapper.toFirestore(user));
    });
    return result;
  }

  @override
  FutureResult<User> findByEmail(Email email) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para buscar por email',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByEmail(email);
  }

  @override
  FutureResult<List<User>> findByRole({
    required GymId gymId,
    required GymRole role,
  }) async {
    final cacheKey = 'users_by_role:${gymId.value}:${role.type.name}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final users = cached
            .map((data) => UserMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(users);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin usuarios en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findByRole(gymId: gymId, role: role);
    result.fold((_) => null, (users) {
      final items = users
          .map((u) => {...UserMapper.toFirestore(u), 'id': u.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureResult<List<User>> findAllActive(GymId gymId) async {
    final cacheKey = 'users_active:${gymId.value}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final users = cached
            .map((data) => UserMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(users);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin usuarios en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findAllActive(gymId);
    result.fold((_) => null, (users) {
      final items = users
          .map((u) => {...UserMapper.toFirestore(u), 'id': u.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureVoidResult save(User user) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede guardar el usuario.',
        code: 'OFFLINE_WRITE',
      ));
    }
    final result = await _remote.save(user);
    result.fold((_) => null, (_) {
      _cache.put(_collection, user.id.value, UserMapper.toFirestore(user));
    });
    return result;
  }

  @override
  FutureVoidResult delete({
    required UserId id,
    required GymId gymId,
    required GymRoleType role,
  }) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede eliminar el usuario.',
        code: 'OFFLINE_WRITE',
      ));
    }
    return _remote.delete(id: id, gymId: gymId, role: role);
  }

  @override
  Future<bool> existsByEmail(Email email) async {
    if (!_connectivity.isOnline) {
      return false;
    }
    return _remote.existsByEmail(email);
  }

  @override
  FutureResult<List<User>> searchByName({
    required String query,
    required GymId gymId,
  }) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para buscar usuarios',
        code: 'OFFLINE',
      ));
    }
    return _remote.searchByName(query: query, gymId: gymId);
  }

  @override
  FutureResult<List<User>> findPendingUsers(GymId gymId) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findPendingUsers(gymId);
  }
}
