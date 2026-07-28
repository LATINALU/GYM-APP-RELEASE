import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/pending_registration.dart';
import '../../../domain/ports/output/pending_registration_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/pending_registration_mapper.dart';

/// Fase 2 de la migración Firebase->Supabase: mismo contrato que
/// [FirebasePendingRegistrationRepository], respaldado por
/// `public.pending_registrations` (ver
/// supabase/migrations/0007_pending_registrations.sql). Una sola tabla
/// reemplaza la duplicación global + por-gym de Firestore.
class SupabasePendingRegistrationRepository
    implements PendingRegistrationRepositoryPort {
  final SupabaseClient _client;
  SupabasePendingRegistrationRepository(this._client);

  SupabaseQueryBuilder get _registrations => _client.from('pending_registrations');

  @override
  FutureVoidResult save(PendingRegistration registration) async {
    try {
      await _registrations.insert(PendingRegistrationMapper.toSupabase(registration));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al guardar solicitud: $e'));
    }
  }

  @override
  FutureResult<PendingRegistration> findById(String registrationId) async {
    try {
      final row = await _registrations.select().eq('id', registrationId).maybeSingle();
      if (row == null) {
        return const Left(ServerFailure(message: 'Solicitud no encontrada'));
      }
      return Right(PendingRegistrationMapper.fromSupabase(row));
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar solicitud: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByGymId(GymId gymId) async {
    try {
      final rows = await _registrations
          .select()
          .eq('target_gym_id', gymId.value)
          .eq('status', 'pendingReview')
          .order('created_at', ascending: false);
      return Right(rows.map((r) => PendingRegistrationMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByUserId(UserId userId) async {
    try {
      final rows = await _registrations
          .select()
          .eq('user_id', userId.value)
          .order('created_at', ascending: false);
      return Right(rows.map((r) => PendingRegistrationMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes del usuario: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findUnassigned() async {
    try {
      final rows = await _registrations
          .select()
          .isFilter('target_gym_id', null)
          .eq('status', 'pendingReview')
          .order('created_at', ascending: false);
      return Right(rows.map((r) => PendingRegistrationMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener solicitudes sin asignar: $e'));
    }
  }

  @override
  FutureVoidResult update(PendingRegistration registration) async {
    try {
      await _registrations
          .update(PendingRegistrationMapper.toSupabase(registration))
          .eq('id', registration.id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al actualizar solicitud: $e'));
    }
  }

  @override
  FutureVoidResult delete(String registrationId) async {
    try {
      await _registrations.delete().eq('id', registrationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al eliminar solicitud: $e'));
    }
  }

  @override
  Stream<List<PendingRegistration>> watchByGymId(GymId gymId) {
    // El stream de Supabase solo admite un filtro server-side (ver
    // SupabaseStreamFilterBuilder) — se filtra por target_gym_id (el
    // que importa para no mezclar colas de otros gimnasios) y el
    // status se filtra en el cliente, igual que hacía el
    // .where('status', ...) adicional del lado Firebase.
    return _registrations
        .stream(primaryKey: ['id'])
        .eq('target_gym_id', gymId.value)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['status'] == 'pendingReview')
            .map((r) => PendingRegistrationMapper.fromSupabase(r))
            .toList());
  }

  @override
  Future<int> countPendingByGymId(GymId gymId) async {
    try {
      final rows = await _registrations
          .select('id')
          .eq('target_gym_id', gymId.value)
          .eq('status', 'pendingReview');
      return rows.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findExpired() async {
    try {
      final now = DateTime.now().toIso8601String();
      final rows = await _registrations
          .select()
          .eq('status', 'pendingReview')
          .lt('expires_at', now);
      return Right(rows.map((r) => PendingRegistrationMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar solicitudes expiradas: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> search({
    required String query,
    GymId? gymId,
  }) async {
    try {
      var builder = _registrations.select().ilike('user_name', '%$query%');
      if (gymId != null) {
        builder = builder.eq('target_gym_id', gymId.value);
      }
      final rows = await builder.limit(20);
      return Right(rows.map((r) => PendingRegistrationMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error en la búsqueda: $e'));
    }
  }
}
