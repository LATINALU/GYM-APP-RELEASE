import '../../domain/entities/muscle_volume.dart';
import '../../domain/ports/output/volume_repository_port.dart';

/// Application Service for Muscle Volume Tracking
/// GYM-APP per-muscle-group volume analysis
class VolumeTrackingService {
  final VolumeRepositoryPort _repo;

  VolumeTrackingService(this._repo);

  /// Get current week's volume record
  Future<MuscleVolumeRecord> getCurrentWeek(String userId) async {
    try {
      final history = await _repo.getHistory(userId, weeks: 1);
      if (history.isNotEmpty) {
        final latest = history.first;
        final weekStart = _getWeekStart(DateTime.now());
        if (latest.weekStart.isAtSameMomentAs(weekStart)) return latest;
      }
      return MuscleVolumeRecord.create(
        userId: userId,
        weekStart: _getWeekStart(DateTime.now()),
      );
    } catch (e) {
      return MuscleVolumeRecord.create(
        userId: userId,
        weekStart: _getWeekStart(DateTime.now()),
      );
    }
  }

  /// Log a set for a specific muscle group
  Future<MuscleVolumeRecord> logSet({
    required String userId,
    required MuscleGroup muscle,
    required int reps,
    required double weightKg,
  }) async {
    await _repo.logSet(
      userId: userId,
      muscle: muscle,
      reps: reps,
      weightKg: weightKg,
    );
    return getCurrentWeek(userId);
  }

  /// Get weekly volume history for trend analysis
  Future<List<MuscleVolumeRecord>> getHistory(
    String userId, {
    int weeks = 8,
  }) async {
    try {
      return await _repo.getHistory(userId, weeks: weeks);
    } catch (e) {
      return const [];
    }
  }

  /// Get volume distribution summary
  Future<Map<String, dynamic>> getDistribution(String userId) async {
    final record = await getCurrentWeek(userId);
    final totalVol = record.totalVolume;

    final distribution = <String, double>{};
    record.volumes.forEach((muscle, data) {
      distribution[muscle.displayName] =
          totalVol > 0 ? (data.totalVolume / totalVol * 100) : 0;
    });

    return {
      'distribution': distribution,
      'totalVolume': totalVol,
      'totalSets': record.totalSets,
      'undertrained': record.undertrained.map((m) => m.displayName).toList(),
      'volumes': record.volumes.map(
        (k, v) => MapEntry(k.displayName, {
          'sets': v.totalSets,
          'reps': v.totalReps,
          'volume': v.totalVolume,
          'maxWeight': v.maxWeight,
        }),
      ),
    };
  }

  /// Compare two weeks of volume
  Future<Map<String, dynamic>> compareWeeks(String userId) async {
    final history = await getHistory(userId, weeks: 2);
    if (history.length < 2) {
      return {'hasComparison': false};
    }
    final current = history[0];
    final previous = history[1];
    return {
      'hasComparison': true,
      'currentVolume': current.totalVolume,
      'previousVolume': previous.totalVolume,
      'volumeChange': current.totalVolume - previous.totalVolume,
      'changePercent':
          previous.totalVolume > 0
              ? ((current.totalVolume - previous.totalVolume) /
                  previous.totalVolume *
                  100)
              : 0,
      'currentSets': current.totalSets,
      'previousSets': previous.totalSets,
    };
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }
}
