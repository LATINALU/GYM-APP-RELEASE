/// Loyalty Program - Sistema de puntos y recompensas del gimnasio
import 'package:equatable/equatable.dart';

/// Razón de acumulación de puntos
enum PointsReason {
  checkIn('Check-in diario', 10, '🏋️'),
  classAttended('Clase grupal', 25, '👥'),
  referral('Referido exitoso', 100, '🤝'),
  monthlyStreak('Racha mensual', 50, '🔥'),
  birthdayBonus('Cumpleaños', 50, '🎂'),
  firstVisit('Primera visita', 20, '⭐'),
  surveyCompleted('Encuesta', 15, '📝'),
  socialShare('Compartir redes', 10, '📱'),
  earlyBird('Madrugador (antes 7am)', 5, '🌅'),
  nightOwl('Nocturno (después 9pm)', 5, '🌙'),
  specialEvent('Evento especial', 30, '🎉');

  final String displayName;
  final int points;
  final String icon;
  const PointsReason(this.displayName, this.points, this.icon);
}

/// Transacción de puntos
class PointsTransaction extends Equatable {
  final String id;
  final String memberId;
  final PointsReason reason;
  final int points;
  final DateTime timestamp;
  final String? description;
  final bool isRedemption; // true = gastó puntos, false = ganó puntos

  const PointsTransaction({
    required this.id,
    required this.memberId,
    required this.reason,
    required this.points,
    required this.timestamp,
    this.description,
    this.isRedemption = false,
  });

  @override
  List<Object?> get props => [id, memberId, timestamp];
}

/// Recompensa canjeable
class Reward extends Equatable {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String icon;
  final RewardCategory category;
  final bool isAvailable;
  final int? stockRemaining;
  final DateTime? expiryDate;
  final String? imageUrl;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    this.icon = '🎁',
    required this.category,
    this.isAvailable = true,
    this.stockRemaining,
    this.expiryDate,
    this.imageUrl,
  });

  /// ¿Hay stock?
  bool get hasStock => stockRemaining == null || stockRemaining! > 0;

  /// ¿Está expirado?
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// ¿Se puede canjear?
  bool get isRedeemable => isAvailable && hasStock && !isExpired;

  @override
  List<Object?> get props => [id, name, pointsCost];
}

/// Categoría de recompensa
enum RewardCategory {
  product('Productos', '🛍️'),
  service('Servicios', '💆'),
  membership('Membresía', '🎫'),
  discount('Descuentos', '💰'),
  experience('Experiencias', '🎉');

  final String displayName;
  final String icon;
  const RewardCategory(this.displayName, this.icon);
}

/// Estado de puntos del miembro
class MemberLoyaltyStatus extends Equatable {
  final String memberId;
  final int currentPoints;
  final int totalEarnedPoints;
  final int totalRedeemedPoints;
  final LoyaltyTier tier;
  final List<PointsTransaction> recentTransactions;
  final int currentStreak; // días consecutivos
  final int longestStreak;
  final DateTime? lastCheckIn;

  const MemberLoyaltyStatus({
    required this.memberId,
    required this.currentPoints,
    required this.totalEarnedPoints,
    required this.totalRedeemedPoints,
    required this.tier,
    this.recentTransactions = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckIn,
  });

  /// Puntos hasta próximo nivel
  int get pointsToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 500 - totalEarnedPoints;
      case LoyaltyTier.silver:
        return 1500 - totalEarnedPoints;
      case LoyaltyTier.gold:
        return 3000 - totalEarnedPoints;
      case LoyaltyTier.platinum:
        return 0; // Ya es máximo
    }
  }

  /// Progreso al siguiente nivel (0-100)
  double get tierProgress {
    switch (tier) {
      case LoyaltyTier.bronze:
        return (totalEarnedPoints / 500) * 100;
      case LoyaltyTier.silver:
        return ((totalEarnedPoints - 500) / 1000) * 100;
      case LoyaltyTier.gold:
        return ((totalEarnedPoints - 1500) / 1500) * 100;
      case LoyaltyTier.platinum:
        return 100;
    }
  }

  @override
  List<Object?> get props => [memberId, currentPoints, tier];
}

/// Tier de lealtad
enum LoyaltyTier {
  bronze('Bronce', '🥉', 0, '#CD7F32'),
  silver('Plata', '🥈', 500, '#C0C0C0'),
  gold('Oro', '🥇', 1500, '#FFD700'),
  platinum('Platino', '💎', 3000, '#E5E4E2');

  final String displayName;
  final String icon;
  final int requiredPoints;
  final String colorHex;
  const LoyaltyTier(this.displayName, this.icon, this.requiredPoints, this.colorHex);

  /// Beneficios por tier
  List<String> get benefits {
    switch (this) {
      case LoyaltyTier.bronze:
        return ['Puntos por check-in', 'Acceso a catálogo básico'];
      case LoyaltyTier.silver:
        return ['Todo de Bronce', '+10% puntos extra', 'Reserva prioritaria'];
      case LoyaltyTier.gold:
        return ['Todo de Plata', '+25% puntos extra', '1 clase gratis/mes', 'Locker preferente'];
      case LoyaltyTier.platinum:
        return ['Todo de Oro', '+50% puntos extra', '2 clases gratis/mes', 'Parking VIP', 'Acceso invitados'];
    }
  }
}

/// Código de referido
class ReferralCode extends Equatable {
  final String code;
  final String ownerId;
  final int timesUsed;
  final int maxUses;
  final int pointsPerReferral;
  final int bonusDaysForReferred;
  final bool isActive;

  const ReferralCode({
    required this.code,
    required this.ownerId,
    this.timesUsed = 0,
    this.maxUses = 10,
    this.pointsPerReferral = 100,
    this.bonusDaysForReferred = 7,
    this.isActive = true,
  });

  /// ¿Aún se puede usar?
  bool get isUsable => isActive && (maxUses == 0 || timesUsed < maxUses);

  @override
  List<Object?> get props => [code, ownerId];
}
