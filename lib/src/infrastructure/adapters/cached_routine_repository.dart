import 'dart:async';

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/exercise_media_port.dart';
import '../../domain/ports/output/routine_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import 'firebase/firebase_routine_repository.dart';
import '../mappers/mappers.dart';

/// Decorator around [FirebaseRoutineRepository] that adds offline-first caching.
/// When online: fetches from Firestore and updates the local cache.
/// When offline: returns cached data from Hive, or a failure if never synced.
///
/// Además, tras cada sync exitoso hace prefetch en segundo plano de los GIFs
/// de los ejercicios, para que las rutinas se puedan revisar sin internet.
class CachedRoutineRepository implements RoutineRepositoryPort {
  final FirebaseRoutineRepository _remote;
  final LocalCacheService _cache;
  final ConnectivityService _connectivity;
  final ExerciseMediaPort? _media;

  static const String _collection = 'routines';

  CachedRoutineRepository(
    this._remote,
    this._cache,
    this._connectivity, {
    ExerciseMediaPort? media,
  }) : _media = media;

  /// Prefetch silencioso de GIFs de las rutinas (fire-and-forget)
  void _prefetchMedia(Iterable<WorkoutRoutine> routines) {
    final media = _media;
    if (media == null) return;
    final urls = routines
        .expand((r) => r.exercises)
        .map((e) => e.animationUrl)
        .whereType<String>();
    unawaited(media.prefetch(urls));
  }

  @override
  FutureResult<WorkoutRoutine> findById(RoutineId id) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.get(_collection, id.value);
      if (cached != null) {
        return right(RoutineMapper.fromFirestore(cached, id.value));
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin rutina en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findById(id);
    result.fold((_) => null, (routine) {
      _cache.put(_collection, id.value, RoutineMapper.toFirestore(routine));
      _prefetchMedia([routine]);
    });
    return result;
  }

  @override
  FutureResult<List<WorkoutRoutine>> findAllActive() async {
    final cacheKey = 'active_routines';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final routines = cached
            .map((data) => RoutineMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(routines);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin rutinas en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findAllActive();
    result.fold((_) => null, (routines) {
      final items = routines
          .map((r) => {...RoutineMapper.toFirestore(r), 'id': r.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
      _prefetchMedia(routines);
    });
    return result;
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByCreator(UserId creatorId) async {
    final cacheKey = 'routines_by_creator:${creatorId.value}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final routines = cached
            .map((data) => RoutineMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(routines);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin rutinas en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findByCreator(creatorId);
    result.fold((_) => null, (routines) {
      final items = routines
          .map((r) => {...RoutineMapper.toFirestore(r), 'id': r.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
      _prefetchMedia(routines);
    });
    return result;
  }

  @override
  FutureVoidResult save(WorkoutRoutine routine) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede guardar la rutina.',
        code: 'OFFLINE_WRITE',
      ));
    }
    final result = await _remote.save(routine);
    result.fold((_) => null, (_) {
      _cache.put(_collection, routine.id.value, RoutineMapper.toFirestore(routine));
      _prefetchMedia([routine]);
    });
    return result;
  }

  @override
  FutureVoidResult delete(RoutineId id) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede eliminar la rutina.',
        code: 'OFFLINE_WRITE',
      ));
    }
    return _remote.delete(id);
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByDifficulty(DifficultyLevel difficulty) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByDifficulty(difficulty);
  }
}
