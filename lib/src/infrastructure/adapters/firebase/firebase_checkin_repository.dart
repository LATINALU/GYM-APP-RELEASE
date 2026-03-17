import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/check_in_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of CheckInRepositoryPort
/// Canonical Firestore schema:
/// - /check_ins/{checkInId}
/// - Required field: gymId
class FirebaseCheckInRepository implements CheckInRepositoryPort {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _firebaseAuth;

  static const String _collection = 'check_ins';
  static const String _usersCollection = 'users';

  FirebaseCheckInRepository(this._firestore, {fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _checkInsRef =>
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
  FutureResult<CheckIn> findById(CheckInId id) async {
    try {
      final doc = await _checkInsRef.doc(id.value).get();
      if (!doc.exists || doc.data() == null) {
        return left(
          const ServerFailure(
            message: 'Check-in no encontrado',
            code: 'CHECKIN_NOT_FOUND',
          ),
        );
      }
      return right(CheckInMapper.fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar check-in: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByClient(UserId clientId) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _checkInsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .orderBy('checkInTime', descending: true)
              .limit(50)
              .get();

      final checkIns =
          query.docs
              .map((doc) => CheckInMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(checkIns);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar check-ins: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _checkInsRef
              .where('gymId', isEqualTo: gymId)
              .where(
                'checkInTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where(
                'checkInTime',
                isLessThanOrEqualTo: endDate.toIso8601String(),
              )
              .orderBy('checkInTime', descending: true)
              .get();

      final checkIns =
          query.docs
              .map((doc) => CheckInMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(checkIns);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar check-ins: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByClientAndDateRange({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _checkInsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .where(
                'checkInTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where(
                'checkInTime',
                isLessThanOrEqualTo: endDate.toIso8601String(),
              )
              .orderBy('checkInTime', descending: true)
              .get();

      final checkIns =
          query.docs
              .map((doc) => CheckInMapper.fromFirestore(doc.data(), doc.id))
              .toList();

      return right(checkIns);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar check-ins: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findToday() async {
    final now = DateTime.now();
    final startOfDay = app_date.DateUtils.startOfDay(now);
    final endOfDay = app_date.DateUtils.endOfDay(now);
    return findByDateRange(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  FutureVoidResult save(CheckIn checkIn) async {
    try {
      final gymId = await _resolveGymIdByUserId(checkIn.clientId.value);
      final data = Map<String, dynamic>.from(CheckInMapper.toFirestore(checkIn))
        ..['gymId'] = gymId;

      await _checkInsRef
          .doc(checkIn.id.value)
          .set(data, SetOptions(merge: true));
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al guardar check-in: $e'));
    }
  }

  @override
  FutureResult<CheckIn?> findActiveByClient(UserId clientId) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _checkInsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .where('checkOutTime', isNull: true)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return right(null);
      }

      final doc = query.docs.first;
      return right(CheckInMapper.fromFirestore(doc.data(), doc.id));
    } catch (e) {
      return left(
        ServerFailure(message: 'Error al buscar check-in activo: $e'),
      );
    }
  }

  @override
  Future<int> countByClientAndPeriod({
    required UserId clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final gymId = await _resolveCurrentGymId();
      final query =
          await _checkInsRef
              .where('gymId', isEqualTo: gymId)
              .where('clientId', isEqualTo: clientId.value)
              .where(
                'checkInTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where(
                'checkInTime',
                isLessThanOrEqualTo: endDate.toIso8601String(),
              )
              .count()
              .get();
      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
