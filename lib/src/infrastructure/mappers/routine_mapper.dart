import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper for Exercise entity to/from Firestore (Routine Context)
/// This handles exercises as part of a routine, with sets/reps/notes
class ExerciseMapper {
  /// Convert Firestore map to Exercise entity
  static Exercise fromFirestore(Map<String, dynamic> data) {
    // Parse muscle groups from heatmap or legacy primaryMuscle field
    final heatmapData = data['heatmap'] as Map<String, dynamic>?;
    final heatmap = heatmapData != null 
        ? MuscleHeatmap.fromMap(heatmapData)
        : MuscleHeatmap.empty();

    return Exercise.restore(
      id: ExerciseId(data['id'] as String? ?? ''),
      name: data['name'] as String? ?? 'Sin nombre',
      description: data['description'] as String? ?? '',
      instructions: data['instructions'] as String?,
      imageUrl: data['imageUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      movementPattern: _patternFromString(data['movementPattern'] as String? ?? 'isolation'),
      exerciseType: _typeFromString(data['exerciseType'] as String? ?? 'compound'),
      equipment: (data['equipment'] as List<dynamic>?)
              ?.map((e) => _equipmentFromString(e as String))
              .toList() ?? [EquipmentType.bodyweight],
      difficulty: _difficultyFromString(data['difficulty'] as String? ?? 'beginner'),
      heatmap: heatmap,
      recommendedRepRange: data['recommendedRepRange'] != null 
          ? _repRangeFromString(data['recommendedRepRange'] as String)
          : null,
      estimatedCalories: data['estimatedCalories'] as int?,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      sets: data['sets'] as int? ?? 3,
      reps: data['reps'] as int? ?? 10,
      restSeconds: data['restSeconds'] as int? ?? 60,
      notes: data['notes'] as String?,
    );
  }

  /// Convert Exercise entity to Firestore map
  static Map<String, dynamic> toFirestore(Exercise exercise) {
    return {
      'id': exercise.id.value,
      'name': exercise.name,
      'description': exercise.description,
      'instructions': exercise.instructions,
      'imageUrl': exercise.imageUrl,
      'animationUrl': exercise.animationUrl,
      'videoUrl': exercise.videoUrl,
      'movementPattern': exercise.movementPattern.name,
      'exerciseType': exercise.exerciseType.name,
      'equipment': exercise.equipment.map((e) => e.name).toList(),
      'difficulty': exercise.difficulty.name,
      'heatmap': exercise.heatmap.toMap(),
      'recommendedRepRange': exercise.recommendedRepRange?.name,
      'estimatedCalories': exercise.estimatedCalories,
      'isActive': exercise.isActive,
      'createdAt': exercise.createdAt.toIso8601String(),
      'updatedAt': exercise.updatedAt?.toIso8601String(),
      'sets': exercise.sets,
      'reps': exercise.reps,
      'restSeconds': exercise.restSeconds,
      'notes': exercise.notes,
    };
  }

  static MovementPattern _patternFromString(String value) {
    return MovementPattern.values.firstWhere(
      (p) => p.name == value,
      orElse: () => MovementPattern.isolation,
    );
  }

  static ExerciseType _typeFromString(String value) {
    return ExerciseType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ExerciseType.compound,
    );
  }

  static EquipmentType _equipmentFromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EquipmentType.bodyweight,
    );
  }

  static ExerciseDifficulty _difficultyFromString(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => ExerciseDifficulty.beginner,
    );
  }

  static RepRangeType _repRangeFromString(String value) {
    return RepRangeType.values.firstWhere(
      (r) => r.name == value,
      orElse: () => RepRangeType.hypertrophy,
    );
  }
}

/// Mapper for WorkoutRoutine entity to/from Firestore
class RoutineMapper {
  /// Convert Firestore document to WorkoutRoutine entity
  static WorkoutRoutine fromFirestore(Map<String, dynamic> data, String id) {
    return WorkoutRoutine.restore(
      id: RoutineId(id),
      name: data['name'] as String,
      description: data['description'] as String?,
      difficulty: _difficultyFromString(data['difficulty'] as String),
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseMapper.fromFirestore(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDurationMinutes: data['estimatedDurationMinutes'] as int,
      createdBy: UserId(data['createdBy'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  /// Convert WorkoutRoutine entity to Firestore document
  static Map<String, dynamic> toFirestore(WorkoutRoutine routine) {
    return {
      'name': routine.name,
      'description': routine.description,
      'difficulty': routine.difficulty.name,
      'exercises': routine.exercises.map(ExerciseMapper.toFirestore).toList(),
      'estimatedDurationMinutes': routine.estimatedDurationMinutes,
      'createdBy': routine.createdBy.value,
      'createdAt': routine.createdAt.toIso8601String(),
      'updatedAt': routine.updatedAt?.toIso8601String(),
      'isActive': routine.isActive,
    };
  }

  static DifficultyLevel _difficultyFromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (d) => d.name == value,
      orElse: () => DifficultyLevel.beginner,
    );
  }
}
