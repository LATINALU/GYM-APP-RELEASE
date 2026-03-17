import '../../../../core/types/typedefs.dart';
import '../../entities/exercise.dart';

/// Output Port - Exercise Repository Interface
/// Para acceder al catálogo de ejercicios
abstract class ExerciseRepositoryPort {
  /// Obtener todos los ejercicios del catálogo
  FutureResult<List<ExerciseTemplate>> findAll();
  
  /// Buscar ejercicio por ID
  FutureResult<ExerciseTemplate> findById(String id);
  
  /// Buscar por grupo muscular
  FutureResult<List<ExerciseTemplate>> findByMuscle(MuscleGroup muscle);
  
  /// Buscar por patrón de movimiento
  FutureResult<List<ExerciseTemplate>> findByPattern(MovementPattern pattern);
  
  /// Buscar por equipamiento
  FutureResult<List<ExerciseTemplate>> findByEquipment(EquipmentType equipment);
  
  /// Buscar por dificultad
  FutureResult<List<ExerciseTemplate>> findByDifficulty(ExerciseDifficulty difficulty);
  
  /// Buscar por nombre/texto
  FutureResult<List<ExerciseTemplate>> search(String query);
  
  /// Obtener ejercicios compuestos
  FutureResult<List<ExerciseTemplate>> findCompoundExercises();
  
  /// Obtener ejercicios de aislamiento
  FutureResult<List<ExerciseTemplate>> findIsolationExercises();
}
