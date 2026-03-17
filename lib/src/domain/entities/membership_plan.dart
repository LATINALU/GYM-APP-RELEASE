import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';
import '../../../core/errors/exceptions.dart';

/// Duración del plan
enum PlanDuration {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannual,
  annual,
}

extension PlanDurationX on PlanDuration {
  String get displayName {
    switch (this) {
      case PlanDuration.daily: return 'Diario';
      case PlanDuration.weekly: return 'Semanal';
      case PlanDuration.biweekly: return 'Quincenal';
      case PlanDuration.monthly: return 'Mensual';
      case PlanDuration.quarterly: return 'Trimestral';
      case PlanDuration.semiannual: return 'Semestral';
      case PlanDuration.annual: return 'Anual';
    }
  }

  int get days {
    switch (this) {
      case PlanDuration.daily: return 1;
      case PlanDuration.weekly: return 7;
      case PlanDuration.biweekly: return 15;
      case PlanDuration.monthly: return 30;
      case PlanDuration.quarterly: return 90;
      case PlanDuration.semiannual: return 180;
      case PlanDuration.annual: return 365;
    }
  }
}

/// Membership Plan Entity - Planes de membresía del gimnasio
/// Creado por el Owner para su gym específico
class MembershipPlan extends Equatable {
  final PlanId id;
  final GymId gymId;
  final String name;
  final String? description;
  final double price;
  final PlanDuration duration;
  final int maxClasses;       // 0 = ilimitado
  final bool includesLocker;
  final bool includesShower;
  final bool includesParking;
  final bool includesPersonalTrainer;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MembershipPlan._({
    required this.id,
    required this.gymId,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.maxClasses = 0,
    this.includesLocker = false,
    this.includesShower = true,
    this.includesParking = false,
    this.includesPersonalTrainer = false,
    this.features = const [],
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create new plan
  factory MembershipPlan.create({
    required GymId gymId,
    required String name,
    String? description,
    required double price,
    required PlanDuration duration,
    int maxClasses = 0,
    bool includesLocker = false,
    bool includesShower = true,
    bool includesParking = false,
    bool includesPersonalTrainer = false,
    List<String> features = const [],
  }) {
    if (name.trim().isEmpty) {
      throw const DomainException(
        'El nombre del plan es requerido',
        code: 'INVALID_PLAN_NAME',
      );
    }
    if (price < 0) {
      throw const DomainException(
        'El precio no puede ser negativo',
        code: 'INVALID_PLAN_PRICE',
      );
    }

    return MembershipPlan._(
      id: PlanId.generate(),
      gymId: gymId,
      name: name.trim(),
      description: description?.trim(),
      price: price,
      duration: duration,
      maxClasses: maxClasses,
      includesLocker: includesLocker,
      includesShower: includesShower,
      includesParking: includesParking,
      includesPersonalTrainer: includesPersonalTrainer,
      features: features,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Restore from persistence
  factory MembershipPlan.restore({
    required PlanId id,
    required GymId gymId,
    required String name,
    String? description,
    required double price,
    required PlanDuration duration,
    int maxClasses = 0,
    bool includesLocker = false,
    bool includesShower = true,
    bool includesParking = false,
    bool includesPersonalTrainer = false,
    List<String> features = const [],
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipPlan._(
      id: id,
      gymId: gymId,
      name: name,
      description: description,
      price: price,
      duration: duration,
      maxClasses: maxClasses,
      includesLocker: includesLocker,
      includesShower: includesShower,
      includesParking: includesParking,
      includesPersonalTrainer: includesPersonalTrainer,
      features: features,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // === BEHAVIOR ===

  MembershipPlan updateInfo({
    String? name,
    String? description,
    double? price,
    PlanDuration? duration,
    int? maxClasses,
    bool? includesLocker,
    bool? includesShower,
    bool? includesParking,
    bool? includesPersonalTrainer,
    List<String>? features,
  }) {
    return MembershipPlan._(
      id: id,
      gymId: gymId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      maxClasses: maxClasses ?? this.maxClasses,
      includesLocker: includesLocker ?? this.includesLocker,
      includesShower: includesShower ?? this.includesShower,
      includesParking: includesParking ?? this.includesParking,
      includesPersonalTrainer: includesPersonalTrainer ?? this.includesPersonalTrainer,
      features: features ?? this.features,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  MembershipPlan deactivate() => MembershipPlan._(
    id: id, gymId: gymId, name: name, description: description,
    price: price, duration: duration, maxClasses: maxClasses,
    includesLocker: includesLocker, includesShower: includesShower,
    includesParking: includesParking, includesPersonalTrainer: includesPersonalTrainer,
    features: features, isActive: false, createdAt: createdAt, updatedAt: DateTime.now(),
  );

  MembershipPlan activate() => MembershipPlan._(
    id: id, gymId: gymId, name: name, description: description,
    price: price, duration: duration, maxClasses: maxClasses,
    includesLocker: includesLocker, includesShower: includesShower,
    includesParking: includesParking, includesPersonalTrainer: includesPersonalTrainer,
    features: features, isActive: true, createdAt: createdAt, updatedAt: DateTime.now(),
  );

  // === COMPUTED ===

  bool get isUnlimitedClasses => maxClasses == 0;
  String get priceDisplay => '\$${price.toStringAsFixed(2)}';
  String get durationDisplay => duration.displayName;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'MembershipPlan($id, $name, $priceDisplay/${duration.displayName})';
}
