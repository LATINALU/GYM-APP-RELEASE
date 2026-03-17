/// Workout Session - Complete workout logging system
import 'package:equatable/equatable.dart';

/// A single set within an exercise
class ExerciseSet extends Equatable {
  final int setNumber;
  final int reps;
  final double weight; // kg
  final Duration? restTime;
  final bool isWarmup;
  final bool isDropSet;
  final bool isFailure;
  final String? notes;
  final DateTime timestamp;

  const ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.restTime,
    this.isWarmup = false,
    this.isDropSet = false,
    this.isFailure = false,
    this.notes,
    required this.timestamp,
  });

  /// Calculate volume (weight x reps)
  double get volume => weight * reps;

  /// Calculate estimated 1RM
  double get estimated1RM => weight * (36 / (37 - reps));

  ExerciseSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    Duration? restTime,
    bool? isWarmup,
    bool? isDropSet,
    bool? isFailure,
    String? notes,
    DateTime? timestamp,
  }) => ExerciseSet(
    setNumber: setNumber ?? this.setNumber,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    restTime: restTime ?? this.restTime,
    isWarmup: isWarmup ?? this.isWarmup,
    isDropSet: isDropSet ?? this.isDropSet,
    isFailure: isFailure ?? this.isFailure,
    notes: notes ?? this.notes,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  List<Object?> get props => [setNumber, reps, weight, isWarmup, isDropSet, isFailure, timestamp];

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'restTime': restTime?.inSeconds,
    'isWarmup': isWarmup,
    'isDropSet': isDropSet,
    'isFailure': isFailure,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    setNumber: json['setNumber'],
    reps: json['reps'],
    weight: json['weight'].toDouble(),
    restTime: json['restTime'] != null ? Duration(seconds: json['restTime']) : null,
    isWarmup: json['isWarmup'] ?? false,
    isDropSet: json['isDropSet'] ?? false,
    isFailure: json['isFailure'] ?? false,
    notes: json['notes'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Exercise log within a workout session
class ExerciseLog extends Equatable {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final List<ExerciseSet> sets;
  final String? notes;
  final int order;

  const ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    this.notes,
    required this.order,
  });

  /// Total volume for this exercise
  double get totalVolume => sets.where((s) => !s.isWarmup).fold(0, (sum, s) => sum + s.volume);

  /// Working sets count (excluding warmup)
  int get workingSetsCount => sets.where((s) => !s.isWarmup).length;

  /// Best set (highest weight with at least 1 rep)
  ExerciseSet? get bestSet {
    final workingSets = sets.where((s) => !s.isWarmup && s.reps > 0).toList();
    if (workingSets.isEmpty) return null;
    workingSets.sort((a, b) => b.weight.compareTo(a.weight));
    return workingSets.first;
  }

  /// Average weight across working sets
  double get averageWeight {
    final workingSets = sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) return 0;
    return workingSets.fold(0.0, (sum, s) => sum + s.weight) / workingSets.length;
  }

  /// Total reps
  int get totalReps => sets.where((s) => !s.isWarmup).fold(0, (sum, s) => sum + s.reps);

  ExerciseLog copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    List<ExerciseSet>? sets,
    String? notes,
    int? order,
  }) => ExerciseLog(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    sets: sets ?? this.sets,
    notes: notes ?? this.notes,
    order: order ?? this.order,
  );

  @override
  List<Object?> get props => [id, exerciseId, sets, order];

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'muscleGroup': muscleGroup,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
    'order': order,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    id: json['id'],
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    muscleGroup: json['muscleGroup'],
    sets: (json['sets'] as List).map((s) => ExerciseSet.fromJson(s)).toList(),
    notes: json['notes'],
    order: json['order'],
  );
}

/// Workout session status
enum WorkoutStatus {
  planned('Planificado'),
  inProgress('En Progreso'),
  completed('Completado'),
  skipped('Omitido');

  final String displayName;
  const WorkoutStatus(this.displayName);
}

/// Complete workout session
class WorkoutSession extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final WorkoutStatus status;
  final List<ExerciseLog> exercises;
  final String? notes;
  final int? rating; // 1-5
  final double? bodyWeight; // at time of workout
  final String? routineId; // if part of a routine

  const WorkoutSession({
    required this.id,
    required this.name,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    required this.exercises,
    this.notes,
    this.rating,
    this.bodyWeight,
    this.routineId,
  });

  /// Duration of the workout
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }

  /// Total volume in kg
  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.totalVolume);

  /// Total sets
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.workingSetsCount);

  /// Total reps
  int get totalReps => exercises.fold(0, (sum, e) => sum + e.totalReps);

  /// Exercises count
  int get exerciseCount => exercises.length;

  /// Muscle groups worked
  Set<String> get muscleGroups => exercises.map((e) => e.muscleGroup).toSet();

  /// Estimated calories burned (rough estimate)
  int get estimatedCalories {
    final durationMinutes = duration?.inMinutes ?? 60;
    // Rough estimate: 5-8 cal/min for weight training
    return (durationMinutes * 6.5).round();
  }

  /// Is workout active (in progress)
  bool get isActive => status == WorkoutStatus.inProgress;

  /// Is workout completed
  bool get isCompleted => status == WorkoutStatus.completed;

  WorkoutSession copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    WorkoutStatus? status,
    List<ExerciseLog>? exercises,
    String? notes,
    int? rating,
    double? bodyWeight,
    String? routineId,
  }) => WorkoutSession(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    exercises: exercises ?? this.exercises,
    notes: notes ?? this.notes,
    rating: rating ?? this.rating,
    bodyWeight: bodyWeight ?? this.bodyWeight,
    routineId: routineId ?? this.routineId,
  );

  @override
  List<Object?> get props => [id, name, date, status, exercises];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'date': date.toIso8601String(),
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'status': status.name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'notes': notes,
    'rating': rating,
    'bodyWeight': bodyWeight,
    'routineId': routineId,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    status: WorkoutStatus.values.firstWhere((s) => s.name == json['status']),
    exercises: (json['exercises'] as List).map((e) => ExerciseLog.fromJson(e)).toList(),
    notes: json['notes'],
    rating: json['rating'],
    bodyWeight: json['bodyWeight']?.toDouble(),
    routineId: json['routineId'],
  );

  /// Create empty workout for starting
  factory WorkoutSession.start({
    required String name,
    String? description,
    String? routineId,
    double? bodyWeight,
  }) => WorkoutSession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    description: description,
    date: DateTime.now(),
    startTime: DateTime.now(),
    status: WorkoutStatus.inProgress,
    exercises: [],
    routineId: routineId,
    bodyWeight: bodyWeight,
  );

}
