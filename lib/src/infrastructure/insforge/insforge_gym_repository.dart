import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/gym_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of GymRepositoryPort
class InsForgeGymRepository implements GymRepositoryPort {
  final InsForgeClient _client;

  InsForgeGymRepository(this._client);

  @override
  FutureResult<GymId> save(Gym gym) async {
    try {
      final response = await _client.insert('gyms', {
        'id': gym.id.value,
        'code': gym.code.value,
        'name': gym.name,
        'address': gym.address,
        'phone': gym.phone?.value,
        'logo_url': gym.logoUrl,
        'is_active': gym.isActive,
        'finance_config': {
          'monthlyPrice': gym.financeConfig.monthlyPrice,
          'annualDiscountPercentage': gym.financeConfig.annualDiscountPercentage,
          'specialPromoPercentage': gym.financeConfig.specialPromoPercentage,
          'specialPromoDescription': gym.financeConfig.specialPromoDescription,
          'autoNotifyExpiration': gym.financeConfig.autoNotifyExpiration,
        },
      });

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error creando gimnasio'));
      }

      return Right(gym.id);
    } catch (e) {
      debugPrint('[InsForgeGym] save error: $e');
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<Gym> findById(GymId id) async {
    try {
      final response = await _client.from('gyms', query: 'id=eq.${id.value}&select=*');

      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Gimnasio no encontrado'));
      }

      return Right(_mapGym(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<void> update(Gym gym) async {
    try {
      final response = await _client.update('gyms', {
        'name': gym.name,
        'address': gym.address,
        'phone': gym.phone?.value,
        'logo_url': gym.logoUrl,
        'is_active': gym.isActive,
        'finance_config': {
          'monthlyPrice': gym.financeConfig.monthlyPrice,
          'annualDiscountPercentage': gym.financeConfig.annualDiscountPercentage,
          'specialPromoPercentage': gym.financeConfig.specialPromoPercentage,
          'specialPromoDescription': gym.financeConfig.specialPromoDescription,
          'autoNotifyExpiration': gym.financeConfig.autoNotifyExpiration,
        },
      }, 'id=eq.${gym.id.value}');

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error actualizando gimnasio'));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<Gym>> findAll() async {
    try {
      final response = await _client.from('gyms', query: 'select=*&order=created_at.desc');

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo gimnasios'));
      }

      final gyms = response.dataList.map((g) => _mapGym(g as Map<String, dynamic>)).toList();
      return Right(gyms);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<void> deactivate(GymId id) async {
    try {
      final response = await _client.update('gyms', {'is_active': false}, 'id=eq.${id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error desactivando gimnasio'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getStats(GymId id) async {
    try {
      // Get member count
      final membersResp = await _client.from('users',
          query: 'gym_id=eq.${id.value}&role=eq.client&is_active=eq.true&select=id');
      final staffResp = await _client.from('users',
          query: 'gym_id=eq.${id.value}&role=eq.employee&is_active=eq.true&select=id');
      final checkInsResp = await _client.from('check_ins',
          query: 'gym_id=eq.${id.value}&check_in_time=gte.${DateTime.now().toIso8601String().substring(0, 10)}&select=id');

      return Right({
        'members': membersResp.dataList.length,
        'staff': staffResp.dataList.length,
        'todayCheckIns': checkInsResp.dataList.length,
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Error obteniendo estadísticas: $e'));
    }
  }

  @override
  FutureResult<List<Map<String, dynamic>>> getDailyMetrics({
    required GymId id,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _client.from('check_ins',
          query: 'gym_id=eq.${id.value}&check_in_time=gte.${start.toIso8601String()}&check_in_time=lte.${end.toIso8601String()}&select=check_in_time');

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo métricas'));
      }

      // Group by date
      final Map<String, int> grouped = {};
      for (final item in response.dataList) {
        final date = (item['check_in_time'] as String).substring(0, 10);
        grouped[date] = (grouped[date] ?? 0) + 1;
      }

      final metrics = grouped.entries.map((e) => {'date': e.key, 'checkIns': e.value}).toList();
      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<Gym> findByCode(GymCode code) async {
    try {
      final response = await _client.from('gyms', query: 'code=eq.${code.value}&select=*');

      if (!response.isSuccess || response.dataList.isEmpty) {
        return Left(NotFoundFailure(message: 'Gimnasio con código ${code.value} no encontrado'));
      }

      return Right(_mapGym(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPER
  // ═══════════════════════════════════════════════════════════════════

  Gym _mapGym(Map<String, dynamic> data) {
    final financeData = data['finance_config'] as Map<String, dynamic>? ?? {};

    return Gym.restore(
      id: GymId(data['id'] as String),
      code: GymCode(data['code'] as String),
      name: data['name'] as String,
      address: data['address'] as String?,
      phone: data['phone'] != null ? PhoneNumber(data['phone'] as String) : null,
      logoUrl: data['logo_url'] as String?,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      isActive: data['is_active'] as bool? ?? true,
      financeConfig: GymFinanceConfig(
        monthlyPrice: (financeData['monthlyPrice'] as num?)?.toDouble() ?? 0,
        annualDiscountPercentage: (financeData['annualDiscountPercentage'] as num?)?.toDouble() ?? 0,
        specialPromoPercentage: (financeData['specialPromoPercentage'] as num?)?.toDouble(),
        specialPromoDescription: financeData['specialPromoDescription'] as String?,
        autoNotifyExpiration: financeData['autoNotifyExpiration'] as bool? ?? true,
      ),
    );
  }
}
