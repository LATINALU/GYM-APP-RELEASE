import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/pending_registration.dart';
import 'package:gym_app/src/infrastructure/mappers/pending_registration_mapper.dart';

void main() {
  group('PendingRegistrationMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final registration = PendingRegistration.restore(
        id: 'reg-1',
        userId: 'firebase-uid-123',
        userEmail: 'ana@example.com',
        userName: 'Ana García',
        targetGymId: 'gym-1',
        targetGymName: 'Iron Temple',
        status: RegistrationStatus.pendingReview,
        source: RegistrationSource.qrScan,
        createdAt: DateTime(2026, 1, 5),
        metadata: {'campaign': 'verano2026'},
      );

      final row = PendingRegistrationMapper.toSupabase(registration);

      expect(row['user_id'], 'firebase-uid-123');
      expect(row['target_gym_id'], 'gym-1');
      expect(row['status'], 'pendingReview');
      expect(row['source'], 'qrScan');
      expect(row['metadata'], {'campaign': 'verano2026'});
      expect(row.containsKey('userId'), isFalse);
      expect(row.containsKey('targetGymId'), isFalse);

      final fromDb = PendingRegistrationMapper.fromSupabase(row);

      expect(fromDb.id, registration.id);
      expect(fromDb.userId, registration.userId);
      expect(fromDb.userName, registration.userName);
      expect(fromDb.targetGymId, registration.targetGymId);
      expect(fromDb.status, registration.status);
      expect(fromDb.source, registration.source);
      expect(fromDb.metadata, registration.metadata);
    });

    test('fromSupabase tolera una solicitud sin gym asignado ni revisar', () {
      final row = {
        'id': 'reg-2',
        'user_id': 'u2',
        'user_email': 'luis@example.com',
        'user_name': 'Luis',
        'target_gym_id': null,
        'status': 'pendingReview',
        'source': 'manualCode',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      final registration = PendingRegistrationMapper.fromSupabase(row);

      expect(registration.targetGymId, isNull);
      expect(registration.reviewedBy, isNull);
      expect(registration.reviewedAt, isNull);
      expect(registration.status, RegistrationStatus.pendingReview);
    });

    test('fromSupabase usa pendingReview/manualCode como fallback para valores desconocidos', () {
      final row = {
        'id': 'reg-3',
        'user_id': 'u3',
        'user_email': 'x@example.com',
        'user_name': 'X',
        'status': 'algo-raro',
        'source': 'otra-cosa',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      final registration = PendingRegistrationMapper.fromSupabase(row);

      expect(registration.status, RegistrationStatus.pendingReview);
      expect(registration.source, RegistrationSource.manualCode);
    });
  });
}
