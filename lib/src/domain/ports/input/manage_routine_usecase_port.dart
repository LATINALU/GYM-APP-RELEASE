import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Command para crear/editar una rutina
class CreateRoutineCommand {
  final String name;
  final String? description;
  final DifficultyLevel difficulty;
  final List<RoutineExerciseInput> exercises;
  final UserId createdBy;
  final bool isActive;
  
  const CreateRoutineCommand({
    required this.name,
    this.description,
    required this.difficulty,
    required this.exercises,
    required this.createdBy,
    this.isActive = true,
  });
}

/// Input para un ejercicio dentro de la rutina
class RoutineExerciseInput {
  final String templateId;
  final int order;
  final int sets;
  final int minReps;
  final int maxReps;
  final int restSeconds;
  final double? targetWeight;
  final String? notes;
  
  const RoutineExerciseInput({
    required this.templateId,
    required this.order,
    this.sets = 3,
    this.minReps = 8,
    this.maxReps = 12,
    this.restSeconds = 90,
    this.targetWeight,
    this.notes,
  });
}

/// Command para actualizar una rutina existente
class UpdateRoutineCommand {
  final RoutineId routineId;
  final String? name;
  final String? description;
  final DifficultyLevel? difficulty;
  final List<RoutineExerciseInput>? exercises;
  final bool? isActive;
  final UserId updatedBy;
  
  const UpdateRoutineCommand({
    required this.routineId,
    this.name,
    this.description,
    this.difficulty,
    this.exercises,
    this.isActive,
    required this.updatedBy,
  });
}

/// Resultado de la creación/edición de rutina
class RoutineManagementResult {
  final WorkoutRoutine routine;
  final String message;
  
  const RoutineManagementResult({
    required this.routine,
    required this.message,
  });
}

/// Input Port - Manage Routine Use Case Interface
/// Para Admin y Empleados - crear, editar, eliminar rutinas
abstract class ManageRoutineUseCasePort {
  /// Crear nueva rutina
  FutureResult<RoutineManagementResult> createRoutine(CreateRoutineCommand command);
  
  /// Actualizar rutina existente
  FutureResult<RoutineManagementResult> updateRoutine(UpdateRoutineCommand command);
  
  /// Eliminar rutina (soft delete)
  FutureResult<void> deleteRoutine(RoutineId routineId, UserId deletedBy);
  
  /// Duplicar rutina existente
  FutureResult<RoutineManagementResult> duplicateRoutine({
    required RoutineId originalId,
    required String newName,
    required UserId createdBy,
  });
  
  /// Obtener todas las rutinas (para Admin/Empleado)
  FutureResult<List<WorkoutRoutine>> getAllRoutines();
  
  /// Obtener rutinas por dificultad
  FutureResult<List<WorkoutRoutine>> getRoutinesByDifficulty(DifficultyLevel difficulty);
}
