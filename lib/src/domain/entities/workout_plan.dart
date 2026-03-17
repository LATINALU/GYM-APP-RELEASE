/// Workout Plan - Weekly routine planning system
import 'package:equatable/equatable.dart';

/// Day of week enum
enum WeekDay {
  monday('Lunes', 'L'),
  tuesday('Martes', 'M'),
  wednesday('Miércoles', 'X'),
  thursday('Jueves', 'J'),
  friday('Viernes', 'V'),
  saturday('Sábado', 'S'),
  sunday('Domingo', 'D');

  final String displayName;
  final String shortName;
  const WeekDay(this.displayName, this.shortName);

  static WeekDay fromDateTime(DateTime date) {
    return WeekDay.values[date.weekday - 1];
  }
}

/// Planned exercise within a routine day
class PlannedExercise extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int targetSets;
  final String targetReps; // e.g., "8-12", "5", "12-15"
  final double? suggestedWeight;
  final String? notes;
  final int order;
  final bool isOptional;

  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.targetSets,
    required this.targetReps,
    this.suggestedWeight,
    this.notes,
    required this.order,
    this.isOptional = false,
  });

  @override
  List<Object?> get props => [exerciseId, targetSets, targetReps, order];

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'muscleGroup': muscleGroup,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'suggestedWeight': suggestedWeight,
    'notes': notes,
    'order': order,
    'isOptional': isOptional,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) => PlannedExercise(
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    muscleGroup: json['muscleGroup'],
    targetSets: json['targetSets'],
    targetReps: json['targetReps'],
    suggestedWeight: json['suggestedWeight']?.toDouble(),
    notes: json['notes'],
    order: json['order'],
    isOptional: json['isOptional'] ?? false,
  );
}

/// A workout day within the weekly plan
class WorkoutDay extends Equatable {
  final WeekDay day;
  final String name; // e.g., "Piernas", "Push", "Cardio"
  final String? description;
  final List<PlannedExercise> exercises;
  final int estimatedDuration; // minutes
  final bool isRestDay;

  const WorkoutDay({
    required this.day,
    required this.name,
    this.description,
    required this.exercises,
    required this.estimatedDuration,
    this.isRestDay = false,
  });

  /// Total sets for this day
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.targetSets);

  /// Muscle groups targeted
  Set<String> get muscleGroups => exercises.map((e) => e.muscleGroup).toSet();

  /// Exercise count
  int get exerciseCount => exercises.length;

  @override
  List<Object?> get props => [day, name, exercises, isRestDay];

  Map<String, dynamic> toJson() => {
    'day': day.name,
    'name': name,
    'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'estimatedDuration': estimatedDuration,
    'isRestDay': isRestDay,
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
    day: WeekDay.values.firstWhere((d) => d.name == json['day']),
    name: json['name'],
    description: json['description'],
    exercises: (json['exercises'] as List).map((e) => PlannedExercise.fromJson(e)).toList(),
    estimatedDuration: json['estimatedDuration'],
    isRestDay: json['isRestDay'] ?? false,
  );

  /// Create rest day
  factory WorkoutDay.restDay(WeekDay day) => WorkoutDay(
    day: day,
    name: 'Descanso',
    description: 'Día de recuperación',
    exercises: [],
    estimatedDuration: 0,
    isRestDay: true,
  );
}

/// Difficulty level of the plan
enum PlanDifficulty {
  beginner('Principiante', '🟢'),
  intermediate('Intermedio', '🟡'),
  advanced('Avanzado', '🔴');

  final String displayName;
  final String indicator;
  const PlanDifficulty(this.displayName, this.indicator);
}

/// Plan goal focus
enum PlanFocus {
  strength('Fuerza', '🏋️'),
  hypertrophy('Hipertrofia', '💪'),
  endurance('Resistencia', '🏃'),
  fatLoss('Pérdida de grasa', '🔥'),
  general('Acondicionamiento', '⚡');

  final String displayName;
  final String icon;
  const PlanFocus(this.displayName, this.icon);
}

/// Complete workout plan
class WorkoutPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? authorId;
  final String? authorName;
  final List<WorkoutDay> weeklySchedule;
  final PlanDifficulty difficulty;
  final PlanFocus focus;
  final int weeksToComplete; // 0 = indefinite
  final bool isActive;
  final DateTime createdAt;
  final DateTime? startDate;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    this.authorId,
    this.authorName,
    required this.weeklySchedule,
    required this.difficulty,
    required this.focus,
    this.weeksToComplete = 0,
    this.isActive = false,
    required this.createdAt,
    this.startDate,
  });

  /// Training days per week
  int get daysPerWeek => weeklySchedule.where((d) => !d.isRestDay).length;

  /// Rest days per week
  int get restDaysPerWeek => weeklySchedule.where((d) => d.isRestDay).length;

  /// Get today's workout
  WorkoutDay? get todaysWorkout {
    final today = WeekDay.fromDateTime(DateTime.now());
    return weeklySchedule.firstWhere(
      (d) => d.day == today,
      orElse: () => WorkoutDay.restDay(today),
    );
  }

  /// Get next workout day
  WorkoutDay? get nextWorkout {
    final today = WeekDay.fromDateTime(DateTime.now());
    final todayIndex = today.index;
    
    // Look for next non-rest day
    for (int i = 1; i <= 7; i++) {
      final checkIndex = (todayIndex + i) % 7;
      final day = weeklySchedule.firstWhere(
        (d) => d.day.index == checkIndex && !d.isRestDay,
        orElse: () => WorkoutDay.restDay(WeekDay.values[checkIndex]),
      );
      if (!day.isRestDay) return day;
    }
    return null;
  }

  /// Total exercises across all days
  int get totalExercises => weeklySchedule.fold(0, (sum, d) => sum + d.exerciseCount);

  /// Total estimated weekly time (minutes)
  int get weeklyTimeEstimate => weeklySchedule.fold(0, (sum, d) => sum + d.estimatedDuration);

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    String? authorId,
    String? authorName,
    List<WorkoutDay>? weeklySchedule,
    PlanDifficulty? difficulty,
    PlanFocus? focus,
    int? weeksToComplete,
    bool? isActive,
    DateTime? createdAt,
    DateTime? startDate,
  }) => WorkoutPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    weeklySchedule: weeklySchedule ?? this.weeklySchedule,
    difficulty: difficulty ?? this.difficulty,
    focus: focus ?? this.focus,
    weeksToComplete: weeksToComplete ?? this.weeksToComplete,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    startDate: startDate ?? this.startDate,
  );

  @override
  List<Object?> get props => [id, name, weeklySchedule, difficulty, focus, isActive];

  /// Create predefined PPL (Push/Pull/Legs) routine
  factory WorkoutPlan.ppl() => WorkoutPlan(
    id: 'ppl-default',
    name: 'Push Pull Legs',
    description: 'Rutina clásica de 6 días dividida en empuje, tirón y piernas',
    weeklySchedule: [
      const WorkoutDay(
        day: WeekDay.monday,
        name: 'Push (Pecho, Hombros, Tríceps)',
        estimatedDuration: 75,
        exercises: [
          PlannedExercise(exerciseId: 'bench_press', exerciseName: 'Press de Banca', muscleGroup: 'Pecho', targetSets: 4, targetReps: '6-8', order: 0),
          PlannedExercise(exerciseId: 'ohp', exerciseName: 'Press Militar', muscleGroup: 'Hombros', targetSets: 4, targetReps: '8-10', order: 1),
          PlannedExercise(exerciseId: 'incline_db_press', exerciseName: 'Press Inclinado Mancuernas', muscleGroup: 'Pecho', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'lateral_raise', exerciseName: 'Elevaciones Laterales', muscleGroup: 'Hombros', targetSets: 3, targetReps: '12-15', order: 3),
          PlannedExercise(exerciseId: 'tricep_pushdown', exerciseName: 'Extensiones Tríceps', muscleGroup: 'Tríceps', targetSets: 3, targetReps: '10-12', order: 4),
          PlannedExercise(exerciseId: 'overhead_extension', exerciseName: 'Extensión Overhead', muscleGroup: 'Tríceps', targetSets: 3, targetReps: '12-15', order: 5),
        ],
      ),
      const WorkoutDay(
        day: WeekDay.tuesday,
        name: 'Pull (Espalda, Bíceps)',
        estimatedDuration: 70,
        exercises: [
          PlannedExercise(exerciseId: 'deadlift', exerciseName: 'Peso Muerto', muscleGroup: 'Espalda', targetSets: 4, targetReps: '5', order: 0),
          PlannedExercise(exerciseId: 'pullups', exerciseName: 'Dominadas', muscleGroup: 'Espalda', targetSets: 4, targetReps: '6-10', order: 1),
          PlannedExercise(exerciseId: 'barbell_row', exerciseName: 'Remo con Barra', muscleGroup: 'Espalda', targetSets: 4, targetReps: '8-10', order: 2),
          PlannedExercise(exerciseId: 'face_pull', exerciseName: 'Face Pull', muscleGroup: 'Espalda', targetSets: 3, targetReps: '15-20', order: 3),
          PlannedExercise(exerciseId: 'barbell_curl', exerciseName: 'Curl con Barra', muscleGroup: 'Bíceps', targetSets: 3, targetReps: '10-12', order: 4),
          PlannedExercise(exerciseId: 'hammer_curl', exerciseName: 'Curl Martillo', muscleGroup: 'Bíceps', targetSets: 3, targetReps: '12-15', order: 5),
        ],
      ),
      const WorkoutDay(
        day: WeekDay.wednesday,
        name: 'Legs (Piernas)',
        estimatedDuration: 80,
        exercises: [
          PlannedExercise(exerciseId: 'squat', exerciseName: 'Sentadilla', muscleGroup: 'Cuádriceps', targetSets: 4, targetReps: '6-8', order: 0),
          PlannedExercise(exerciseId: 'rdl', exerciseName: 'Peso Muerto Rumano', muscleGroup: 'Isquiotibiales', targetSets: 4, targetReps: '8-10', order: 1),
          PlannedExercise(exerciseId: 'leg_press', exerciseName: 'Prensa de Piernas', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'leg_curl', exerciseName: 'Curl Femoral', muscleGroup: 'Isquiotibiales', targetSets: 3, targetReps: '10-12', order: 3),
          PlannedExercise(exerciseId: 'calf_raise', exerciseName: 'Elevación de Gemelos', muscleGroup: 'Gemelos', targetSets: 4, targetReps: '15-20', order: 4),
        ],
      ),
      const WorkoutDay(
        day: WeekDay.thursday,
        name: 'Push (Pecho, Hombros, Tríceps)',
        estimatedDuration: 70,
        exercises: [
          PlannedExercise(exerciseId: 'incline_bench', exerciseName: 'Press Inclinado Barra', muscleGroup: 'Pecho', targetSets: 4, targetReps: '8-10', order: 0),
          PlannedExercise(exerciseId: 'db_ohp', exerciseName: 'Press Militar Mancuernas', muscleGroup: 'Hombros', targetSets: 4, targetReps: '10-12', order: 1),
          PlannedExercise(exerciseId: 'cable_fly', exerciseName: 'Cruces en Polea', muscleGroup: 'Pecho', targetSets: 3, targetReps: '12-15', order: 2),
          PlannedExercise(exerciseId: 'rear_delt_fly', exerciseName: 'Pájaros', muscleGroup: 'Hombros', targetSets: 3, targetReps: '15-20', order: 3),
          PlannedExercise(exerciseId: 'dips', exerciseName: 'Fondos', muscleGroup: 'Tríceps', targetSets: 3, targetReps: '8-12', order: 4),
        ],
      ),
      const WorkoutDay(
        day: WeekDay.friday,
        name: 'Pull (Espalda, Bíceps)',
        estimatedDuration: 65,
        exercises: [
          PlannedExercise(exerciseId: 'weighted_pullups', exerciseName: 'Dominadas Lastradas', muscleGroup: 'Espalda', targetSets: 4, targetReps: '6-8', order: 0),
          PlannedExercise(exerciseId: 'cable_row', exerciseName: 'Remo en Polea', muscleGroup: 'Espalda', targetSets: 4, targetReps: '10-12', order: 1),
          PlannedExercise(exerciseId: 'lat_pulldown', exerciseName: 'Jalón al Pecho', muscleGroup: 'Espalda', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'incline_curl', exerciseName: 'Curl Inclinado', muscleGroup: 'Bíceps', targetSets: 3, targetReps: '10-12', order: 3),
          PlannedExercise(exerciseId: 'concentration_curl', exerciseName: 'Curl Concentración', muscleGroup: 'Bíceps', targetSets: 2, targetReps: '15', order: 4),
        ],
      ),
      const WorkoutDay(
        day: WeekDay.saturday,
        name: 'Legs (Piernas)',
        estimatedDuration: 75,
        exercises: [
          PlannedExercise(exerciseId: 'front_squat', exerciseName: 'Sentadilla Frontal', muscleGroup: 'Cuádriceps', targetSets: 4, targetReps: '8-10', order: 0),
          PlannedExercise(exerciseId: 'bulgarian_split_squat', exerciseName: 'Zancadas Búlgaras', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '10-12', order: 1),
          PlannedExercise(exerciseId: 'stiff_leg_deadlift', exerciseName: 'Peso Muerto Piernas Rígidas', muscleGroup: 'Isquiotibiales', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'leg_extension', exerciseName: 'Extensión de Piernas', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '12-15', order: 3),
          PlannedExercise(exerciseId: 'seated_calf_raise', exerciseName: 'Gemelos Sentado', muscleGroup: 'Gemelos', targetSets: 4, targetReps: '15-20', order: 4),
        ],
      ),
      WorkoutDay.restDay(WeekDay.sunday),
    ],
    difficulty: PlanDifficulty.intermediate,
    focus: PlanFocus.hypertrophy,
    weeksToComplete: 0,
    createdAt: DateTime.now(),
  );

  /// Create a beginner full body routine
  factory WorkoutPlan.beginnerFullBody() => WorkoutPlan(
    id: 'beginner-fullbody',
    name: 'Full Body Principiante',
    description: 'Rutina de 3 días perfecta para empezar. Trabaja todo el cuerpo cada sesión.',
    weeklySchedule: [
      const WorkoutDay(
        day: WeekDay.monday,
        name: 'Full Body A',
        estimatedDuration: 60,
        exercises: [
          PlannedExercise(exerciseId: 'squat', exerciseName: 'Sentadilla', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '8-10', order: 0),
          PlannedExercise(exerciseId: 'bench_press', exerciseName: 'Press de Banca', muscleGroup: 'Pecho', targetSets: 3, targetReps: '8-10', order: 1),
          PlannedExercise(exerciseId: 'barbell_row', exerciseName: 'Remo con Barra', muscleGroup: 'Espalda', targetSets: 3, targetReps: '8-10', order: 2),
          PlannedExercise(exerciseId: 'ohp', exerciseName: 'Press Militar', muscleGroup: 'Hombros', targetSets: 3, targetReps: '10-12', order: 3),
          PlannedExercise(exerciseId: 'plank', exerciseName: 'Plancha', muscleGroup: 'Core', targetSets: 3, targetReps: '30-60s', order: 4),
        ],
      ),
      WorkoutDay.restDay(WeekDay.tuesday),
      const WorkoutDay(
        day: WeekDay.wednesday,
        name: 'Full Body B',
        estimatedDuration: 60,
        exercises: [
          PlannedExercise(exerciseId: 'deadlift', exerciseName: 'Peso Muerto', muscleGroup: 'Espalda', targetSets: 3, targetReps: '5-6', order: 0),
          PlannedExercise(exerciseId: 'incline_db_press', exerciseName: 'Press Inclinado', muscleGroup: 'Pecho', targetSets: 3, targetReps: '10-12', order: 1),
          PlannedExercise(exerciseId: 'lat_pulldown', exerciseName: 'Jalón al Pecho', muscleGroup: 'Espalda', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'lunges', exerciseName: 'Zancadas', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '10/pierna', order: 3),
          PlannedExercise(exerciseId: 'bicep_curl', exerciseName: 'Curl Bíceps', muscleGroup: 'Bíceps', targetSets: 2, targetReps: '12-15', order: 4),
        ],
      ),
      WorkoutDay.restDay(WeekDay.thursday),
      const WorkoutDay(
        day: WeekDay.friday,
        name: 'Full Body C',
        estimatedDuration: 60,
        exercises: [
          PlannedExercise(exerciseId: 'leg_press', exerciseName: 'Prensa de Piernas', muscleGroup: 'Cuádriceps', targetSets: 3, targetReps: '10-12', order: 0),
          PlannedExercise(exerciseId: 'db_bench', exerciseName: 'Press Mancuernas', muscleGroup: 'Pecho', targetSets: 3, targetReps: '10-12', order: 1),
          PlannedExercise(exerciseId: 'cable_row', exerciseName: 'Remo en Polea', muscleGroup: 'Espalda', targetSets: 3, targetReps: '10-12', order: 2),
          PlannedExercise(exerciseId: 'lateral_raise', exerciseName: 'Elevaciones Laterales', muscleGroup: 'Hombros', targetSets: 3, targetReps: '12-15', order: 3),
          PlannedExercise(exerciseId: 'tricep_pushdown', exerciseName: 'Extensiones Tríceps', muscleGroup: 'Tríceps', targetSets: 2, targetReps: '12-15', order: 4),
        ],
      ),
      WorkoutDay.restDay(WeekDay.saturday),
      WorkoutDay.restDay(WeekDay.sunday),
    ],
    difficulty: PlanDifficulty.beginner,
    focus: PlanFocus.general,
    weeksToComplete: 8,
    createdAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'authorId': authorId,
    'authorName': authorName,
    'weeklySchedule': weeklySchedule.map((d) => d.toJson()).toList(),
    'difficulty': difficulty.name,
    'focus': focus.name,
    'weeksToComplete': weeksToComplete,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    authorId: json['authorId'],
    authorName: json['authorName'],
    weeklySchedule: (json['weeklySchedule'] as List).map((d) => WorkoutDay.fromJson(d)).toList(),
    difficulty: PlanDifficulty.values.firstWhere((d) => d.name == json['difficulty']),
    focus: PlanFocus.values.firstWhere((f) => f.name == json['focus']),
    weeksToComplete: json['weeksToComplete'] ?? 0,
    isActive: json['isActive'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
  );
}
