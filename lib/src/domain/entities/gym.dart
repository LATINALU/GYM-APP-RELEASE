import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';

/// Financial settings for a gym
class GymFinanceConfig extends Equatable {
  final double monthlyPrice;
  final double annualDiscountPercentage;
  final double? specialPromoPercentage;
  final String? specialPromoDescription;
  final bool autoNotifyExpiration; // The requested 5-day notification toggle

  const GymFinanceConfig({
    this.monthlyPrice = 0.0,
    this.annualDiscountPercentage = 0.0,
    this.specialPromoPercentage,
    this.specialPromoDescription,
    this.autoNotifyExpiration = true,
  });

  GymFinanceConfig copyWith({
    double? monthlyPrice,
    double? annualDiscountPercentage,
    double? specialPromoPercentage,
    String? specialPromoDescription,
    bool? autoNotifyExpiration,
  }) {
    return GymFinanceConfig(
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      annualDiscountPercentage: annualDiscountPercentage ?? this.annualDiscountPercentage,
      specialPromoPercentage: specialPromoPercentage ?? this.specialPromoPercentage,
      specialPromoDescription: specialPromoDescription ?? this.specialPromoDescription,
      autoNotifyExpiration: autoNotifyExpiration ?? this.autoNotifyExpiration,
    );
  }

  @override
  List<Object?> get props => [
        monthlyPrice,
        annualDiscountPercentage,
        specialPromoPercentage,
        specialPromoDescription,
        autoNotifyExpiration,
      ];
}

/// Gym Entity - Represents a gym business in the multi-tenant system
class Gym extends Equatable {
  final GymId id;
  final GymCode code;
  final String name;
  final String? address;
  final PhoneNumber? phone;
  final String? logoUrl;
  final DateTime createdAt;
  final bool isActive;
  final GymFinanceConfig financeConfig;

  const Gym._({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
    required this.createdAt,
    this.isActive = true,
    this.financeConfig = const GymFinanceConfig(),
  });

  /// Factory: Create a new gym
  factory Gym.create({
    required String name,
    String? address,
    PhoneNumber? phone,
    String? logoUrl,
    GymFinanceConfig? financeConfig,
  }) {
    return Gym._(
      id: GymId.generate(),
      code: GymCode.generate(name),
      name: name,
      address: address,
      phone: phone,
      logoUrl: logoUrl,
      createdAt: DateTime.now(),
      isActive: true,
      financeConfig: financeConfig ?? const GymFinanceConfig(),
    );
  }

  /// Factory: Restore from storage
  factory Gym.restore({
    required GymId id,
    required GymCode code,
    required String name,
    String? address,
    PhoneNumber? phone,
    String? logoUrl,
    required DateTime createdAt,
    bool isActive = true,
    GymFinanceConfig? financeConfig,
  }) {
    return Gym._(
      id: id,
      code: code,
      name: name,
      address: address,
      phone: phone,
      logoUrl: logoUrl,
      createdAt: createdAt,
      isActive: isActive,
      financeConfig: financeConfig ?? const GymFinanceConfig(),
    );
  }

  Gym copyWith({
    String? name,
    String? address,
    PhoneNumber? phone,
    String? logoUrl,
    bool? isActive,
    GymFinanceConfig? financeConfig,
  }) {
    return Gym._(
      id: id,
      code: code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      financeConfig: financeConfig ?? this.financeConfig,
    );
  }

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Gym($id, $name)';
}
