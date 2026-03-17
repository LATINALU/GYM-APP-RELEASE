import '../../domain/entities/recovery_log.dart';
import '../../domain/ports/output/recovery_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of RecoveryRepositoryPort
class InsForgeRecoveryRepository implements RecoveryRepositoryPort {
  final InsForgeClient _client;

  InsForgeRecoveryRepository(this._client);

  @override
  Future<void> save(RecoveryLog log) async {
    try {
      await _client.insert('recovery_logs', {
        'id': log.id,
        'user_id': log.userId,
        'sleep_hours': log.sleepHours,
        'sleep_quality': log.sleepQuality.index,
        'stress_level': log.stressLevel,
        'soreness_level': log.energyLevel,
        'notes': log.notes,
        'logged_at': log.date.toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<RecoveryLog?> getToday(String userId) async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final response = await _client.from('recovery_logs',
          query: 'user_id=eq.$userId&logged_at=gte.${start.toIso8601String()}&select=*&order=logged_at.desc&limit=1');
      if (!response.isSuccess || response.dataList.isEmpty) return null;
      return _map(response.firstItem!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RecoveryLog>> getHistory(String userId, {int limit = 14}) async {
    try {
      final response = await _client.from('recovery_logs',
          query: 'user_id=eq.$userId&select=*&order=logged_at.desc&limit=$limit');
      if (!response.isSuccess) return [];
      return response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<double> getAverageRecoveryScore(String userId, {int days = 7}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client.from('recovery_logs',
          query: 'user_id=eq.$userId&logged_at=gte.${since.toIso8601String()}&select=sleep_quality,stress_level,soreness_level');
      if (!response.isSuccess || response.dataList.isEmpty) return 0;

      double total = 0;
      for (final item in response.dataList) {
        final m = item as Map<String, dynamic>;
        final sleep = (m['sleep_quality'] as num?)?.toDouble() ?? 5;
        final stress = 10 - ((m['stress_level'] as num?)?.toDouble() ?? 5);
        final energy = (m['soreness_level'] as num?)?.toDouble() ?? 5;
        total += (sleep + stress + energy) / 3;
      }
      return total / response.dataList.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> delete(String logId) async {
    try {
      await _client.delete('recovery_logs', 'id=eq.$logId');
    } catch (_) {}
  }

  RecoveryLog _map(Map<String, dynamic> data) {
    final qualityIdx = (data['sleep_quality'] as num?)?.toInt() ?? 2;
    final quality = SleepQuality.values[qualityIdx.clamp(0, SleepQuality.values.length - 1)];

    return RecoveryLog.restore({
      'id': data['id'] as String,
      'userId': data['user_id'] as String,
      'date': DateTime.tryParse(data['logged_at'] as String? ?? '') ?? DateTime.now(),
      'sleepQuality': quality,
      'sleepHours': (data['sleep_hours'] as num?)?.toDouble() ?? 0.0,
      'muscleSoreness': (data['muscle_soreness'] as num?)?.toInt() ?? 5,
      'energyLevel': (data['energy_level'] as num?)?.toInt() ?? 5,
      'stressLevel': (data['stress_level'] as num?)?.toInt() ?? 5,
      'motivationLevel': (data['motivation_level'] as num?)?.toInt() ?? 5,
      'heartRateResting': (data['heart_rate_resting'] as num?)?.toInt(),
      'notes': data['notes'] as String?,
    });
  }
}
