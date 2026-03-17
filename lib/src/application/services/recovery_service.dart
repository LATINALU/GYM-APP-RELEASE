import '../../domain/entities/recovery_log.dart';
import '../../domain/ports/output/recovery_repository_port.dart';

/// Application Service for Recovery Tracking
/// GYM-APP recovery and readiness system
class RecoveryService {
  final RecoveryRepositoryPort _repo;

  RecoveryService(this._repo);

  /// Log today's recovery data
  Future<void> logRecovery(RecoveryLog log) async {
    await _repo.save(log);
  }

  /// Get today's recovery log
  Future<RecoveryLog?> getTodayLog(String userId) async {
    try {
      return await _repo.getToday(userId);
    } catch (e) {
      return null;
    }
  }

  /// Get recovery history for trend analysis
  Future<List<RecoveryLog>> getHistory(String userId, {int days = 14}) async {
    try {
      return await _repo.getHistory(userId, limit: days);
    } catch (e) {
      return const [];
    }
  }

  /// Get average recovery score over N days
  Future<double> getAverageScore(String userId, {int days = 7}) async {
    try {
      return await _repo.getAverageRecoveryScore(userId, days: days);
    } catch (e) {
      return 0;
    }
  }

  /// Get readiness recommendation
  Future<Map<String, dynamic>> getReadiness(String userId) async {
    try {
      final todayLog = await getTodayLog(userId);
      final avgScore = await getAverageScore(userId);

      if (todayLog != null) {
        return {
          'score': todayLog.recoveryScore,
          'status': todayLog.recoveryStatus,
          'shouldTrainHeavy': todayLog.shouldTrainHeavy,
          'shouldRest': todayLog.shouldRest,
          'avgWeekScore': avgScore,
          'recommendation': _getRecommendation(todayLog.recoveryScore),
          'sleepHours': todayLog.sleepHours,
          'hydration': todayLog.hydrationLiters,
          'stress': todayLog.stressLevel,
          'energy': todayLog.energyLevel,
        };
      }
      return _emptyReadiness(avgScore: avgScore);
    } catch (e) {
      return _emptyReadiness();
    }
  }

  String _getRecommendation(double score) {
    if (score >= 85) return 'Día perfecto para entrenamiento pesado o PRs.';
    if (score >= 70) return 'Buen día para entrenamiento normal de volumen.';
    if (score >= 55) return 'Entrena ligero o haz trabajo de movilidad.';
    if (score >= 40) return 'Considera un día de recuperación activa.';
    return 'Descanso total recomendado. Tu cuerpo necesita recuperarse.';
  }

  Map<String, dynamic> _emptyReadiness({double avgScore = 0}) => {
    'score': 0.0,
    'status': 'Sin datos',
    'shouldTrainHeavy': false,
    'shouldRest': false,
    'avgWeekScore': avgScore,
    'recommendation':
        'Completa tu check-in diario para obtener recomendaciones.',
    'sleepHours': 0.0,
    'hydration': 0.0,
    'stress': 0,
    'energy': 0,
  };
}
