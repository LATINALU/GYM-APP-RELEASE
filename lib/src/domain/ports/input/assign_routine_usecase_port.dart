import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Command for assigning a routine
class AssignRoutineCommand {
  final RoutineId routineId;
  final UserId clientId;
  final UserId assignerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  const AssignRoutineCommand({
    required this.routineId,
    required this.clientId,
    required this.assignerId,
    this.startDate,
    this.endDate,
    this.notes,
  });
}

/// Result of routine assignment
class AssignRoutineResult {
  final RoutineAssignment assignment;
  final String message;

  const AssignRoutineResult({
    required this.assignment,
    required this.message,
  });
}

/// Input Port - Assign Routine Use Case Interface
abstract class AssignRoutineUseCasePort {
  /// Execute routine assignment
  FutureResult<AssignRoutineResult> execute(AssignRoutineCommand command);
}
