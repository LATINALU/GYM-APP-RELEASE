import '../entities/exercise.dart';
import 'dataset_exercise_catalog.dart';

/// Catálogo de ejercicios del gimnasio
///
/// Fachada sobre [DatasetExerciseCatalog]: los 1,324 ejercicios del dataset
/// (diseño uniforme de Gym visual, instrucciones en español, media offline).
/// El catálogo estático anterior fue eliminado tras la purga de rutinas
/// antiguas (migración jul-2026).
class ExerciseCatalog {
  ExerciseCatalog._();

  static List<ExerciseTemplate> get _allExercises =>
      DatasetExerciseCatalog.exercises;

  /// Obtener todos los ejercicios
  static List<ExerciseTemplate> get all => _allExercises;

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
        e.spanishName.toLowerCase().contains(q) ||
        e.primaryMuscle.displayName.toLowerCase().contains(q)).toList();
  }

  /// Obtener ejercicio por ID (`ds_XXXX`); acepta también el nombre exacto
  /// como fallback para ejercicios persistidos sin templateId
  static ExerciseTemplate? byId(String id) {
    for (final e in _allExercises) {
      if (e.id == id) return e;
    }
    final byName = DatasetExerciseCatalog.templateIdForName(id);
    if (byName != null) {
      for (final e in _allExercises) {
        if (e.id == byName) return e;
      }
    }
    return null;
  }

  /// Grupos musculares disponibles
  static List<MuscleGroup> get availableMuscleGroups =>
      MuscleGroup.values.where((m) =>
          _allExercises.any((e) => e.primaryMuscle == m)).toList();

  /// Patrones de movimiento disponibles
  static List<MovementPattern> get availablePatterns =>
      MovementPattern.values.where((p) =>
          _allExercises.any((e) => e.movementPattern == p)).toList();
}
