import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/check_in_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import 'firebase/firebase_checkin_repository.dart';
import '../mappers/mappers.dart';

/// Decorator around [FirebaseCheckInRepository] that adds offline-first caching.
/// When online: fetches from Firestore and updates the local cache.
/// When offline: returns cached data from Hive, or a failure if never synced.
class CachedCheckInRepository implements CheckInRepositoryPort {
  final FirebaseCheckInRepository _remote;
  final LocalCacheService _cache;
  final ConnectivityService _connectivity;

  static const String _collection = 'check_ins';

  CachedCheckInRepository(this._remote, this._cache, this._connectivity);

  @override
  FutureResult<CheckIn> findById(CheckInId id) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.get(_collection, id.value);
      if (cached != null) {
        return right(CheckInMapper.fromFirestore(cached, id.value));
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin check-in en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findById(id);
    result.fold((_) => null, (checkIn) {
      _cache.put(_collection, id.value, CheckInMapper.toFirestore(checkIn));
    });
    return result;
  }

  @override
  FutureResult<List<CheckIn>> findByClient(UserId clientId) async {
    final cacheKey = 'check_ins_by_client:${clientId.value}';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final checkIns = cached
            .map((data) => CheckInMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(checkIns);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin check-ins en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findByClient(clientId);
    result.fold((_) => null, (checkIns) {
      final items = checkIns
          .map((c) => {...CheckInMapper.toFirestore(c), 'id': c.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureResult<List<CheckIn>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByDateRange(startDate: startDate, endDate: endDate);
  }

  @override
  FutureResult<List<CheckIn>> findByClientAndDateRange({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión para esta operación',
        code: 'OFFLINE',
      ));
    }
    return _remote.findByClientAndDateRange(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  FutureResult<List<CheckIn>> findToday() async {
    final cacheKey = 'check_ins_today';

    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection(cacheKey);
      if (cached != null) {
        final checkIns = cached
            .map((data) => CheckInMapper.fromFirestore(data, data['id'] ?? ''))
            .toList();
        return right(checkIns);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin check-ins en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }

    final result = await _remote.findToday();
    result.fold((_) => null, (checkIns) {
      final items = checkIns
          .map((c) => {...CheckInMapper.toFirestore(c), 'id': c.id.value})
          .toList();
      _cache.putCollection(cacheKey, items);
      _cache.setLastSync(cacheKey, DateTime.now());
    });
    return result;
  }

  @override
  FutureVoidResult save(CheckIn checkIn) async {
    if (!_connectivity.isOnline) {
      return left(const ServerFailure(
        message: 'Sin conexión. No se puede registrar el check-in.',
        code: 'OFFLINE_WRITE',
      ));
    }
    final result = await _remote.save(checkIn);
    result.fold((_) => null, (_) {
      _cache.put(_collection, checkIn.id.value, CheckInMapper.toFirestore(checkIn));
    });
    return result;
  }

  @override
  FutureResult<CheckIn?> findActiveByClient(UserId clientId) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection('check_ins_by_client:${clientId.value}');
      if (cached != null) {
        final active = cached.where((c) => c['checkOutTime'] == null).toList();
        if (active.isNotEmpty) {
          return right(CheckInMapper.fromFirestore(active.first, active.first['id'] ?? ''));
        }
        return right(null);
      }
      return left(const ServerFailure(
        message: 'Sin conexión y sin check-ins en caché',
        code: 'OFFLINE_NO_CACHE',
      ));
    }
    return _remote.findActiveByClient(clientId);
  }

  @override
  Future<int> countByClientAndPeriod({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_connectivity.isOnline) {
      final cached = _cache.getCollection('check_ins_by_client:${clientId.value}');
      if (cached != null) {
        return cached.where((c) {
          final time = c['checkInTime'] as String?;
          if (time == null) return false;
          final dt = DateTime.tryParse(time);
          if (dt == null) return false;
          return dt.isAfter(startDate.subtract(const Duration(days: 1))) &&
              dt.isBefore(endDate.add(const Duration(days: 1)));
        }).length;
      }
      return 0;
    }
    return _remote.countByClientAndPeriod(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
