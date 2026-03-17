import 'package:gym_app/src/domain/entities/muscle_volume.dart';

/// PORT - Output interface for muscle volume data persistence
abstract class VolumeRepositoryPort {
  Future<void> save(MuscleVolumeRecord record);
  Future<MuscleVolumeRecord?> getCurrentWeek(String userId);
  Future<List<MuscleVolumeRecord>> getHistory(String userId, {int weeks = 8});
  Future<void> logSet({
    required String userId,
    required MuscleGroup muscle,
    required int reps,
    required double weightKg,
  });
}
