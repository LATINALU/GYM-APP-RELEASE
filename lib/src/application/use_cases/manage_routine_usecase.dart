import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/data/exercise_catalog.dart';
import '../../domain/ports/input/manage_routine_usecase_port.dart';
import '../../domain/ports/output/output_ports.dart';
import '../../domain/value_objects/value_objects.dart';

/// Implementación del caso de uso para gestionar rutinas
/// Solo Admin y Empleados pueden usar este use case
class ManageRoutineUseCase implements ManageRoutineUseCasePort {
  final UserRepositoryPort _userRepository;
  final RoutineRepositoryPort _routineRepository;

  ManageRoutineUseCase({
    required UserRepositoryPort userRepository,
    required RoutineRepositoryPort routineRepository,
  })  : _userRepository = userRepository,
        _routineRepository = routineRepository;

  @override
  FutureResult<RoutineManagementResult> createRoutine(
    CreateRoutineCommand command,
  ) async {
    try {
      // 1. Validar permisos del usuario
      final permissionCheck = await _validateUserPermissions(command.createdBy);
      if (permissionCheck != null) {
        return left(permissionCheck);
      }

      // 2. Validar datos de entrada
      final validationError = _validateRoutineData(command);
      if (validationError != null) {
        return left(validationError);
      }

      // 3. Validar que los ejercicios existen
      final exercisesResult = _buildExercisesFromCommand(command.exercises);
      if (exercisesResult.isLeft()) {
        return left(exercisesResult.fold((f) => f, (_) => throw Exception()));
      }
      final exercises = exercisesResult.getOrElse(() => []);

      // 4. Crear la rutina
      final routine = WorkoutRoutine.create(
        name: command.name,
        description: command.description,
        difficulty: command.difficulty,
        exercises: exercises,
        estimatedDurationMinutes: _calculateDuration(exercises),
        createdBy: command.createdBy,
      );

      // 5. Guardar en repositorio
      final saveResult = await _routineRepository.save(routine);
      if (saveResult.isLeft()) {
        return left(saveResult.fold((f) => f, (_) => throw Exception()));
      }

      return right(RoutineManagementResult(
        routine: routine,
        message: 'Rutina "${routine.name}" creada exitosamente',
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al crear rutina: $e'));
    }
  }

  @override
  FutureResult<RoutineManagementResult> updateRoutine(
    UpdateRoutineCommand command,
  ) async {
    try {
      // 1. Validar permisos
      final permissionCheck = await _validateUserPermissions(command.updatedBy);
      if (permissionCheck != null) {
        return left(permissionCheck);
      }

      // 2. Obtener rutina existente
      final routineResult = await _routineRepository.findById(command.routineId);
      if (routineResult.isLeft()) {
        return left(const ValidationFailure(message: 'Rutina no encontrada'));
      }
      var routine = routineResult.getOrElse(() => throw Exception());

      // 3. Actualizar campos
      if (command.name != null) {
        routine = routine.copyWith(name: command.name);
      }
      if (command.description != null) {
        routine = routine.copyWith(description: command.description);
      }
      if (command.difficulty != null) {
        routine = routine.copyWith(difficulty: command.difficulty);
      }
      if (command.isActive != null) {
        routine = command.isActive! ? routine.activate() : routine.deactivate();
      }
      if (command.exercises != null) {
        final exercisesResult = _buildExercisesFromCommand(command.exercises!);
        if (exercisesResult.isLeft()) {
          return left(exercisesResult.fold((f) => f, (_) => throw Exception()));
        }
        final exercises = exercisesResult.getOrElse(() => []);
        routine = routine.copyWith(
          exercises: exercises,
          estimatedDurationMinutes: _calculateDuration(exercises),
        );
      }

      // 4. Guardar cambios
      final saveResult = await _routineRepository.save(routine);
      if (saveResult.isLeft()) {
        return left(saveResult.fold((f) => f, (_) => throw Exception()));
      }

      return right(RoutineManagementResult(
        routine: routine,
        message: 'Rutina actualizada exitosamente',
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al actualizar rutina: $e'));
    }
  }

  @override
  FutureResult<void> deleteRoutine(RoutineId routineId, UserId deletedBy) async {
    try {
      // 1. Validar permisos
      final permissionCheck = await _validateUserPermissions(deletedBy);
      if (permissionCheck != null) {
        return left(permissionCheck);
      }

      // 2. Soft delete - desactivar la rutina
      final routineResult = await _routineRepository.findById(routineId);
      if (routineResult.isLeft()) {
        return left(const ValidationFailure(message: 'Rutina no encontrada'));
      }
      var routine = routineResult.getOrElse(() => throw Exception());
      routine = routine.deactivate();

      // 3. Guardar
      return await _routineRepository.save(routine);
    } catch (e) {
      return left(ServerFailure(message: 'Error al eliminar rutina: $e'));
    }
  }

  @override
  FutureResult<RoutineManagementResult> duplicateRoutine({
    required RoutineId originalId,
    required String newName,
    required UserId createdBy,
  }) async {
    try {
      // 1. Validar permisos
      final permissionCheck = await _validateUserPermissions(createdBy);
      if (permissionCheck != null) {
        return left(permissionCheck);
      }

      // 2. Obtener rutina original
      final originalResult = await _routineRepository.findById(originalId);
      if (originalResult.isLeft()) {
        return left(const ValidationFailure(message: 'Rutina original no encontrada'));
      }
      final original = originalResult.getOrElse(() => throw Exception());

      // 3. Crear copia con nuevo ID y nombre
      final copy = WorkoutRoutine.create(
        name: newName,
        description: original.description,
        difficulty: original.difficulty,
        exercises: original.exercises,
        estimatedDurationMinutes: original.estimatedDurationMinutes,
        createdBy: createdBy,
      );

      // 4. Guardar
      final saveResult = await _routineRepository.save(copy);
      if (saveResult.isLeft()) {
        return left(saveResult.fold((f) => f, (_) => throw Exception()));
      }

      return right(RoutineManagementResult(
        routine: copy,
        message: 'Rutina duplicada como "${copy.name}"',
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error al duplicar rutina: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> getAllRoutines() async {
    return await _routineRepository.findAllActive();
  }

  @override
  FutureResult<List<WorkoutRoutine>> getRoutinesByDifficulty(
    DifficultyLevel difficulty,
  ) async {
    return await _routineRepository.findByDifficulty(difficulty);
  }

  // === HELPER METHODS ===

  Future<Failure?> _validateUserPermissions(UserId userId) async {
    final userResult = await _userRepository.findByIdGlobal(userId);
    return userResult.fold(
      (failure) => const PermissionFailure(
        message: 'Usuario no encontrado',
      ),
      (user) {
        if (!user.role.canAssignRoutines) {
          return const PermissionFailure(
            message: 'Solo Admin y Empleados pueden gestionar rutinas',
          );
        }
        if (!user.isActive) {
          return const PermissionFailure(
            message: 'Usuario inactivo',
          );
        }
        return null;
      },
    );
  }

  ValidationFailure? _validateRoutineData(CreateRoutineCommand command) {
    final errors = <String, String>{};

    if (command.name.trim().isEmpty) {
      errors['name'] = 'El nombre es requerido';
    } else if (command.name.length < 3) {
      errors['name'] = 'El nombre debe tener al menos 3 caracteres';
    }

    if (command.exercises.isEmpty) {
      errors['exercises'] = 'La rutina debe tener al menos un ejercicio';
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(
        message: errors.values.first,
        fieldErrors: errors,
      );
    }

    return null;
  }

  Result<List<Exercise>> _buildExercisesFromCommand(
    List<RoutineExerciseInput> inputs,
  ) {
    final exercises = <Exercise>[];

    for (final input in inputs) {
      final template = ExerciseCatalog.byId(input.templateId);
      if (template == null) {
        return left(ValidationFailure(
          message: 'Ejercicio no encontrado: ${input.templateId}',
        ));
      }

      exercises.add(Exercise.createFromTemplate(
        template: template,
        sets: input.sets,
        reps: input.maxReps,
        restSeconds: input.restSeconds,
        notes: input.notes,
      ));
    }

    return right(exercises);
  }

  int _calculateDuration(List<Exercise> exercises) {
    int totalMinutes = 0;
    for (final exercise in exercises) {
      // Aproximación: sets * (30 seg por set + descanso)
      final setTime = exercise.sets * 30; // 30 seg por set
      final restTime = exercise.sets * (exercise.restSeconds ?? 60);
      totalMinutes += ((setTime + restTime) / 60).ceil();
    }
    return totalMinutes.clamp(10, 180);
  }
}
