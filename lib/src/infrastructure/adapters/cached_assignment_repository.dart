import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/assignment_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import 'firebase/firebase_assignment_repository.dart';
import '../mappers/mappers.dart';

/// Decorator around [FirebaseAssignmentRepository] that adds offline-first caching.
/// When online: fetches from Firestore and updates the local cache.
/// When offline: returns cached data from Hive, or a failure if never synced.
class CachedAssignmentRepository implements AssignmentRepositoryPort {
  final FirebaseAssignmentRepository _remote;
  final LocalCacheService _cache;
  final ConnectivityService _connectivity;

  static const String _collection = 'assignments';

  CachedAssignmentRepository(this._remote, this._cache, this._connectivity);

  @override
  FutureResult<RoutineAssignment> findById(AssignmentId id) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.get(_collection, id.value);
      if (cached != null) {
        return right(AssignmentMapper.fromFirestore(cached, id.value));
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin datos en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findById(id);
    result.fold((_) => null, (assignment) {
      _cache.put(_collection, id.value, AssignmentMapper.toFirestore(assignment));
    });
    return result;
  }

  @override
  FutureResult<List<RoutineAssignment>> findActiveByClient(UserId clientId) async {
    final cacheKey = 'active_assignments:${clientId.value}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final assignments = cached
            .map((data) => AssignmentMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(assignments);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin rutinas en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findActiveByClient(clientId);
    result.fold((_) => null, (assignments) {
      final items = assignments
          .map((a) => {...AssignmentMapper.toFirestore(a), 'id': a.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureResult<List<RoutineAssignment>> findByClient(UserId clientId) async {
    final cacheKey = 'assignments:${clientId.value}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final assignments = cached
            .map((data) => AssignmentMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(assignments);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin rutinas en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findByClient(clientId);
    result.fold((_) => null, (assignments) {
      final items = assignments
          .map((a) => {...AssignmentMapper.toFirestore(a), 'id': a.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureResult<List<RoutineAssignment>> findByRoutine(RoutineId routineId) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByRoutine(routineId);
  }

  @override
  FutureResult<List<RoutineAssignment>> findByAssigner(UserId assignerId) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByAssigner(assignerId);
  }

  @override
  FutureVoidResult save(RoutineAssignment assignment) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede guardar la asignación.',
        code: 'OFFLINE_WRITE',
      ));
    }
    final result = await _remote.save(assignment);
    result.fold((_) => null, (_) {
      _cache.put(_collection, assignment.id.value, AssignmentMapper.toFirestore(assignment));
    });
    return result;
  }

  @override
  FutureVoidResult delete(AssignmentId id) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede eliminar la asignación.',
        code: 'OFFLINE_WRITE',
      ));
    }
    return _remote.delete(id);
  }

  @override
  Future<bool> hasActiveAssignment(UserId clientId, RoutineId routineId) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection('active_assignments:${clientId.value}');
      if (cached != null) {
        return cached.any((a) =>
            a['routineId'] == routineId.value && a['status'] == 'active');
      }
      return false;
    }
    return _remote.hasActiveAssignment(clientId, routineId);
  }
}
