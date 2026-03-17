import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/access_code_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of AccessCodeRepositoryPort
class InsForgeAccessCodeRepository implements AccessCodeRepositoryPort {
  final InsForgeClient _client;

  InsForgeAccessCodeRepository(this._client);

  @override
  FutureResult<AccessCode> generate({
    required GymId gymId,
    required AccessCodeType type,
    required UserId generatedBy,
    int length = 8,
    int expirationMinutes = 30,
  }) async {
    try {
      final code = _generateCode(length);
      final expiresAt = DateTime.now().add(Duration(minutes: expirationMinutes));

      final response = await _client.insert('access_codes', {
        'code': code,
        'gym_id': gymId.value,
        'type': type.name,
        'generated_by': generatedBy.value,
        'expires_at': expiresAt.toIso8601String(),
      });

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error generando código'));
      }

      final savedData = response.firstItem ?? {'id': '', 'code': code, 'created_at': DateTime.now().toIso8601String()};
      return Right(_map(savedData, gymId, type, generatedBy, expiresAt, code));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<AccessCode> validateAndConsume({required String code, required UserId consumedBy}) async {
    try {
      final response = await _client.from('access_codes',
          query: 'code=eq.$code&is_used=eq.false&is_revoked=eq.false&select=*');

      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Código no encontrado o ya utilizado'));
      }

      final data = response.firstItem!;
      final expiresAt = DateTime.parse(data['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        return const Left(ValidationFailure(message: 'Código expirado'));
      }

      // Mark as used
      await _client.update('access_codes', {
        'is_used': true,
        'consumed_by': consumedBy.value,
        'used_at': DateTime.now().toIso8601String(),
      }, 'code=eq.$code');

      return Right(_mapFromData(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<AccessCode> findByCode(String code) async {
    try {
      final response = await _client.from('access_codes', query: 'code=eq.$code&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Código no encontrado'));
      }
      return Right(_mapFromData(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<AccessCode>> findActiveByGymId(GymId gymId) async {
    try {
      final response = await _client.from('access_codes',
          query: 'gym_id=eq.${gymId.value}&is_used=eq.false&is_revoked=eq.false&expires_at=gt.${DateTime.now().toIso8601String()}&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _mapFromData(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult revoke(String code) async {
    try {
      final response = await _client.update('access_codes', {'is_revoked': true}, 'code=eq.$code');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult revokeAllForGym(GymId gymId) async {
    try {
      final response = await _client.update('access_codes',
          {'is_revoked': true}, 'gym_id=eq.${gymId.value}&is_used=eq.false&is_revoked=eq.false');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult cleanupExpired() async {
    try {
      await _client.delete('access_codes',
          'expires_at=lt.${DateTime.now().toIso8601String()}&is_used=eq.false');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getUsageStats(GymId gymId) async {
    try {
      final allResp = await _client.from('access_codes', query: 'gym_id=eq.${gymId.value}&select=id,is_used,is_revoked');
      final total = allResp.dataList.length;
      final used = allResp.dataList.where((e) => (e as Map)['is_used'] == true).length;
      final revoked = allResp.dataList.where((e) => (e as Map)['is_revoked'] == true).length;
      return Right({'total': total, 'used': used, 'revoked': revoked, 'active': total - used - revoked});
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  AccessCode _map(Map<String, dynamic> data, GymId gymId, AccessCodeType type, UserId generatedBy, DateTime expiresAt, String code) {
    return AccessCode.restore(
      value: code,
      type: type,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: expiresAt,
    );
  }

  AccessCodeType _parseType(String typeStr) {
    switch (typeStr) {
      case 'gymEntry': return AccessCodeType.gymEntry;
      case 'ownerVerification': return AccessCodeType.ownerVerification;
      case 'employeeInvitation': return AccessCodeType.employeeInvitation;
      case 'memberOnboarding': return AccessCodeType.memberOnboarding;
      case 'passwordReset': return AccessCodeType.passwordReset;
      case 'twoFactorAuth': return AccessCodeType.twoFactorAuth;
      default: return AccessCodeType.memberOnboarding;
    }
  }

  AccessCode _mapFromData(Map<String, dynamic> data) {
    final type = _parseType(data['type'] as String? ?? 'memberOnboarding');

    return AccessCode.restore(
      value: data['code'] as String,
      type: type,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.parse(data['expires_at'] as String),
      isUsed: data['is_used'] as bool? ?? false,
      usedBy: data['consumed_by'] as String?,
      usedAt: data['used_at'] != null ? DateTime.tryParse(data['used_at'] as String) : null,
    );
  }
}
