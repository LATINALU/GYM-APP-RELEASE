import 'package:dartz/dartz.dart';
import 'package:supabase/supabase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/ports/output/access_code_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/access_code_mapper.dart';

/// Fase 2 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseAccessCodeRepository], respaldado por `public.access_codes`
/// (ver supabase/migrations/0006_access_codes.sql). A diferencia del
/// adaptador Firebase, una sola tabla alcanza (sin doble escritura
/// global + por-gym), ver comentario en la migración.
class SupabaseAccessCodeRepository implements AccessCodeRepositoryPort {
  final SupabaseClient _client;
  SupabaseAccessCodeRepository(this._client);

  SupabaseQueryBuilder get _codes => _client.from('access_codes');

  @override
  FutureResult<AccessCode> generate({
    required GymId gymId,
    required AccessCodeType type,
    required UserId generatedBy,
    int length = 8,
    int expirationMinutes = 30,
  }) async {
    try {
      final code = AccessCode.generate(
        type: type,
        length: length,
        expirationMinutes: expirationMinutes,
      );
      await _codes.insert(
        AccessCodeMapper.toSupabase(
          code,
          gymId: gymId.value,
          generatedBy: generatedBy.value,
        ),
      );
      return Right(code);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al generar código: $e'));
    }
  }

  @override
  FutureResult<AccessCode> validateAndConsume({
    required String code,
    required UserId consumedBy,
  }) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final row = await _codes.select().eq('value', sanitized).maybeSingle();
      if (row == null) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }

      final accessCode = AccessCodeMapper.fromSupabase(row);
      if (accessCode.isUsed) {
        return const Left(ServerFailure(message: 'Este código ya fue utilizado'));
      }
      if (accessCode.isExpired) {
        return const Left(ServerFailure(message: 'Este código ha expirado'));
      }

      final consumed = accessCode.consume(consumedBy.value);
      await _codes.update({
        'is_used': true,
        'used_by': consumedBy.value,
        'used_at': DateTime.now().toIso8601String(),
      }).eq('value', sanitized);

      return Right(consumed);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al validar código: $e'));
    }
  }

  @override
  FutureResult<AccessCode> findByCode(String code) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final row = await _codes.select().eq('value', sanitized).maybeSingle();
      if (row == null) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }
      return Right(AccessCodeMapper.fromSupabase(row));
    } catch (e) {
      return Left(ServerFailure(message: 'Error al buscar código: $e'));
    }
  }

  @override
  FutureResult<List<AccessCode>> findActiveByGymId(GymId gymId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final rows = await _codes
          .select()
          .eq('gym_id', gymId.value)
          .eq('is_used', false)
          .gt('expires_at', now);
      return Right(rows.map((r) => AccessCodeMapper.fromSupabase(r)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener códigos activos: $e'));
    }
  }

  @override
  FutureVoidResult revoke(String code) async {
    try {
      final sanitized = code.trim().toUpperCase();
      final row = await _codes.select().eq('value', sanitized).maybeSingle();
      if (row == null) {
        return const Left(ServerFailure(message: 'Código no encontrado'));
      }
      await _codes.update({
        'is_used': true,
        'used_by': '_REVOKED_',
        'used_at': DateTime.now().toIso8601String(),
      }).eq('value', sanitized);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al revocar código: $e'));
    }
  }

  @override
  FutureVoidResult revokeAllForGym(GymId gymId) async {
    try {
      await _codes.update({
        'is_used': true,
        'used_by': '_REVOKED_BULK_',
        'used_at': DateTime.now().toIso8601String(),
      }).eq('gym_id', gymId.value).eq('is_used', false);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al revocar códigos: $e'));
    }
  }

  @override
  FutureVoidResult cleanupExpired() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _codes.delete().eq('is_used', false).lt('expires_at', now);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error al limpiar códigos: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getUsageStats(GymId gymId) async {
    try {
      final rows = await _codes.select().eq('gym_id', gymId.value);
      final total = rows.length;
      final now = DateTime.now();
      final used = rows.where((r) => r['is_used'] == true).length;
      final active = rows.where((r) {
        final isUsed = r['is_used'] == true;
        final expiresAt = DateTime.tryParse(r['expires_at']?.toString() ?? '');
        return !isUsed && expiresAt != null && expiresAt.isAfter(now);
      }).length;

      return Right({
        'total': total,
        'used': used,
        'active': active,
        'expired': total - used - active,
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Error al obtener estadísticas: $e'));
    }
  }
}
