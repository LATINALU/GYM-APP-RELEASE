import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/ports/output/access_code_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase implementation of AccessCodeRepositoryPort
/// 
/// Firestore structure:
/// /access_codes/{codeValue}  ← Global lookup by code
/// /gyms/{gymId}/access_codes/{codeValue}  ← Per-gym codes
class FirebaseAccessCodeRepository implements AccessCodeRepositoryPort {
  final FirebaseFirestore _firestore;

  FirebaseAccessCodeRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _globalCollection =>
      _firestore.collection('access_codes');

  CollectionReference<Map<String, dynamic>> _gymCollection(String gymId) =>
      _firestore.collection('gyms').doc(gymId).collection('access_codes');

  @override
  FutureResult<AccessCode> generate({
    required GymId gymId,
    required AccessCodeType type,
    required UserId generatedBy,
    int length = 8,
    int expirationMinutes = 30,
  }) async {
    try {
      final code = AccessCode.generate(
        type: type,
        length: length,
        expirationMinutes: expirationMinutes,
      );

      final data = _toFirestore(code, gymId.value, generatedBy.value);

      // Write to both global and gym-specific collections
      await _globalCollection.doc(code.value).set(data);
      await _gymCollection(gymId.value).doc(code.value).set(data);

      return Right(code);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al generar código: $e'));
    }
  }

  @override
  FutureResult<AccessCode> validateAndConsume({
    required String code,
    required UserId consumedBy,
  }) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final doc = await _globalCollection.doc(sanitized).get();

      if (!doc.exists || doc.data() == null) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }

      final accessCode = _fromFirestore(doc.data()!);

      if (accessCode.isUsed) {
        return const Left(ServerFailure(message: 'Este código ya fue utilizado'));
      }

      if (accessCode.isExpired) {
        return const Left(ServerFailure(message: 'Este código ha expirado'));
      }

      // Consume the code
      final consumed = accessCode.consume(consumedBy.value);
      final updatedData = {
        'isUsed': true,
        'usedBy': consumedBy.value,
        'usedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _globalCollection.doc(sanitized).update(updatedData);
      
      // Also update gym-specific copy
      final gymId = doc.data()!['gymId'] as String?;
      if (gymId != null) {
        await _gymCollection(gymId).doc(sanitized).update(updatedData);
      }

      return Right(consumed);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al validar código: $e'));
    }
  }

  @override
  FutureResult<AccessCode> findByCode(String code) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final doc = await _globalCollection.doc(sanitized).get();

      if (!doc.exists || doc.data() == null) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }

      return Right(_fromFirestore(doc.data()!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar código: $e'));
    }
  }

  @override
  FutureResult<List<AccessCode>> findActiveByGymId(GymId gymId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _gymCollection(gymId.value)
          .where('isUsed', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .get();

      final codes = snapshot.docs
          .map((doc) => _fromFirestore(doc.data()))
          .toList();

      return Right(codes);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener códigos activos: $e'));
    }
  }

  @override
  FutureVoidResult revoke(String code) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final doc = await _globalCollection.doc(sanitized).get();

      if (!doc.exists) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }

      final revokeData = {
        'isUsed': true,
        'usedBy': '_REVOKED_',
        'usedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _globalCollection.doc(sanitized).update(revokeData);

      final gymId = doc.data()?['gymId'] as String?;
      if (gymId != null) {
        await _gymCollection(gymId).doc(sanitized).update(revokeData);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al revocar código: $e'));
    }
  }

  @override
  FutureVoidResult revokeAllForGym(GymId gymId) async {
    try {
      final snapshot = await _gymCollection(gymId.value)
          .where('isUsed', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final revokeData = {
        'isUsed': true,
        'usedBy': '_REVOKED_BULK_',
        'usedAt': Timestamp.fromDate(DateTime.now()),
      };

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, revokeData);
        batch.update(_globalCollection.doc(doc.id), revokeData);
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al revocar códigos: $e'));
    }
  }

  @override
  FutureVoidResult cleanupExpired() async {
    try {
      final now = DateTime.now();
      final snapshot = await _globalCollection
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('isUsed', isEqualTo: false)
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        final gymId = doc.data()['gymId'] as String?;
        if (gymId != null) {
          batch.delete(_gymCollection(gymId).doc(doc.id));
        }
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al limpiar códigos: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getUsageStats(GymId gymId) async {
    try {
      final allCodes = await _gymCollection(gymId.value).get();
      final used = allCodes.docs.where((d) => d.data()['isUsed'] == true);
      final active = allCodes.docs.where((d) {
        final data = d.data();
        final isUsed = data['isUsed'] as bool? ?? false;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        return !isUsed && expiresAt != null && expiresAt.isAfter(DateTime.now());
      });

      return Right({
        'total': allCodes.docs.length,
        'used': used.length,
        'active': active.length,
        'expired': allCodes.docs.length - used.length - active.length,
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener estadísticas: $e'));
    }
  }

  // === MAPPERS ===

  Map<String, dynamic> _toFirestore(
      AccessCode code, String gymId, String generatedBy) {
    return {
      'value': code.value,
      'type': code.type.name,
      'gymId': gymId,
      'generatedBy': generatedBy,
      'createdAt': Timestamp.fromDate(code.createdAt),
      'expiresAt': Timestamp.fromDate(code.expiresAt),
      'isUsed': code.isUsed,
      'usedBy': code.usedBy,
      'usedAt':
          code.usedAt != null ? Timestamp.fromDate(code.usedAt!) : null,
    };
  }

  AccessCode _fromFirestore(Map<String, dynamic> data) {
    return AccessCode.restore(
      value: data['value'] as String? ?? '',
      type: _parseType(data['type'] as String? ?? 'gymEntry'),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUsed: data['isUsed'] as bool? ?? false,
      usedBy: data['usedBy'] as String?,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  AccessCodeType _parseType(String value) {
    return AccessCodeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AccessCodeType.gymEntry,
    );
  }
}
