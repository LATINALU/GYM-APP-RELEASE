import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/assignment_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of AssignmentRepositoryPort
/// Canonical Firestore schema:
/// - /assignments/{assignmentId}
/// - Required field: gymId
class FirebaseAssignmentRepository implements AssignmentRepositoryPort {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _firebaseAuth;

  static const String _collection = 'assignments';
  static const String _usersCollection = 'users';

  FirebaseAssignmentRepository(this._firestore, {fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
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
  FutureResult<RoutineAssignment> findById(AssignmentId id) async {
    try {
      final doc = await _assignmentsRef.doc(id.value).get();
      if (!doc.exists || doc.data() == null) {
        return left(
          const ServerFailure(
            message: 'Asignación no encontrada',
            code: 'ASSIGNMENT_NOT_FOUND',
          ),
        );
      }
      return right(AssignmentMapper.fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar asignación: $e'));
    }
  }

  @override
  FutureResult<List<RoutineAssignment>> findActiveByClient(
    UserId clientId,
  ) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _assignmentsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .where('status', isEqualTo: 'active')
              .get();

      final assignments =
          query.docs
              .map((doc) => AssignmentMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(assignments);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar asignaciones: $e'));
    }
  }

  @override
  FutureResult<List<RoutineAssignment>> findByClient(UserId clientId) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _assignmentsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .orderBy('assignedAt', descending: true)
              .get();

      final assignments =
          query.docs
              .map((doc) => AssignmentMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(assignments);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar asignaciones: $e'));
    }
  }

  @override
  FutureResult<List<RoutineAssignment>> findByRoutine(
    RoutineId routineId,
  ) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _assignmentsRef
              .where('gymId', isEqualTo: gymId)
              .where('routineId', isEqualTo: routineId.value)
              .get();

      final assignments =
          query.docs
              .map((doc) => AssignmentMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(assignments);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar asignaciones: $e'));
    }
  }

  @override
  FutureResult<List<RoutineAssignment>> findByAssigner(
    UserId assignerId,
  ) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _assignmentsRef
              .where('gymId', isEqualTo: gymId)
              .where('assignedById', isEqualTo: assignerId.value)
              .orderBy('assignedAt', descending: true)
              .get();

      final assignments =
          query.docs
              .map((doc) => AssignmentMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(assignments);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar asignaciones: $e'));
    }
  }

  @override
  FutureVoidResult save(RoutineAssignment assignment) async {
    try {
      final gymId = await _resolveGymIdByUserId(assignment.assignedById.value);
      final data = Map<String, dynamic>.from(
        AssignmentMapper.toFirestore(assignment),
      )..['gymId'] = gymId;

      await _assignmentsRef
          .doc(assignment.id.value)
          .set(data, SetOptions(merge: true));
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al guardar asignación: $e'));
    }
  }

  @override
  FutureVoidResult delete(AssignmentId id) async {
    try {
      await _assignmentsRef.doc(id.value).delete();
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al eliminar asignación: $e'));
    }
  }

  @override
  Future<bool> hasActiveAssignment(UserId clientId, RoutineId routineId) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _assignmentsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .where('routineId', isEqualTo: routineId.value)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
