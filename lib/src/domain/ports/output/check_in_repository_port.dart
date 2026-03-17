import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - Check-In Repository Interface
abstract class CheckInRepositoryPort {
  /// Get check-in by ID
  FutureResult<CheckIn> findById(CheckInId id);

  /// Get check-ins for a client
  FutureResult<List<CheckIn>> findByClient(UserId clientId);

  /// Get check-ins for a specific date range
  FutureResult<List<CheckIn>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get client's check-ins for a date range
  FutureResult<List<CheckIn>> findByClientAndDateRange({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get today's check-ins
  FutureResult<List<CheckIn>> findToday();

  /// Save check-in
  FutureVoidResult save(CheckIn checkIn);

  /// Get active check-in for client (not checked out)
  FutureResult<CheckIn?> findActiveByClient(UserId clientId);

  /// Count check-ins for period
  Future<int> countByClientAndPeriod({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
