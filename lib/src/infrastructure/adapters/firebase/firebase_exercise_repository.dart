import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/exercise_mapper.dart';

typedef FutureResult<T> = Future<Either<Failure, T>>;

/// Repositorio de ejercicios usando Firestore
class FirebaseExerciseRepository {
  final FirebaseFirestore _firestore;
  
  FirebaseExerciseRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _exercisesRef =>
      _firestore.collection('exercises');

  /// Obtener todos los ejercicios activos
  FutureResult<List<Exercise>> getAll() async {
    try {
      final snapshot = await _exercisesRef
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final exercises = snapshot.docs
          .map((doc) => ExerciseMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(exercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error al obtener ejercicios: $e'));
    }
  }

  /// Obtener ejercicio por ID
  FutureResult<Exercise> getById(ExerciseId id) async {
    try {
      final doc = await _exercisesRef.doc(id.value).get();

      if (!doc.exists) {
        return left(const NotFoundFailure(message: 'Ejercicio no encontrado'));
      }

      return right(ExerciseMapper.fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al obtener ejercicio: $e'));
    }
  }

  /// Buscar ejercicios por grupo muscular
  FutureResult<List<Exercise>> getByMuscleGroup(MuscleGroup muscle) async {
    try {
      final snapshot = await _exercisesRef
          .where('primaryMuscle', isEqualTo: muscle.name)
          .where('isActive', isEqualTo: true)
          .get();

      final exercises = snapshot.docs
          .map((doc) => ExerciseMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(exercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar ejercicios: $e'));
    }
  }

  /// Buscar ejercicios por equipamiento
  FutureResult<List<Exercise>> getByEquipment(EquipmentType equipment) async {
    try {
      final snapshot = await _exercisesRef
          .where('equipment', arrayContains: equipment.name)
          .where('isActive', isEqualTo: true)
          .get();

      final exercises = snapshot.docs
          .map((doc) => ExerciseMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(exercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar ejercicios: $e'));
    }
  }

  /// Buscar ejercicios por término
  FutureResult<List<Exercise>> search(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      
      if (normalizedQuery.isEmpty) {
        return getAll();
      }

      final snapshot = await _exercisesRef
          .where('searchTerms', arrayContains: normalizedQuery)
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      final exercises = snapshot.docs
          .map((doc) => ExerciseMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(exercises);
    } catch (e) {
      return left(ServerFailure(message: 'Error en búsqueda: $e'));
    }
  }

  /// Crear nuevo ejercicio
  FutureResult<Exercise> create(Exercise exercise) async {
    try {
      await _exercisesRef.doc(exercise.id.value).set(
        ExerciseMapper.toFirestore(exercise),
      );

      return right(exercise);
    } catch (e) {
      return left(ServerFailure(message: 'Error al crear ejercicio: $e'));
    }
  }

  /// Actualizar ejercicio existente
  FutureResult<Exercise> update(Exercise exercise) async {
    try {
      await _exercisesRef.doc(exercise.id.value).update(
        ExerciseMapper.toFirestore(exercise),
      );

      return right(exercise);
    } catch (e) {
      return left(ServerFailure(message: 'Error al actualizar ejercicio: $e'));
    }
  }

  /// Desactivar ejercicio (soft delete)
  FutureResult<void> deactivate(ExerciseId id) async {
    try {
      await _exercisesRef.doc(id.value).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al desactivar ejercicio: $e'));
    }
  }
}
