import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/routine_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of RoutineRepositoryPort
/// Canonical Firestore schema:
/// - /routines/{routineId}
/// - Required field: gymId
class FirebaseRoutineRepository implements RoutineRepositoryPort {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _firebaseAuth;

  static const String _collection = 'routines';
  static const String _usersCollection = 'users';

  FirebaseRoutineRepository(this._firestore, {fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _routinesRef =>
      _firestore.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  Future<String> _resolveGymIdByUserId(String userId) async {
    final userDoc = await _usersRef.doc(userId).get();
    final gymId = userDoc.data()?['gymId']?.toString();

    if (gymId == null || gymId.trim().isEmpty) {
      throw StateError('No gymId found for user $userId');
    }

    return gymId;
  }

  Future<String> _resolveCurrentGymId() async {
    final currentUid = _firebaseAuth.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) {
      throw StateError('No authenticated user for gym-scoped query');
    }
    return _resolveGymIdByUserId(currentUid);
  }

  @override
  FutureResult<WorkoutRoutine> findById(RoutineId id) async {
    try {
      final doc = await _routinesRef.doc(id.value).get();
      if (!doc.exists || doc.data() == null) {
        return left(
          const ServerFailure(
            message: 'Rutina no encontrada',
            code: 'ROUTINE_NOT_FOUND',
          ),
        );
      }
      return right(RoutineMapper.fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar rutina: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findAllActive() async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _routinesRef
              .where('gymId', isEqualTo: gymId)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      final routines =
          query.docs
              .map((doc) => RoutineMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(routines);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar rutinas: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByCreator(UserId creatorId) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _routinesRef
              .where('gymId', isEqualTo: gymId)
              .where('createdBy', isEqualTo: creatorId.value)
              .where('isActive', isEqualTo: true)
              .get();

      final routines =
          query.docs
              .map((doc) => RoutineMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(routines);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar rutinas: $e'));
    }
  }

  @override
  FutureVoidResult save(WorkoutRoutine routine) async {
    try {
      final gymId = await _resolveGymIdByUserId(routine.createdBy.value);
      final data = Map<String, dynamic>.from(RoutineMapper.toFirestore(routine))
        ..['gymId'] = gymId;

      await _routinesRef
          .doc(routine.id.value)
          .set(data, SetOptions(merge: true));
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al guardar rutina: $e'));
    }
  }

  @override
  FutureVoidResult delete(RoutineId id) async {
    try {
      await _routinesRef.doc(id.value).delete();
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al eliminar rutina: $e'));
    }
  }

  @override
  FutureResult<List<WorkoutRoutine>> findByDifficulty(
    DifficultyLevel difficulty,
  ) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _routinesRef
              .where('gymId', isEqualTo: gymId)
              .where('difficulty', isEqualTo: difficulty.name)
              .where('isActive', isEqualTo: true)
              .get();

      final routines =
          query.docs
              .map((doc) => RoutineMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(routines);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar rutinas: $e'));
    }
  }
}
