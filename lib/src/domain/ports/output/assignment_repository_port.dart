import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - Assignment Repository Interface
abstract class AssignmentRepositoryPort {
  /// Get assignment by ID
  FutureResult<RoutineAssignment> findById(AssignmentId id);

  /// Get active assignments for a client
  FutureResult<List<RoutineAssignment>> findActiveByClient(UserId clientId);

  /// Get all assignments for a client
  FutureResult<List<RoutineAssignment>> findByClient(UserId clientId);

  /// Get assignments by routine
  FutureResult<List<RoutineAssignment>> findByRoutine(RoutineId routineId);

  /// Get assignments created by a specific user (employee/owner)
  FutureResult<List<RoutineAssignment>> findByAssigner(UserId assignerId);

  /// Save assignment
  FutureVoidResult save(RoutineAssignment assignment);

  /// Delete assignment
  FutureVoidResult delete(AssignmentId id);

  /// Check if client has active assignment for routine
  Future<bool> hasActiveAssignment(UserId clientId, RoutineId routineId);
}
