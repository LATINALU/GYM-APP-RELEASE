import '../entities/exercise.dart';
import 'leg_exercises.dart';
import 'isolation_exercises.dart';

/// Catálogo completo de ejercicios del gimnasio
/// Organizado por patrón de movimiento
class ExerciseCatalog {
  static final List<ExerciseTemplate> _allExercises = [
    ..._pushExercises,
    ..._pullExercises,
    ...LegExerciseCatalog.exercises,
    ...IsolationExerciseCatalog.exercises,
  ];

  /// Obtener todos los ejercicios
  static List<ExerciseTemplate> get all => List.unmodifiable(_allExercises);

  /// Total de ejercicios
  static int get count => _allExercises.length;

  /// Filtrar por grupo muscular
  static List<ExerciseTemplate> byMuscle(MuscleGroup muscle) =>
      _allExercises.where((e) => 
          e.primaryMuscle == muscle || e.secondaryMuscles.contains(muscle)).toList();

  /// Filtrar por patrón de movimiento
  static List<ExerciseTemplate> byPattern(MovementPattern pattern) =>
      _allExercises.where((e) => e.movementPattern == pattern).toList();

  /// Filtrar por equipamiento
  static List<ExerciseTemplate> byEquipment(EquipmentType equipment) =>
      _allExercises.where((e) => e.equipment.contains(equipment)).toList();

  /// Filtrar por tipo de ejercicio
  static List<ExerciseTemplate> byType(ExerciseType type) =>
      _allExercises.where((e) => e.exerciseType == type).toList();

  /// Filtrar por dificultad
  static List<ExerciseTemplate> byDifficulty(ExerciseDifficulty difficulty) =>
      _allExercises.where((e) => e.difficulty == difficulty).toList();

  /// Ejercicios compuestos
  static List<ExerciseTemplate> get compoundExercises =>
      _allExercises.where((e) => e.exerciseType == ExerciseType.compound).toList();

  /// Ejercicios de aislamiento
  static List<ExerciseTemplate> get isolationExercises =>
      _allExercises.where((e) => e.exerciseType == ExerciseType.isolation).toList();

  /// Buscar por nombre
  static List<ExerciseTemplate> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return _allExercises.where((e) =>
        e.name.toLowerCase().contains(q) ||
        (e.spanishName.toLowerCase().contains(q) ?? false) ||
        e.primaryMuscle.displayName.toLowerCase().contains(q)).toList();
  }

  /// Obtener ejercicio por ID
  static ExerciseTemplate? byId(String id) {
    try {
      return _allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Grupos musculares disponibles
  static List<MuscleGroup> get availableMuscleGroups =>
      MuscleGroup.values.where((m) => 
          _allExercises.any((e) => e.primaryMuscle == m)).toList();

  /// Patrones de movimiento disponibles
  static List<MovementPattern> get availablePatterns =>
      MovementPattern.values.where((p) =>
          _allExercises.any((e) => e.movementPattern == p)).toList();

  // === EJERCICIOS DE EMPUJE ===
  static final List<ExerciseTemplate> _pushExercises = [
    // Press Banca
    const ExerciseTemplate(
      id: 'bench_press_barbell',
      name: 'Barbell Bench Press',
      spanishName: 'Press de Banca con Barra',
      description: 'Ejercicio compuesto principal para pecho.',
      movementPattern: MovementPattern.horizontalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.frontDelts, MuscleGroup.triceps],
      equipment: [EquipmentType.barbell, EquipmentType.bench],
      recommendedRepRanges: [RepRangeType.strength, RepRangeType.hypertrophy],
      requiresSpotter: true,
    ),
    const ExerciseTemplate(
      id: 'bench_press_dumbbell',
      name: 'Dumbbell Bench Press',
      spanishName: 'Press de Banca con Mancuernas',
      description: 'Mayor rango de movimiento que barra.',
      movementPattern: MovementPattern.horizontalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.frontDelts, MuscleGroup.triceps],
      equipment: [EquipmentType.dumbbell, EquipmentType.bench],
    ),
    const ExerciseTemplate(
      id: 'incline_bench_press',
      name: 'Incline Bench Press',
      spanishName: 'Press Inclinado',
      description: 'Énfasis en pecho superior.',
      movementPattern: MovementPattern.horizontalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.frontDelts, MuscleGroup.triceps],
      equipment: [EquipmentType.barbell, EquipmentType.bench],
    ),
    const ExerciseTemplate(
      id: 'chest_dips',
      name: 'Chest Dips',
      spanishName: 'Fondos en Paralelas',
      description: 'Peso corporal para pecho inferior.',
      movementPattern: MovementPattern.horizontalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.frontDelts],
      equipment: [EquipmentType.bodyweight],
    ),
    const ExerciseTemplate(
      id: 'push_ups',
      name: 'Push Ups',
      spanishName: 'Flexiones',
      description: 'Ejercicio básico de empuje.',
      movementPattern: MovementPattern.horizontalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.frontDelts],
      equipment: [EquipmentType.bodyweight],
    ),
    const ExerciseTemplate(
      id: 'overhead_press_barbell',
      name: 'Overhead Press',
      spanishName: 'Press Militar con Barra',
      description: 'Empuje vertical principal.',
      movementPattern: MovementPattern.verticalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.frontDelts,
      secondaryMuscles: [MuscleGroup.sideDelts, MuscleGroup.triceps, MuscleGroup.traps],
      equipment: [EquipmentType.barbell],
      recommendedRepRanges: [RepRangeType.strength, RepRangeType.hypertrophy],
    ),
    const ExerciseTemplate(
      id: 'overhead_press_dumbbell',
      name: 'Dumbbell Shoulder Press',
      spanishName: 'Press de Hombros con Mancuernas',
      description: 'Mayor rango de movimiento.',
      movementPattern: MovementPattern.verticalPush,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.frontDelts,
      secondaryMuscles: [MuscleGroup.sideDelts, MuscleGroup.triceps],
      equipment: [EquipmentType.dumbbell],
    ),
  ];

  // === EJERCICIOS DE TRACCIÓN ===
  static final List<ExerciseTemplate> _pullExercises = [
    const ExerciseTemplate(
      id: 'pull_ups',
      name: 'Pull Ups',
      spanishName: 'Dominadas',
      description: 'Tracción vertical principal.',
      movementPattern: MovementPattern.verticalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.lats,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.upperBack, MuscleGroup.rearDelts],
      equipment: [EquipmentType.pullupBar],
    ),
    const ExerciseTemplate(
      id: 'chin_ups',
      name: 'Chin Ups',
      spanishName: 'Dominadas Supinas',
      description: 'Mayor énfasis en bíceps.',
      movementPattern: MovementPattern.verticalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.lats,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.upperBack],
      equipment: [EquipmentType.pullupBar],
    ),
    const ExerciseTemplate(
      id: 'lat_pulldown',
      name: 'Lat Pulldown',
      spanishName: 'Jalón al Pecho',
      description: 'Alternativa a dominadas.',
      movementPattern: MovementPattern.verticalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.lats,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.upperBack],
      equipment: [EquipmentType.cable],
    ),
    const ExerciseTemplate(
      id: 'barbell_row',
      name: 'Barbell Row',
      spanishName: 'Remo con Barra',
      description: 'Tracción horizontal principal.',
      movementPattern: MovementPattern.horizontalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.intermediate,
      primaryMuscle: MuscleGroup.upperBack,
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps, MuscleGroup.rearDelts],
      equipment: [EquipmentType.barbell],
      recommendedRepRanges: [RepRangeType.strength, RepRangeType.hypertrophy],
    ),
    const ExerciseTemplate(
      id: 'dumbbell_row',
      name: 'Dumbbell Row',
      spanishName: 'Remo con Mancuerna',
      description: 'Remo unilateral.',
      movementPattern: MovementPattern.horizontalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.upperBack,
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
      equipment: [EquipmentType.dumbbell, EquipmentType.bench],
      isUnilateral: true,
    ),
    const ExerciseTemplate(
      id: 'cable_row',
      name: 'Seated Cable Row',
      spanishName: 'Remo Sentado en Polea',
      description: 'Tensión constante.',
      movementPattern: MovementPattern.horizontalPull,
      exerciseType: ExerciseType.compound,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.upperBack,
      secondaryMuscles: [MuscleGroup.lats, MuscleGroup.biceps],
      equipment: [EquipmentType.cable],
    ),
    const ExerciseTemplate(
      id: 'face_pull',
      name: 'Face Pull',
      spanishName: 'Tirón Facial',
      description: 'Deltoides posterior y salud de hombros.',
      movementPattern: MovementPattern.horizontalPull,
      exerciseType: ExerciseType.accessory,
      difficulty: ExerciseDifficulty.beginner,
      primaryMuscle: MuscleGroup.rearDelts,
      secondaryMuscles: [MuscleGroup.traps, MuscleGroup.upperBack],
      equipment: [EquipmentType.cable],
      recommendedRepRanges: [RepRangeType.hypertrophy, RepRangeType.endurance],
    ),
  ];
}
