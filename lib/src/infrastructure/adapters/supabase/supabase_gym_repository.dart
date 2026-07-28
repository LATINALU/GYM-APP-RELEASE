import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/gym_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Fase 3 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseGymRepository], respaldado por `public.gyms` (ver
/// supabase/migrations/0008_gyms_and_members.sql).
class SupabaseGymRepository implements GymRepositoryPort {
  final SupabaseClient _client;
  SupabaseGymRepository(this._client);

  SupabaseQueryBuilder get _gyms => _client.from('gyms');

  @override
  FutureResult<GymId> save(Gym gym) async {
    try {
      await _gyms.upsert(GymMapper.toSupabase(gym));
      return right(gym.id);
    } catch (e) {
      return left(ServerFailure(message: 'Error al guardar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<Gym> findById(GymId id) async {
    try {
      final row = await _gyms.select().eq('id', id.value).maybeSingle();
      if (row == null) {
        return left(const ServerFailure(message: 'Gimnasio no encontrado'));
      }
      return right(GymMapper.fromSupabase(row));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<void> update(Gym gym) async {
    try {
      await _gyms.update(GymMapper.toSupabase(gym)).eq('id', gym.id.value);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al actualizar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<List<Gym>> findAll() async {
    try {
      final rows = await _gyms.select().eq('is_active', true);
      return right(rows.map((r) => GymMapper.fromSupabase(r)).toList());
    } catch (e) {
      return left(ServerFailure(message: 'Error al listar gimnasios: $e'));
    }
  }

  @override
  FutureResult<void> deactivate(GymId id) async {
    try {
      await _gyms.update({'is_active': false}).eq('id', id.value);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al desactivar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getStats(GymId id) async {
    // Paridad con el adaptador Firebase: gyms/{gymId}/stats/overview nunca
    // tuvo ningún escritor en todo el código (verificado), siempre
    // devolvía {}. No se crea una tabla nueva para esto.
    return right(const {});
  }

  @override
  FutureResult<List<Map<String, dynamic>>> getDailyMetrics({
    required GymId id,
    required DateTime start,
    required DateTime end,
  }) async {
    // Ídem getStats: gyms/{gymId}/metrics nunca tuvo escritor real.
    return right(const []);
  }

  @override
  FutureResult<Gym> findByCode(GymCode code) async {
    try {
      final row = await _gyms
          .select()
          .eq('code', code.value)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return left(const ServerFailure(
          message: 'Gimnasio no encontrado con ese código',
        ));
      }
      return right(GymMapper.fromSupabase(row));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar gimnasio por código: $e'));
    }
  }
}
