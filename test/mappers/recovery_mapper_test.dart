import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/recovery_log.dart';
import 'package:gym_app/src/infrastructure/mappers/recovery_mapper.dart';

void main() {
  group('RecoveryMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final original = RecoveryLog.create(
        userId: 'firebase-uid-123',
        sleepHours: 7.5,
        sleepQuality: SleepQuality.good,
        hydrationLiters: 2.5,
        stressLevel: 4,
        muscleSoreness: {'quads': SorenessLevel.mild, 'back': SorenessLevel.none},
        energyLevel: 8,
        motivationLevel: 9,
        heartRateResting: 58.0,
        notes: 'descanso de prueba',
      );

      final row = RecoveryMapper.toSupabase(original);

      expect(row['user_id'], 'firebase-uid-123');
      expect(row['sleep_hours'], 7.5);
      expect(row['sleep_quality'], 'good');
      expect(row['stress_level'], 4);
      expect(row['muscle_soreness'], {'quads': 'mild', 'back': 'none'});
      expect(row['heart_rate_resting'], 58.0);
      expect(row['notes'], 'descanso de prueba');
      expect(row.containsKey('userId'), isFalse);

      // Simula lo que devolvería PostgREST (mismas columnas, id ya asignado)
      final fromDb = RecoveryMapper.fromSupabase(row);

      expect(fromDb.id, original.id);
      expect(fromDb.userId, original.userId);
      expect(fromDb.sleepHours, original.sleepHours);
      expect(fromDb.sleepQuality, original.sleepQuality);
      expect(fromDb.muscleSoreness, original.muscleSoreness);
      expect(fromDb.energyLevel, original.energyLevel);
      expect(fromDb.motivationLevel, original.motivationLevel);
      expect(fromDb.heartRateResting, original.heartRateResting);
      expect(fromDb.notes, original.notes);
    });

    test('fromSupabase tolera columnas nulas', () {
      final row = {
        'id': 'r1',
        'user_id': 'u1',
        'date': DateTime(2026, 1, 1).toIso8601String(),
        'sleep_hours': null,
        'sleep_quality': null,
        'muscle_soreness': null,
        'heart_rate_resting': null,
        'notes': null,
      };

      final log = RecoveryMapper.fromSupabase(row);

      expect(log.id, 'r1');
      expect(log.userId, 'u1');
      expect(log.sleepHours, 0);
      expect(log.sleepQuality, SleepQuality.fair);
      expect(log.muscleSoreness, isEmpty);
      expect(log.heartRateResting, isNull);
      expect(log.notes, isNull);
    });
  });
}
