import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';
import 'exercise.dart';
import 'user.dart';
import '../../../core/errors/exceptions.dart';

/// Difficulty level for routines
enum DifficultyLevel {
  beginner,     // Principiante
  intermediate, // Intermedio
  advanced,     // Avanzado
}

extension DifficultyLevelX on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Principiante';
      case DifficultyLevel.intermediate:
        return 'Intermedio';
      case DifficultyLevel.advanced:
        return 'Avanzado';
    }
  }

  int get level {
    switch (this) {
      case DifficultyLevel.beginner:
        return 1;
      case DifficultyLevel.intermediate:
        return 2;
      case DifficultyLevel.advanced:
        return 3;
    }
  }
}

/// Workout Routine Entity - Collection of exercises
class WorkoutRoutine extends Equatable {
  final RoutineId id;
  final String name;
  final String? description;
  final DifficultyLevel difficulty;
  final List<Exercise> exercises;
  final int estimatedDurationMinutes;
  final UserId createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const WorkoutRoutine._({
    required this.id,
    required this.name,
    this.description,
    required this.difficulty,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create new routine
  factory WorkoutRoutine.create({
    required String name,
    String? description,
    required DifficultyLevel difficulty,
    List<Exercise> exercises = const [],
    int? estimatedDurationMinutes,
    required UserId createdBy,
  }) {
    if (name.trim().isEmpty) {
      throw const DomainException(
        'El nombre de la rutina es requerido',
        code: 'INVALID_ROUTINE_NAME',
      );
    }
    if (name.length > 100) {
      throw const DomainException(
        'El nombre de la rutina no puede exceder 100 caracteres',
        code: 'INVALID_ROUTINE_NAME',
      );
    }

    return WorkoutRoutine._(
      id: RoutineId.generate(),
      name: name.trim(),
      description: description?.trim(),
      difficulty: difficulty,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDurationMinutes ?? _calculateDuration(exercises),
      createdBy: createdBy,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  /// Restore from persistence
  factory WorkoutRoutine.restore({
    required RoutineId id,
    required String name,
    String? description,
    required DifficultyLevel difficulty,
    required List<Exercise> exercises,
    required int estimatedDurationMinutes,
    required UserId createdBy,
    required DateTime createdAt,
    DateTime? updatedAt,
    bool isActive = true,
  }) {
    return WorkoutRoutine._(
      id: id,
      name: name,
      description: description,
      difficulty: difficulty,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDurationMinutes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  // === BEHAVIOR METHODS ===

  /// Add exercise to routine
  WorkoutRoutine addExercise(Exercise exercise) {
    final newExercises = [...exercises, exercise];
    return _copyWith(
      exercises: newExercises,
      estimatedDurationMinutes: _calculateDuration(newExercises),
      updatedAt: DateTime.now(),
    );
  }

  /// Remove exercise from routine
  WorkoutRoutine removeExercise(ExerciseId exerciseId) {
    final newExercises = exercises.where((e) => e.id != exerciseId).toList();
    return _copyWith(
      exercises: newExercises,
      estimatedDurationMinutes: _calculateDuration(newExercises),
      updatedAt: DateTime.now(),
    );
  }

  /// Update routine info
  WorkoutRoutine updateInfo({
    String? name,
    String? description,
    DifficultyLevel? difficulty,
  }) {
    return _copyWith(
      name: name,
      description: description,
      difficulty: difficulty,
      updatedAt: DateTime.now(),
    );
  }

  /// Deactivate routine
  WorkoutRoutine deactivate() {
    return _copyWith(isActive: false, updatedAt: DateTime.now());
  }

  /// Activate routine
  WorkoutRoutine activate() {
    return _copyWith(isActive: true, updatedAt: DateTime.now());
  }

  /// Public copyWith for routine updates
  WorkoutRoutine copyWith({
    String? name,
    String? description,
    DifficultyLevel? difficulty,
    List<Exercise>? exercises,
    int? estimatedDurationMinutes,
    bool? isActive,
  }) {
    return _copyWith(
      name: name,
      description: description,
      difficulty: difficulty,
      exercises: exercises,
      estimatedDurationMinutes: estimatedDurationMinutes,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if routine is suitable for a client based on experience
  bool isSuitableFor(User client) {
    // If client has no previous history, only beginner routines
    // This could be expanded based on client fitness level
    return true; // For MVP, allow all
  }

  // === COMPUTED PROPERTIES ===

  /// Total exercise count
  int get exerciseCount => exercises.length;

  /// Formatted duration display
  String get durationDisplay => '$estimatedDurationMinutes min';

  /// All muscle groups targeted
  Set<MuscleGroup> get targetedMuscles {
    return exercises.expand((e) => e.allMuscles).toSet();
  }

  /// Has any exercises
  bool get hasExercises => exercises.isNotEmpty;

  static int _calculateDuration(List<Exercise> exercises) {
    if (exercises.isEmpty) return 0;
    // Estimate: 2 min per set + rest time
    int total = 0;
    for (final exercise in exercises) {
      total += exercise.sets * 2; // 2 min per set average
      total += (exercise.restSeconds ?? 60) * (exercise.sets - 1) ~/ 60;
    }
    return total.clamp(10, 180);
  }

  WorkoutRoutine _copyWith({
    String? name,
    String? description,
    DifficultyLevel? difficulty,
    List<Exercise>? exercises,
    int? estimatedDurationMinutes,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return WorkoutRoutine._(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      'WorkoutRoutine($name, ${difficulty.displayName}, $exerciseCount exercises)';
}
