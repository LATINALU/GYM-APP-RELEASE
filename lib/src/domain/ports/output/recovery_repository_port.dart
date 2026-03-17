import 'package:gym_app/src/domain/entities/recovery_log.dart';

/// PORT - Output interface for recovery log persistence
abstract class RecoveryRepositoryPort {
  Future<void> save(RecoveryLog log);
  Future<RecoveryLog?> getToday(String userId);
  Future<List<RecoveryLog>> getHistory(String userId, {int limit = 14});
  Future<double> getAverageRecoveryScore(String userId, {int days = 7});
  Future<void> delete(String logId);
}
