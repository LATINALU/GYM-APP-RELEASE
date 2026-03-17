import '../../domain/entities/muscle_volume.dart';
import '../../domain/ports/output/volume_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of VolumeRepositoryPort
class InsForgeVolumeRepository implements VolumeRepositoryPort {
  final InsForgeClient _client;

  InsForgeVolumeRepository(this._client);

  @override
  Future<void> save(MuscleVolumeRecord record) async {
    try {
      final volumesMap = <String, dynamic>{};
      record.volumes.forEach((muscle, data) {
        volumesMap[muscle.name] = data.toMap();
      });

      await _client.insert('muscle_volumes', {
        'id': record.id,
        'user_id': record.userId,
        'muscle_group': 'all',
        'sets_completed': record.totalSets,
        'total_volume': record.totalVolume,
        'week_start': record.weekStart.toIso8601String().substring(0, 10),
      });
    } catch (_) {}
  }

  @override
  Future<MuscleVolumeRecord?> getCurrentWeek(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day)
          .toIso8601String().substring(0, 10);

      final response = await _client.from('muscle_volumes',
          query: 'user_id=eq.$userId&week_start=eq.$weekStartStr&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) return null;

      return MuscleVolumeRecord.restore({
        'id': response.firstItem!['id'] as String? ?? '',
        'userId': userId,
        'weekStart': weekStartStr,
        'volumes': {},
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MuscleVolumeRecord>> getHistory(String userId, {int weeks = 8}) async {
    try {
      final response = await _client.from('muscle_volumes',
          query: 'user_id=eq.$userId&select=*&order=week_start.desc&limit=$weeks');
      if (!response.isSuccess) return [];

      return response.dataList.map((e) {
        final m = e as Map<String, dynamic>;
        return MuscleVolumeRecord.restore({
          'id': m['id'] as String? ?? '',
          'userId': userId,
          'weekStart': m['week_start'] as String? ?? '',
          'volumes': {},
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> logSet({
    required String userId,
    required MuscleGroup muscle,
    required int reps,
    required double weightKg,
  }) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day)
          .toIso8601String().substring(0, 10);
      final volume = reps * weightKg;

      await _client.insert('muscle_volumes', {
        'user_id': userId,
        'muscle_group': muscle.name,
        'sets_completed': 1,
        'total_volume': volume,
        'week_start': weekStartStr,
      });
    } catch (_) {}
  }
}
