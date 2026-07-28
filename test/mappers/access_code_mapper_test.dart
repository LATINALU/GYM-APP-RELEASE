import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/value_objects/value_objects.dart';
import 'package:gym_app/src/infrastructure/mappers/access_code_mapper.dart';

void main() {
  group('AccessCodeMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final code = AccessCode.generate(
        type: AccessCodeType.gymEntry,
        length: 8,
        expirationMinutes: 30,
      );

      final row = AccessCodeMapper.toSupabase(
        code,
        gymId: 'gym-1',
        generatedBy: 'owner-1',
      );

      expect(row['value'], code.value);
      expect(row['gym_id'], 'gym-1');
      expect(row['generated_by'], 'owner-1');
      expect(row['type'], 'gymEntry');
      expect(row['is_used'], false);
      expect(row['used_by'], isNull);
      expect(row['used_at'], isNull);

      final fromDb = AccessCodeMapper.fromSupabase(row);

      expect(fromDb.value, code.value);
      expect(fromDb.type, code.type);
      expect(fromDb.isUsed, isFalse);
      expect(fromDb.isExpired, isFalse);
    });

    test('fromSupabase reconstruye un código ya consumido', () {
      final usedAt = DateTime(2026, 1, 5, 10, 30);
      final row = {
        'value': 'GYM12345',
        'gym_id': 'gym-1',
        'type': 'ownerVerification',
        'generated_by': 'owner-1',
        'created_at': DateTime(2026, 1, 5, 10, 0).toIso8601String(),
        'expires_at': DateTime(2026, 1, 5, 10, 30).toIso8601String(),
        'is_used': true,
        'used_by': 'client-1',
        'used_at': usedAt.toIso8601String(),
      };

      final code = AccessCodeMapper.fromSupabase(row);

      expect(code.value, 'GYM12345');
      expect(code.type, AccessCodeType.ownerVerification);
      expect(code.isUsed, isTrue);
      expect(code.usedBy, 'client-1');
      expect(code.usedAt, usedAt);
    });

    test('fromSupabase usa gymEntry como fallback para un type desconocido', () {
      final row = {
        'value': 'X1',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'expires_at': DateTime(2026, 1, 1).toIso8601String(),
        'type': 'algo-inexistente',
      };

      final code = AccessCodeMapper.fromSupabase(row);

      expect(code.type, AccessCodeType.gymEntry);
    });
  });
}
