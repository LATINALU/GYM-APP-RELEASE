import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - Routine Repository Interface
abstract class RoutineRepositoryPort {
  /// Get routine by ID
  FutureResult<WorkoutRoutine> findById(RoutineId id);

  /// Get all active routines
  FutureResult<List<WorkoutRoutine>> findAllActive();

  /// Get routines created by specific user
  FutureResult<List<WorkoutRoutine>> findByCreator(UserId creatorId);

  /// Save routine (create or update)
  FutureVoidResult save(WorkoutRoutine routine);

  /// Delete routine
  FutureVoidResult delete(RoutineId id);

  /// Get routines by difficulty
  FutureResult<List<WorkoutRoutine>> findByDifficulty(DifficultyLevel difficulty);
}
