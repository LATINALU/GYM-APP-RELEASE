import 'package:supabase/supabase.dart';
import 'package:gym_app/src/domain/entities/body_measurement.dart';
import 'package:gym_app/src/domain/ports/output/measurement_repository_port.dart';
import '../../mappers/measurement_mapper.dart';

/// Piloto Supabase self-hosted: mismo contrato que
/// [FirebaseMeasurementRepository], respaldado por `public.body_measurements`
/// en Postgres (ver supabase/migrations/0001_body_measurements.sql).
class SupabaseMeasurementRepository implements MeasurementRepositoryPort {
  final SupabaseClient _client;
  SupabaseMeasurementRepository(this._client);

  SupabaseQueryBuilder get _measurements => _client.from('body_measurements');

  @override
  Future<void> save(BodyMeasurement measurement) async {
    await _measurements.upsert(MeasurementMapper.toSupabase(measurement));
  }

  @override
  Future<List<BodyMeasurement>> getHistory(String userId, {int limit = 30}) async {
    final rows = await _measurements
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);
    return rows.map((r) => MeasurementMapper.fromSupabase(r)).toList();
  }

  @override
  Future<BodyMeasurement?> getLatest(String userId) async {
    final rows = await _measurements
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return MeasurementMapper.fromSupabase(rows.first);
  }

  @override
  Future<void> delete(String measurementId) async {
    await _measurements.delete().eq('id', measurementId);
  }

  @override
  Future<List<BodyMeasurement>> getByDateRange(String userId, DateTime from, DateTime to) async {
    final rows = await _measurements
        .select()
        .eq('user_id', userId)
        .gte('date', from.toIso8601String())
        .lte('date', to.toIso8601String())
        .order('date', ascending: false);
    return rows.map((r) => MeasurementMapper.fromSupabase(r)).toList();
  }
}
