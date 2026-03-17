import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/data/exercise_catalog.dart';
import '../../../domain/ports/output/exercise_repository_port.dart';

/// Implementación del repositorio de ejercicios
/// Usa el catálogo estático de ejercicios por ahora
/// En el futuro puede conectarse a Firestore para ejercicios personalizados
class LocalExerciseRepository implements ExerciseRepositoryPort {
  
  @override
  FutureResult<List<ExerciseTemplate>> findAll() async {
    try {
      return right(ExerciseCatalog.all);
    } catch (e) {
      return left(ServerFailure(message: 'Error al obtener ejercicios: $e'));
    }
  }

  @override
  FutureResult<ExerciseTemplate> findById(String id) async {
    try {
      final exercise = ExerciseCatalog.byId(id);
      if (exercise == null) {
        return left(const ValidationFailure(message: 'Ejercicio no encontrado'));
      }
      return right(exercise);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar ejercicio: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByMuscle(MuscleGroup muscle) async {
    try {
      return right(ExerciseCatalog.byMuscle(muscle));
    } catch (e) {
      return left(ServerFailure(message: 'Error al filtrar por músculo: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByPattern(MovementPattern pattern) async {
    try {
      return right(ExerciseCatalog.byPattern(pattern));
    } catch (e) {
      return left(ServerFailure(message: 'Error al filtrar por patrón: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByEquipment(EquipmentType equipment) async {
    try {
      return right(ExerciseCatalog.byEquipment(equipment));
    } catch (e) {
      return left(ServerFailure(message: 'Error al filtrar por equipamiento: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findByDifficulty(ExerciseDifficulty difficulty) async {
    try {
      return right(ExerciseCatalog.byDifficulty(difficulty));
    } catch (e) {
      return left(ServerFailure(message: 'Error al filtrar por dificultad: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> search(String query) async {
    try {
      return right(ExerciseCatalog.search(query));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findCompoundExercises() async {
    try {
      return right(ExerciseCatalog.compoundExercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error: $e'));
    }
  }

  @override
  FutureResult<List<ExerciseTemplate>> findIsolationExercises() async {
    try {
      return right(ExerciseCatalog.isolationExercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error: $e'));
    }
  }
}
