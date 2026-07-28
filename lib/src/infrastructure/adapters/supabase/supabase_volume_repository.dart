import 'package:supabase/supabase.dart';
import 'package:gym_app/src/domain/entities/muscle_volume.dart';
import 'package:gym_app/src/domain/ports/output/volume_repository_port.dart';
import '../../mappers/volume_mapper.dart';

/// Fase 1 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseVolumeRepository], respaldado por `public.volume_records`
/// (ver supabase/migrations/0003_volume_records.sql).
class SupabaseVolumeRepository implements VolumeRepositoryPort {
  final SupabaseClient _client;
  SupabaseVolumeRepository(this._client);

  SupabaseQueryBuilder get _records => _client.from('volume_records');

  DateTime _weekStartOf(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  @override
  Future<MuscleVolumeRecord?> getCurrentWeek(String userId) async {
    final weekStart = _weekStartOf(DateTime.now());
    final rows = await _records
        .select()
        .eq('user_id', userId)
        .eq('week_start', weekStart.toIso8601String())
        .limit(1);
    if (rows.isEmpty) return null;
    return VolumeMapper.fromSupabase(rows.first);
  }

  @override
  Future<void> save(MuscleVolumeRecord record) async {
    await _records.upsert(VolumeMapper.toSupabase(record));
  }

  @override
  Future<void> logSet({
    required String userId,
    required MuscleGroup muscle,
    required int reps,
    required double weightKg,
  }) async {
    final weekStart = _weekStartOf(DateTime.now());
    final record =
        await getCurrentWeek(userId) ??
        MuscleVolumeRecord.create(userId: userId, weekStart: weekStart);
    final updated = record.addSet(muscle: muscle, reps: reps, weightKg: weightKg);
    await save(updated);
  }

  @override
  Future<List<MuscleVolumeRecord>> getHistory(String userId, {int weeks = 8}) async {
    final rows = await _records
        .select()
        .eq('user_id', userId)
        .order('week_start', ascending: false)
        .limit(weeks);
    return rows.map((r) => VolumeMapper.fromSupabase(r)).toList();
  }
}
