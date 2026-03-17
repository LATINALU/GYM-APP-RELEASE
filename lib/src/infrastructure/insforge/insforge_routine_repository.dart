import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/routine_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of RoutineRepositoryPort
class InsForgeRoutineRepository implements RoutineRepositoryPort {
  final InsForgeClient _client;

  InsForgeRoutineRepository(this._client);

  @override
  FutureResult<WorkoutRoutine> findById(RoutineId id) async {
    try {
      final response = await _client.from('workout_routines', query: 'id=eq.${id.value}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Rutina no encontrada'));
      }
      final routine = await _mapRoutineWithExercises(response.firstItem!);
      return Right(routine);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findAllActive() async {
    try {
      final response = await _client.from('workout_routines',
          query: 'is_active=eq.true&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      final routines = <WorkoutRoutine>[];
      for (final r in response.dataList) {
        routines.add(await _mapRoutineWithExercises(r as Map<String, dynamic>));
      }
      return Right(routines);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByCreator(UserId creatorId) async {
    try {
      final response = await _client.from('workout_routines',
          query: 'created_by=eq.${creatorId.value}&is_active=eq.true&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      final routines = <WorkoutRoutine>[];
      for (final r in response.dataList) {
        routines.add(await _mapRoutineWithExercises(r as Map<String, dynamic>));
      }
      return Right(routines);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult save(WorkoutRoutine routine) async {
    try {
      // Save routine
      final response = await _client.insert('workout_routines', {
        'id': routine.id.value,
        'name': routine.name,
        'description': routine.description,
        'difficulty': routine.difficulty.name,
        'estimated_duration_minutes': routine.estimatedDurationMinutes,
        'created_by': routine.createdBy.value,
        'is_active': routine.isActive,
      });

      if (response.isConflict) {
        await _client.update('workout_routines', {
          'name': routine.name,
          'description': routine.description,
          'difficulty': routine.difficulty.name,
          'estimated_duration_minutes': routine.estimatedDurationMinutes,
          'is_active': routine.isActive,
        }, 'id=eq.${routine.id.value}');
      } else if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error guardando rutina'));
      }

      // Save exercises (delete old, insert new)
      await _client.delete('routine_exercises', 'routine_id=eq.${routine.id.value}');
      for (int i = 0; i < routine.exercises.length; i++) {
        final ex = routine.exercises[i];
        await _client.insert('routine_exercises', {
          'routine_id': routine.id.value,
          'exercise_id': ex.id.value,
          'order_index': i,
          'sets': ex.sets,
          'reps': ex.reps,
          'rest_seconds': ex.restSeconds,
          'notes': ex.notes,
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult delete(RoutineId id) async {
    try {
      final response = await _client.update('workout_routines', {'is_active': false}, 'id=eq.${id.value}');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByDifficulty(DifficultyLevel difficulty) async {
    try {
      final response = await _client.from('workout_routines',
          query: 'is_active=eq.true&difficulty=eq.${difficulty.name}&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      final routines = <WorkoutRoutine>[];
      for (final r in response.dataList) {
        routines.add(await _mapRoutineWithExercises(r as Map<String, dynamic>));
      }
      return Right(routines);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPERS
  // ═══════════════════════════════════════════════════════════════════

  Future<WorkoutRoutine> _mapRoutineWithExercises(Map<String, dynamic> data) async {
    // Fetch routine exercises
    List<Exercise> exercises = [];
    try {
      final exResponse = await _client.from('routine_exercises',
          query: 'routine_id=eq.${data['id']}&select=*,exercises(*)&order=order_index.asc');
      if (exResponse.isSuccess) {
        for (final re in exResponse.dataList) {
          final reMap = re as Map<String, dynamic>;
          final exData = reMap['exercises'] as Map<String, dynamic>?;
          if (exData != null) {
            exercises.add(Exercise.restore(
              id: ExerciseId(exData['id'] as String? ?? ''),
              name: exData['name'] as String? ?? '',
              description: exData['description'] as String? ?? '',
              movementPattern: _parseMovement(exData['movement_pattern'] as String? ?? 'isolation'),
              exerciseType: _parseType(exData['exercise_type'] as String? ?? 'compound'),
              difficulty: _parseDifficulty(exData['difficulty'] as String? ?? 'intermediate'),
              equipment: [],
              heatmap: const MuscleHeatmap({}),
              isActive: true,
              createdAt: DateTime.tryParse(exData['created_at'] as String? ?? '') ?? DateTime.now(),
              sets: reMap['sets'] as int? ?? 3,
              reps: reMap['reps'] as int? ?? 10,
              restSeconds: reMap['rest_seconds'] as int? ?? 60,
              notes: reMap['notes'] as String?,
            ));
          }
        }
      }
    } catch (_) {}

    final diffStr = data['difficulty'] as String? ?? 'intermediate';
    DifficultyLevel diff;
    switch (diffStr) {
      case 'beginner': diff = DifficultyLevel.beginner; break;
      case 'advanced': diff = DifficultyLevel.advanced; break;
      default: diff = DifficultyLevel.intermediate;
    }

    return WorkoutRoutine.restore(
      id: RoutineId(data['id'] as String),
      name: data['name'] as String,
      description: data['description'] as String?,
      difficulty: diff,
      exercises: exercises,
      estimatedDurationMinutes: data['estimated_duration_minutes'] as int? ?? 60,
      createdBy: UserId(data['created_by'] as String),
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at'] as String) : null,
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  MovementPattern _parseMovement(String v) =>
      MovementPattern.values.firstWhere((m) => m.name == v, orElse: () => MovementPattern.isolation);
  ExerciseType _parseType(String v) =>
      ExerciseType.values.firstWhere((t) => t.name == v, orElse: () => ExerciseType.compound);
  ExerciseDifficulty _parseDifficulty(String v) =>
      ExerciseDifficulty.values.firstWhere((d) => d.name == v, orElse: () => ExerciseDifficulty.intermediate);
}
