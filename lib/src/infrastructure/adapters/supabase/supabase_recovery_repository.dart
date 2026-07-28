import 'package:supabase/supabase.dart';
import 'package:gym_app/src/domain/entities/recovery_log.dart';
import 'package:gym_app/src/domain/ports/output/recovery_repository_port.dart';
import '../../mappers/recovery_mapper.dart';

/// Fase 1 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseRecoveryRepository], respaldado por `public.recovery_logs`
/// (ver supabase/migrations/0002_recovery_logs.sql).
class SupabaseRecoveryRepository implements RecoveryRepositoryPort {
  final SupabaseClient _client;
  SupabaseRecoveryRepository(this._client);

  SupabaseQueryBuilder get _logs => _client.from('recovery_logs');

  @override
  Future<void> save(RecoveryLog log) async {
    await _logs.upsert(RecoveryMapper.toSupabase(log));
  }

  @override
  Future<RecoveryLog?> getToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final rows = await _logs
        .select()
        .eq('user_id', userId)
        .gte('date', startOfDay.toIso8601String())
        .limit(1);
    if (rows.isEmpty) return null;
    return RecoveryMapper.fromSupabase(rows.first);
  }

  @override
  Future<List<RecoveryLog>> getHistory(String userId, {int limit = 14}) async {
    final rows = await _logs
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);
    return rows.map((r) => RecoveryMapper.fromSupabase(r)).toList();
  }

  @override
  Future<double> getAverageRecoveryScore(String userId, {int days = 7}) async {
    final logs = await getHistory(userId, limit: days);
    if (logs.isEmpty) return 0;
    return logs.fold(0.0, (s, l) => s + l.recoveryScore) / logs.length;
  }

  @override
  Future<void> delete(String logId) async {
    await _logs.delete().eq('id', logId);
  }
}
