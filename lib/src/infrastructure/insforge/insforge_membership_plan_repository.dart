import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/value_objects/value_objects.dart';
import 'insforge_client.dart';

/// InsForge repository for MembershipPlan CRUD
/// No port interface exists yet, so this is a standalone repository
class InsForgeMembershipPlanRepository {
  final InsForgeClient _client;

  InsForgeMembershipPlanRepository(this._client);

  /// Get all plans for a gym
  FutureResult<List<MembershipPlan>> findByGymId(GymId gymId) async {
    try {
      final response = await _client.from('membership_plans',
          query: 'gym_id=eq.${gymId.value}&select=*&order=price.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo planes'));
      }
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Get active plans for a gym
  FutureResult<List<MembershipPlan>> findActiveByGymId(GymId gymId) async {
    try {
      final response = await _client.from('membership_plans',
          query: 'gym_id=eq.${gymId.value}&is_active=eq.true&select=*&order=price.asc');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error obteniendo planes'));
      }
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Get plan by ID
  FutureResult<MembershipPlan> findById(PlanId id) async {
    try {
      final response = await _client.from('membership_plans', query: 'id=eq.${id.value}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Plan no encontrado'));
      }
      return Right(_map(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Create a new plan
  FutureResult<MembershipPlan> save(MembershipPlan plan) async {
    try {
      final response = await _client.insert('membership_plans', _toMap(plan));
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error creando plan'));
      }
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Update a plan
  FutureVoidResult update(MembershipPlan plan) async {
    try {
      final response = await _client.update('membership_plans', _toMap(plan), 'id=eq.${plan.id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error actualizando plan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Activate/deactivate a plan
  FutureVoidResult setActive(PlanId id, bool isActive) async {
    try {
      final response = await _client.update('membership_plans', {'is_active': isActive}, 'id=eq.${id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error cambiando estado del plan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  /// Delete a plan (hard delete)
  FutureVoidResult delete(PlanId id) async {
    try {
      final response = await _client.delete('membership_plans', 'id=eq.${id.value}');
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error eliminando plan'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPERS
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> _toMap(MembershipPlan plan) {
    return {
      'id': plan.id.value,
      'gym_id': plan.gymId.value,
      'name': plan.name,
      'description': plan.description,
      'price': plan.price,
      'duration': plan.duration.name,
      'max_classes': plan.maxClasses,
      'includes_locker': plan.includesLocker,
      'includes_shower': plan.includesShower,
      'includes_parking': plan.includesParking,
      'includes_personal_trainer': plan.includesPersonalTrainer,
      'features': plan.features,
      'is_active': plan.isActive,
    };
  }

  MembershipPlan _map(Map<String, dynamic> data) {
    final durationStr = data['duration'] as String? ?? 'monthly';
    PlanDuration duration;
    switch (durationStr) {
      case 'daily': duration = PlanDuration.daily; break;
      case 'weekly': duration = PlanDuration.weekly; break;
      case 'biweekly': duration = PlanDuration.biweekly; break;
      case 'quarterly': duration = PlanDuration.quarterly; break;
      case 'semiannual': duration = PlanDuration.semiannual; break;
      case 'annual': duration = PlanDuration.annual; break;
      default: duration = PlanDuration.monthly;
    }

    final features = (data['features'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return MembershipPlan.restore(
      id: PlanId(data['id'] as String),
      gymId: GymId(data['gym_id'] as String),
      name: data['name'] as String,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      duration: duration,
      maxClasses: data['max_classes'] as int? ?? 0,
      includesLocker: data['includes_locker'] as bool? ?? false,
      includesShower: data['includes_shower'] as bool? ?? true,
      includesParking: data['includes_parking'] as bool? ?? false,
      includesPersonalTrainer: data['includes_personal_trainer'] as bool? ?? false,
      features: features,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at'] as String) : null,
    );
  }
}
