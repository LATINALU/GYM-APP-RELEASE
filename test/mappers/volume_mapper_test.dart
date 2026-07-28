import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/muscle_volume.dart';
import 'package:gym_app/src/infrastructure/mappers/volume_mapper.dart';

void main() {
  group('VolumeMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final original = MuscleVolumeRecord.create(
        userId: 'firebase-uid-123',
        weekStart: DateTime(2026, 1, 5),
      ).addSet(muscle: MuscleGroup.chest, reps: 8, weightKg: 60).addSet(
            muscle: MuscleGroup.back,
            reps: 10,
            weightKg: 40,
          );

      final row = VolumeMapper.toSupabase(original);

      expect(row['user_id'], 'firebase-uid-123');
      expect(row['week_start'], DateTime(2026, 1, 5).toIso8601String());
      expect(row.containsKey('userId'), isFalse);
      expect(row.containsKey('weekStart'), isFalse);

      // Simula lo que devolvería PostgREST (mismas columnas, id ya asignado)
      final fromDb = VolumeMapper.fromSupabase(row);

      expect(fromDb.id, original.id);
      expect(fromDb.userId, original.userId);
      expect(fromDb.weekStart, original.weekStart);
      expect(fromDb.totalVolume, original.totalVolume);
      expect(fromDb.volumes[MuscleGroup.chest]!.totalVolume, 480);
      expect(fromDb.volumes[MuscleGroup.back]!.totalVolume, 400);
    });

    test('fromSupabase tolera un registro sin sets (volumes vacío)', () {
      final row = {
        'id': 'v1',
        'user_id': 'u1',
        'week_start': DateTime(2026, 1, 5).toIso8601String(),
        'volumes': <String, dynamic>{},
      };

      final record = VolumeMapper.fromSupabase(row);

      expect(record.id, 'v1');
      expect(record.userId, 'u1');
      expect(record.totalVolume, 0);
      expect(record.volumes, isEmpty);
    });
  });
}
