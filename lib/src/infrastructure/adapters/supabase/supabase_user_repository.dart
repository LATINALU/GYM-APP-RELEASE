import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart' hide User;
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Fase 3 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseUserRepository], respaldado por `public.gym_members` (ver
/// supabase/migrations/0008_gyms_and_members.sql). Una sola tabla
/// reemplaza la escritura triplicada de Firestore (nested + raíz +
/// legacy 'user/{uid}', este último no migrado por ser código muerto
/// sin lectores).
class SupabaseUserRepository implements UserRepositoryPort {
  final SupabaseClient _client;
  SupabaseUserRepository(this._client);

  SupabaseQueryBuilder get _members => _client.from('gym_members');

  @override
  FutureResult<User> findById({
    required UserId id,
    required GymId gymId,
    required GymRoleType role,
  }) async {
    try {
      final row = await _members
          .select()
          .eq('id', id.value)
          .eq('gym_id', gymId.value)
          .maybeSingle();
      if (row == null) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }
      return right(UserMapper.fromSupabase(row));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User> findByIdGlobal(UserId id) async {
    try {
      final row = await _members.select().eq('id', id.value).maybeSingle();
      if (row == null) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }
      return right(UserMapper.fromSupabase(row));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User> findByEmail(Email email) async {
    try {
      final row = await _members
          .select()
          .ilike('email', email.value)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }
      return right(UserMapper.fromSupabase(row));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar usuario por email: $e'));
    }
  }

  @override
  FutureResult<List<User>> findByRole({required GymId gymId, required GymRole role}) async {
    try {
      final rows = await _members
          .select()
          .eq('gym_id', gymId.value)
          .eq('role', role.toValue())
          .eq('is_active', true);
      return right(rows.map((r) => UserMapper.fromSupabase(r)).toList());
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<List<User>> findAllActive(GymId gymId) async {
    try {
      // A diferencia de Firebase (que necesitaba 3 consultas, una por
      // subcolección owners/employees/clients, y mergearlas), acá alcanza
      // con un solo where por gym_id: las 3 conviven en la misma tabla.
      final rows = await _members
          .select()
          .eq('gym_id', gymId.value)
          .eq('is_active', true);
      return right(rows.map((r) => UserMapper.fromSupabase(r)).toList());
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar usuarios activos: $e'));
    }
  }

  @override
  FutureVoidResult save(User user) async {
    try {
      // Una sola escritura reemplaza el batch triple de Firebase (nested
      // + raíz + legacy 'user/{uid}', este último dead code no migrado).
      await _members.upsert(UserMapper.toSupabase(user));
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureVoidResult delete({
    required UserId id,
    required GymId gymId,
    required GymRoleType role,
  }) async {
    try {
      await _members.delete().eq('id', id.value).eq('gym_id', gymId.value);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al eliminar usuario: $e'));
    }
  }

  @override
  Future<bool> existsByEmail(Email email) async {
    try {
      final rows = await _members.select('id').ilike('email', email.value).limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  FutureResult<List<User>> searchByName({required String query, required GymId gymId}) async {
    try {
      final normalizedQuery = query.trim();
      final rows = await _members
          .select()
          .eq('gym_id', gymId.value)
          .eq('is_active', true)
          .or('first_name.ilike.%$normalizedQuery%,last_name.ilike.%$normalizedQuery%');
      return right(rows.map((r) => UserMapper.fromSupabase(r)).toList());
    } catch (e) {
      return left(ServerFailure(message: 'Error en búsqueda: $e'));
    }
  }

  @override
  FutureResult<List<User>> findPendingUsers(GymId gymId) async {
    try {
      final rows = await _members
          .select()
          .eq('gym_id', gymId.value)
          .eq('role', 'client')
          .eq('membership_status', 'pending');
      return right(rows.map((r) => UserMapper.fromSupabase(r)).toList());
    } catch (e) {
      return left(ServerFailure(message: 'Error de sincronización: $e'));
    }
  }
}
