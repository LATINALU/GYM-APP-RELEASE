import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/body_measurement.dart';
import 'package:gym_app/src/infrastructure/mappers/measurement_mapper.dart';

void main() {
  group('MeasurementMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final original = BodyMeasurement.create(
        userId: 'firebase-uid-123',
        weightKg: 82.4,
        bodyFatPercentage: 18.2,
        heightCm: 178,
        chestCm: 102,
        waistCm: 88,
        hipsCm: 98,
        bicepsLeftCm: 34,
        bicepsRightCm: 34.5,
        thighLeftCm: 58,
        thighRightCm: 58.5,
        calfLeftCm: 38,
        calfRightCm: 38.2,
        shouldersCm: 120,
        neckCm: 40,
        forearmLeftCm: 28,
        forearmRightCm: 28.3,
        notes: 'medición de prueba',
      );

      final row = MeasurementMapper.toSupabase(original);

      expect(row['user_id'], 'firebase-uid-123');
      expect(row['weight_kg'], 82.4);
      expect(row['body_fat_percentage'], 18.2);
      expect(row['biceps_right_cm'], 34.5);
      expect(row['notes'], 'medición de prueba');
      expect(row.containsKey('userId'), isFalse);

      // Simula lo que devolvería PostgREST (mismas columnas, id ya asignado)
      final fromDb = MeasurementMapper.fromSupabase(row);

      expect(fromDb.id, original.id);
      expect(fromDb.userId, original.userId);
      expect(fromDb.weightKg, original.weightKg);
      expect(fromDb.bodyFatPercentage, original.bodyFatPercentage);
      expect(fromDb.bicepsRightCm, original.bicepsRightCm);
      expect(fromDb.notes, original.notes);
    });

    test('fromSupabase tolera columnas nulas', () {
      final row = {
        'id': 'm1',
        'user_id': 'u1',
        'date': DateTime(2026, 1, 1).toIso8601String(),
        'weight_kg': null,
        'notes': null,
      };

      final measurement = MeasurementMapper.fromSupabase(row);

      expect(measurement.id, 'm1');
      expect(measurement.userId, 'u1');
      expect(measurement.weightKg, isNull);
      expect(measurement.notes, isNull);
    });
  });
}
