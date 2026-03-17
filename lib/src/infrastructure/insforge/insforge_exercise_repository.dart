import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/exercise_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of ExerciseRepositoryPort
class InsForgeExerciseRepository implements ExerciseRepositoryPort {
  final InsForgeClient _client;

  InsForgeExerciseRepository(this._client);

  @override
  FutureResult<List<ExerciseTemplate>> findAll() async {
    try {
      final response = await _client.from('exercises', query: 'is_active=eq.true&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo ejercicios'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<ExerciseTemplate> findById(String id) async {
    try {
      final response = await _client.from('exercises', query: 'id=eq.$id&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Ejercicio no encontrado'));
      }
      return Right(_mapTemplate(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByMuscle(MuscleGroup muscle) async {
    try {
      // Use heatmap JSONB to filter by muscle group
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&heatmap->>${muscle.name}=not.is.null&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando por músculo'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByPattern(MovementPattern pattern) async {
    try {
      final patternStr = pattern.name;
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&movement_pattern=eq.$patternStr&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando por patrón'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByEquipment(EquipmentType equipment) async {
    try {
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&equipment=cs.["${equipment.name}"]&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando por equipamiento'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByDifficulty(ExerciseDifficulty difficulty) async {
    try {
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&difficulty=eq.${difficulty.name}&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando por dificultad'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> search(String query) async {
    try {
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&or=(name.ilike.*$query*,description.ilike.*$query*)&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error buscando ejercicios'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findCompoundExercises() async {
    try {
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&exercise_type=eq.compound&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo compuestos'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findIsolationExercises() async {
    try {
      final response = await _client.from('exercises',
          query: 'is_active=eq.true&exercise_type=eq.isolation&select=*&order=name.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo aislamiento'));
      }
      final exercises = response.dataList.map((e) => _mapTemplate(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXTENDED METHODS (for Admin/Owner CRUD)
  // ═══════════════════════════════════════════════════════════════════

  /// Save a new exercise (Admin global or Owner gym-specific)
  FutureResult<Exercise> saveExercise(Exercise exercise) async {
    try {
      final response = await _client.insert('exercises', _exerciseToMap(exercise));
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error guardando ejercicio'));
      }
      return Right(exercise);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Update an exercise
  FutureVoidResult updateExercise(Exercise exercise) async {
    try {
      final response = await _client.update('exercises', _exerciseToMap(exercise), 'id=eq.${exercise.id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error actualizando ejercicio'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Delete (soft) an exercise
  FutureVoidResult deleteExercise(String exerciseId) async {
    try {
      final response = await _client.update('exercises', {'is_active': false}, 'id=eq.$exerciseId');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error eliminando ejercicio'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Get exercises by scope (global or gym-specific)
  FutureResult<List<Exercise>> findByScope(ExerciseScope scope, {GymId? gymId}) async {
    try {
      String query = 'is_active=eq.true&scope=eq.${scope.name}&select=*&order=name.asc';
      if (gymId != null && scope == ExerciseScope.gym) {
        query = 'is_active=eq.true&scope=eq.gym&gym_id=eq.${gymId.value}&select=*&order=name.asc';
      }
      final response = await _client.from('exercises', query: query);
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo ejercicios'));
      }
      final exercises = response.dataList.map((e) => _mapExercise(e as Map<String, dynamic>)).toList();
      return Right(exercises);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPERS
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> _exerciseToMap(Exercise exercise) {
    return {
      'id': exercise.id.value,
      'name': exercise.name,
      'description': exercise.description,
      'instructions': exercise.instructions,
      'image_url': exercise.imageUrl,
      'animation_url': exercise.animationUrl,
      'video_url': exercise.videoUrl,
      'scope': exercise.scope.name,
      'created_by': exercise.createdBy?.value,
      'gym_id': exercise.gymId?.value,
      'movement_pattern': exercise.movementPattern.name,
      'exercise_type': exercise.exerciseType.name,
      'difficulty': exercise.difficulty.name,
      'equipment': exercise.equipment.map((e) => e.name).toList(),
      'heatmap': exercise.heatmap.intensities,
    };
  }

  ExerciseTemplate _mapTemplate(Map<String, dynamic> data) {
    return ExerciseTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      spanishName: data['spanish_name'] as String? ?? data['name'] as String,
      description: data['description'] as String? ?? '',
      primaryMuscle: _parseMuscleFromHeatmap(data['heatmap']),
      secondaryMuscles: _parseSecondaryMuscles(data['heatmap']),
      movementPattern: _parseMovementPattern(data['movement_pattern'] as String? ?? 'isolation'),
      exerciseType: _parseExerciseType(data['exercise_type'] as String? ?? 'compound'),
      equipment: _parseEquipmentList(data['equipment']),
      difficulty: _parseDifficulty(data['difficulty'] as String? ?? 'intermediate'),
    );
  }

  Exercise _mapExercise(Map<String, dynamic> data) {
    return Exercise.create(
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      instructions: data['instructions'] as String?,
      imageUrl: data['image_url'] as String?,
      animationUrl: data['animation_url'] as String?,
      videoUrl: data['video_url'] as String?,
      movementPattern: _parseMovementPattern(data['movement_pattern'] as String? ?? 'isolation'),
      exerciseType: _parseExerciseType(data['exercise_type'] as String? ?? 'compound'),
      difficulty: _parseDifficulty(data['difficulty'] as String? ?? 'intermediate'),
      equipment: _parseEquipmentList(data['equipment']),
      heatmap: MuscleHeatmap(_parseHeatmap(data['heatmap'])),
      scope: data['scope'] == 'gym' ? ExerciseScope.gym : ExerciseScope.global,
      createdBy: data['created_by'] != null ? UserId(data['created_by'] as String) : null,
      gymId: data['gym_id'] != null ? GymId(data['gym_id'] as String) : null,
    );
  }

  MuscleGroup _parseMuscleFromHeatmap(dynamic heatmap) {
    if (heatmap is Map) {
      final sorted = heatmap.entries.toList()..sort((a, b) => ((b.value as num?) ?? 0).compareTo((a.value as num?) ?? 0));
      if (sorted.isNotEmpty) {
        return MuscleGroup.values.firstWhere(
          (m) => m.name == sorted.first.key,
          orElse: () => MuscleGroup.chest,
        );
      }
    }
    return MuscleGroup.chest;
  }

  List<MuscleGroup> _parseSecondaryMuscles(dynamic heatmap) {
    if (heatmap is Map && heatmap.length > 1) {
      final sorted = heatmap.entries.toList()..sort((a, b) => ((b.value as num?) ?? 0).compareTo((a.value as num?) ?? 0));
      return sorted.skip(1).map((e) => MuscleGroup.values.firstWhere(
        (m) => m.name == e.key,
        orElse: () => MuscleGroup.chest,
      )).toList();
    }
    return [];
  }

  Map<String, double> _parseHeatmap(dynamic heatmap) {
    if (heatmap is Map) {
      return heatmap.map((k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0));
    }
    return {};
  }

  MovementPattern _parseMovementPattern(String value) {
    return MovementPattern.values.firstWhere((m) => m.name == value, orElse: () => MovementPattern.isolation);
  }

  ExerciseType _parseExerciseType(String value) {
    return ExerciseType.values.firstWhere((t) => t.name == value, orElse: () => ExerciseType.compound);
  }

  ExerciseDifficulty _parseDifficulty(String value) {
    return ExerciseDifficulty.values.firstWhere((d) => d.name == value, orElse: () => ExerciseDifficulty.intermediate);
  }

  List<EquipmentType> _parseEquipmentList(dynamic equipment) {
    if (equipment is List) {
      return equipment.map((e) => EquipmentType.values.firstWhere(
        (eq) => eq.name == e.toString(),
        orElse: () => EquipmentType.bodyweight,
      )).toList();
    }
    return [];
  }
}
