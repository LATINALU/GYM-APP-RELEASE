import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/pending_registration.dart';
import '../../../domain/ports/output/pending_registration_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase implementation of PendingRegistrationRepositoryPort
/// 
/// Firestore structure:
/// /pending_registrations/{registrationId}  ← Global collection
/// /gyms/{gymId}/pending_requests/{registrationId}  ← Per-gym index
class FirebasePendingRegistrationRepository
    implements PendingRegistrationRepositoryPort {
  final FirebaseFirestore _firestore;

  FirebasePendingRegistrationRepository(this._firestore);

  /// Root collection for all pending registrations
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('pending_registrations');

  /// Per-gym index collection
  CollectionReference<Map<String, dynamic>> _gymCollection(String gymId) =>
      _firestore.collection('gyms').doc(gymId).collection('pending_requests');

  @override
  FutureVoidResult save(PendingRegistration registration) async {
    try {
      final data = _toFirestore(registration);

      // Write to global collection
      await _collection.doc(registration.id).set(data);

      // If assigned to a gym, also write to gym's index
      if (registration.targetGymId != null) {
        await _gymCollection(registration.targetGymId!)
            .doc(registration.id)
            .set(data);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al guardar solicitud: $e'));
    }
  }

  @override
  FutureResult<PendingRegistration> findById(String registrationId) async {
    try {
      final doc = await _collection.doc(registrationId).get();
      if (!doc.exists || doc.data() == null) {
        return const Left(ServerFailure(message: 'Solicitud no encontrada'));
      }
      return Right(_fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar solicitud: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByGymId(GymId gymId) async {
    try {
      final snapshot = await _gymCollection(gymId.value)
          .where('status', isEqualTo: 'pendingReview')
          .orderBy('createdAt', descending: true)
          .get();

      final registrations = snapshot.docs
          .map((doc) => _fromFirestore(doc.data(), doc.id))
          .toList();

      return Right(registrations);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByUserId(UserId userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId.value)
          .orderBy('createdAt', descending: true)
          .get();

      final registrations = snapshot.docs
          .map((doc) => _fromFirestore(doc.data(), doc.id))
          .toList();

      return Right(registrations);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes del usuario: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findUnassigned() async {
    try {
      final snapshot = await _collection
          .where('targetGymId', isNull: true)
          .where('status', isEqualTo: 'pendingReview')
          .orderBy('createdAt', descending: true)
          .get();

      final registrations = snapshot.docs
          .map((doc) => _fromFirestore(doc.data(), doc.id))
          .toList();

      return Right(registrations);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes sin asignar: $e'));
    }
  }

  @override
  FutureVoidResult update(PendingRegistration registration) async {
    try {
      final data = _toFirestore(registration);

      final existingDoc = await _collection.doc(registration.id).get();
      final previousGymId = existingDoc.data()?['targetGymId'] as String?;

      await _collection.doc(registration.id).update(data);

      if (previousGymId != null &&
          previousGymId.isNotEmpty &&
          previousGymId != registration.targetGymId) {
        await _gymCollection(previousGymId).doc(registration.id).delete();
      }

      // Update gym index if assigned
      if (registration.targetGymId != null) {
        await _gymCollection(registration.targetGymId!)
            .doc(registration.id)
            .set(data, SetOptions(merge: true));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar solicitud: $e'));
    }
  }

  @override
  FutureVoidResult delete(String registrationId) async {
    try {
      // Get the registration first to know if it has a gym
      final doc = await _collection.doc(registrationId).get();
      if (doc.exists && doc.data() != null) {
        final gymId = doc.data()!['targetGymId'] as String?;
        if (gymId != null) {
          await _gymCollection(gymId).doc(registrationId).delete();
        }
      }

      await _collection.doc(registrationId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar solicitud: $e'));
    }
  }

  @override
  Stream<List<PendingRegistration>> watchByGymId(GymId gymId) {
    return _gymCollection(gymId.value)
        .where('status', isEqualTo: 'pendingReview')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<int> countPendingByGymId(GymId gymId) async {
    try {
      final snapshot = await _gymCollection(gymId.value)
          .where('status', isEqualTo: 'pendingReview')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findExpired() async {
    try {
      final now = DateTime.now();
      final snapshot = await _collection
          .where('status', isEqualTo: 'pendingReview')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final registrations = snapshot.docs
          .map((doc) => _fromFirestore(doc.data(), doc.id))
          .toList();

      return Right(registrations);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar solicitudes expiradas: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> search({
    required String query,
    GymId? gymId,
  }) async {
    try {
      final lowerQuery = query.toLowerCase();
      
      Query<Map<String, dynamic>> ref;
      if (gymId != null) {
        ref = _gymCollection(gymId.value);
      } else {
        ref = _collection;
      }

      // Firestore doesn't support full-text search natively
      // We use a prefix match on userName for now
      final snapshot = await ref
          .where('userNameLower', isGreaterThanOrEqualTo: lowerQuery)
          .where('userNameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(20)
          .get();

      final registrations = snapshot.docs
          .map((doc) => _fromFirestore(doc.data(), doc.id))
          .toList();

      return Right(registrations);
    } catch (e) {
      return Left(ServerFailure(message: 'Error en la búsqueda: $e'));
    }
  }

  // === MAPPERS ===

  Map<String, dynamic> _toFirestore(PendingRegistration reg) {
    return {
      'userId': reg.userId,
      'userEmail': reg.userEmail,
      'userName': reg.userName,
      'userNameLower': reg.userName.toLowerCase(),
      'userPhone': reg.userPhone,
      'userPhotoUrl': reg.userPhotoUrl,
      'targetGymId': reg.targetGymId,
      'targetGymName': reg.targetGymName,
      'targetGymCode': reg.targetGymCode,
      'accessCodeUsed': reg.accessCodeUsed,
      'status': reg.status.name,
      'source': reg.source.name,
      'message': reg.message,
      'fitnessGoal': reg.fitnessGoal,
      'weight': reg.weight,
      'height': reg.height,
      'reviewedBy': reg.reviewedBy,
      'reviewedAt': reg.reviewedAt != null
          ? Timestamp.fromDate(reg.reviewedAt!)
          : null,
      'rejectionReason': reg.rejectionReason,
      'createdAt': Timestamp.fromDate(reg.createdAt),
      'expiresAt': reg.expiresAt != null
          ? Timestamp.fromDate(reg.expiresAt!)
          : null,
      'metadata': reg.metadata,
    };
  }

  PendingRegistration _fromFirestore(Map<String, dynamic> data, String id) {
    return PendingRegistration.restore(
      id: id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhone: data['userPhone'] as String?,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      targetGymId: data['targetGymId'] as String?,
      targetGymName: data['targetGymName'] as String?,
      targetGymCode: data['targetGymCode'] as String?,
      accessCodeUsed: data['accessCodeUsed'] as String?,
      status: _parseStatus(data['status'] as String? ?? 'pendingReview'),
      source: _parseSource(data['source'] as String? ?? 'manualCode'),
      message: data['message'] as String?,
      fitnessGoal: data['fitnessGoal'] as String?,
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  RegistrationStatus _parseStatus(String value) {
    return RegistrationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RegistrationStatus.pendingReview,
    );
  }

  RegistrationSource _parseSource(String value) {
    return RegistrationSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RegistrationSource.manualCode,
    );
  }
}
