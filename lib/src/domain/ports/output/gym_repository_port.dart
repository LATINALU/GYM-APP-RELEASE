import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../../../core/types/typedefs.dart';

/// Gym Repository Port - Output Port for Gym persistence
abstract class GymRepositoryPort {
  /// Save a new gym
  FutureResult<GymId> save(Gym gym);

  /// Find gym by ID
  FutureResult<Gym> findById(GymId id);

  /// Update gym details
  FutureResult<void> update(Gym gym);

  /// List all active gyms (for admin/super-admin use)
  FutureResult<List<Gym>> findAll();

  /// Deactivate a gym
  FutureResult<void> deactivate(GymId id);

  /// Get general statistics for a gym
  FutureResult<Map<String, dynamic>> getStats(GymId id);

  /// Get daily metrics for a date range
  FutureResult<List<Map<String, dynamic>>> getDailyMetrics({
    required GymId id,
    required DateTime start,
    required DateTime end,
  });

  /// Find a gym by its human-readable code
  FutureResult<Gym> findByCode(GymCode code);
}
