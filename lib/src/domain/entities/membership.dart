/// Membership Domain Entity - Corazón del negocio del gimnasio
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de membresía disponible
enum MembershipTier {
  basic,
  standard,
  premium,
  black,
  student,
  corporate,
  dayPass;

  String get displayName {
    switch (this) {
      case MembershipTier.basic: return 'Básica';
      case MembershipTier.standard: return 'Estándar';
      case MembershipTier.premium: return 'Premium';
      case MembershipTier.black: return 'Black';
      case MembershipTier.student: return 'Estudiante';
      case MembershipTier.corporate: return 'Corporativa';
      case MembershipTier.dayPass: return 'Pase Diario';
    }
  }

  String get icon {
    switch (this) {
      case MembershipTier.basic: return '🏃';
      case MembershipTier.standard: return '💪';
      case MembershipTier.premium: return '⭐';
      case MembershipTier.black: return '👑';
      case MembershipTier.student: return '📚';
      case MembershipTier.corporate: return '🏢';
      case MembershipTier.dayPass: return '🎟️';
    }
  }

  String get colorHex {
    switch (this) {
      case MembershipTier.basic: return '#6B7280';
      case MembershipTier.standard: return '#3B82F6';
      case MembershipTier.premium: return '#8B5CF6';
      case MembershipTier.black: return '#F59E0B';
      case MembershipTier.student: return '#10B981';
      case MembershipTier.corporate: return '#0EA5E9';
      case MembershipTier.dayPass: return '#EC4899';
    }
  }

  int get sortOrder {
    switch (this) {
      case MembershipTier.dayPass: return 0;
      case MembershipTier.basic: return 1;
      case MembershipTier.student: return 2;
      case MembershipTier.standard: return 3;
      case MembershipTier.premium: return 4;
      case MembershipTier.corporate: return 5;
      case MembershipTier.black: return 6;
    }
  }
}

/// Estado de la suscripción de membresía
enum SubscriptionStatus {
  active,
  expired,
  suspended,
  cancelled,
  pending,
  frozen;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active: return 'Activa';
      case SubscriptionStatus.expired: return 'Vencida';
      case SubscriptionStatus.suspended: return 'Suspendida';
      case SubscriptionStatus.cancelled: return 'Cancelada';
      case SubscriptionStatus.pending: return 'Pendiente';
      case SubscriptionStatus.frozen: return 'Congelada';
    }
  }

  String get colorHex {
    switch (this) {
      case SubscriptionStatus.active: return '#10B981';
      case SubscriptionStatus.expired: return '#EF4444';
      case SubscriptionStatus.suspended: return '#F59E0B';
      case SubscriptionStatus.cancelled: return '#6B7280';
      case SubscriptionStatus.pending: return '#3B82F6';
      case SubscriptionStatus.frozen: return '#06B6D4';
    }
  }

  IconData get icon {
    switch (this) {
      case SubscriptionStatus.active: return Icons.check_circle;
      case SubscriptionStatus.expired: return Icons.cancel;
      case SubscriptionStatus.suspended: return Icons.pause_circle;
      case SubscriptionStatus.cancelled: return Icons.block;
      case SubscriptionStatus.pending: return Icons.hourglass_top;
      case SubscriptionStatus.frozen: return Icons.ac_unit;
    }
  }
}


/// Ciclo de facturación
enum BillingCycle {
  daily,
  weekly,
  monthly,
  quarterly,
  semiannual,
  annual;

  String get displayName {
    switch (this) {
      case BillingCycle.daily: return 'Diario';
      case BillingCycle.weekly: return 'Semanal';
      case BillingCycle.monthly: return 'Mensual';
      case BillingCycle.quarterly: return 'Trimestral';
      case BillingCycle.semiannual: return 'Semestral';
      case BillingCycle.annual: return 'Anual';
    }
  }

  int get durationDays {
    switch (this) {
      case BillingCycle.daily: return 1;
      case BillingCycle.weekly: return 7;
      case BillingCycle.monthly: return 30;
      case BillingCycle.quarterly: return 90;
      case BillingCycle.semiannual: return 180;
      case BillingCycle.annual: return 365;
    }
  }

  int get discountPercent {
    switch (this) {
      case BillingCycle.daily: return 0;
      case BillingCycle.weekly: return 0;
      case BillingCycle.monthly: return 0;
      case BillingCycle.quarterly: return 10;
      case BillingCycle.semiannual: return 15;
      case BillingCycle.annual: return 25;
    }
  }
}

/// Método de pago
enum PaymentMethod {
  creditCard,
  debitCard,
  cash,
  bankTransfer,
  paypal,
  mercadoPago,
  stripe;

  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard: return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard: return 'Tarjeta de Débito';
      case PaymentMethod.cash: return 'Efectivo';
      case PaymentMethod.bankTransfer: return 'Transferencia';
      case PaymentMethod.paypal: return 'PayPal';
      case PaymentMethod.mercadoPago: return 'MercadoPago';
      case PaymentMethod.stripe: return 'Stripe';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.creditCard: return '💳';
      case PaymentMethod.debitCard: return '💳';
      case PaymentMethod.cash: return '💵';
      case PaymentMethod.bankTransfer: return '🏦';
      case PaymentMethod.paypal: return '🅿️';
      case PaymentMethod.mercadoPago: return '🛒';
      case PaymentMethod.stripe: return '💰';
    }
  }
}

/// Tipo de plan de membresía con características y precios
class MembershipPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final MembershipTier tier;
  final double monthlyPrice;
  final List<String> features;
  final List<String> restrictions;
  final List<GymZoneAccess> zoneAccess;
  final int maxClassBookingsPerMonth;
  final int maxGuestPassesPerMonth;
  final bool includesLocker;
  final bool includesTowelService;
  final bool includesPersonalTrainer;
  final int personalTrainerSessionsPerMonth;
  final String? accessSchedule; // "06:00-22:00" or "24/7"
  final bool isActive;
  final bool isPopular;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.monthlyPrice,
    required this.features,
    this.restrictions = const [],
    this.zoneAccess = const [],
    this.maxClassBookingsPerMonth = 0,
    this.maxGuestPassesPerMonth = 0,
    this.includesLocker = false,
    this.includesTowelService = false,
    this.includesPersonalTrainer = false,
    this.personalTrainerSessionsPerMonth = 0,
    this.accessSchedule,
    this.isActive = true,
    this.isPopular = false,
  });

  double getPriceForCycle(BillingCycle cycle) {
    final basePrice = monthlyPrice * (cycle.durationDays / 30);
    final discount = basePrice * (cycle.discountPercent / 100);
    return basePrice - discount;
  }

  String get formattedMonthlyPrice => '\$${monthlyPrice.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, tier, monthlyPrice];
}

/// Zonas del gym con acceso controlado
enum GymZoneAccess {
  mainFloor,
  cardioZone,
  weightsArea,
  groupClasses,
  crossfitBox,
  functionalArea,
  stretching,
  recoveryRoom,
  spa,
  sauna,
  pool,
  vipLounge;

  String get displayName {
    switch (this) {
      case GymZoneAccess.mainFloor: return 'Sala Principal';
      case GymZoneAccess.cardioZone: return 'Zona Cardio';
      case GymZoneAccess.weightsArea: return 'Zona de Pesas';
      case GymZoneAccess.groupClasses: return 'Clases Grupales';
      case GymZoneAccess.crossfitBox: return 'Box CrossFit';
      case GymZoneAccess.functionalArea: return 'Área Funcional';
      case GymZoneAccess.stretching: return 'Área de Estiramiento';
      case GymZoneAccess.recoveryRoom: return 'Sala de Recuperación';
      case GymZoneAccess.spa: return 'Spa';
      case GymZoneAccess.sauna: return 'Sauna';
      case GymZoneAccess.pool: return 'Piscina';
      case GymZoneAccess.vipLounge: return 'Lounge VIP';
    }
  }

  String get icon {
    switch (this) {
      case GymZoneAccess.mainFloor: return '🏋️';
      case GymZoneAccess.cardioZone: return '🏃';
      case GymZoneAccess.weightsArea: return '💪';
      case GymZoneAccess.groupClasses: return '👥';
      case GymZoneAccess.crossfitBox: return '🔥';
      case GymZoneAccess.functionalArea: return '🤸';
      case GymZoneAccess.stretching: return '🧘';
      case GymZoneAccess.recoveryRoom: return '🛏️';
      case GymZoneAccess.spa: return '💆';
      case GymZoneAccess.sauna: return '🧖';
      case GymZoneAccess.pool: return '🏊';
      case GymZoneAccess.vipLounge: return '🍸';
    }
  }
}

/// Membresía activa de un miembro
class MemberMembership extends Equatable {
  final String id;
  final String memberId;
  final String planId;
  final MembershipPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? suspendedUntil;
  final String? suspensionReason;
  final BillingCycle billingCycle;
  final double paidAmount;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;
  final bool autoRenew;
  final String? lockerNumber;
  final int classBookingsUsed;
  final int guestPassesUsed;
  final List<PaymentRecord> paymentHistory;

  const MemberMembership({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.suspendedUntil,
    this.suspensionReason,
    this.billingCycle = BillingCycle.monthly,
    this.paidAmount = 0,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.autoRenew = true,
    this.lockerNumber,
    this.classBookingsUsed = 0,
    this.guestPassesUsed = 0,
    this.paymentHistory = const [],
  });

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => status == SubscriptionStatus.active && !isExpired;
  bool get isFrozen => status == SubscriptionStatus.frozen;

  int get classBookingsRemaining => 
      plan.maxClassBookingsPerMonth - classBookingsUsed;
  
  int get guestPassesRemaining => 
      plan.maxGuestPassesPerMonth - guestPassesUsed;

  double get totalPaid => paymentHistory.fold(0, (sum, p) => sum + p.amount);

  MemberMembership copyWith({
    SubscriptionStatus? status,
    DateTime? endDate,
    DateTime? suspendedUntil,
    String? suspensionReason,
    bool? autoRenew,
    int? classBookingsUsed,
    int? guestPassesUsed,
    List<PaymentRecord>? paymentHistory,
  }) {
    return MemberMembership(
      id: id,
      memberId: memberId,
      planId: planId,
      plan: plan,
      status: status ?? this.status,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      billingCycle: billingCycle,
      paidAmount: paidAmount,
      lastPaymentDate: lastPaymentDate,
      nextPaymentDate: nextPaymentDate,
      autoRenew: autoRenew ?? this.autoRenew,
      lockerNumber: lockerNumber,
      classBookingsUsed: classBookingsUsed ?? this.classBookingsUsed,
      guestPassesUsed: guestPassesUsed ?? this.guestPassesUsed,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  @override
  List<Object?> get props => [id, memberId, planId, status, endDate];
}

/// Estado del pago
enum PaymentRecordStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled;

  String get displayName {
    switch (this) {
      case PaymentRecordStatus.pending: return 'Pendiente';
      case PaymentRecordStatus.completed: return 'Completado';
      case PaymentRecordStatus.failed: return 'Fallido';
      case PaymentRecordStatus.refunded: return 'Reembolsado';
      case PaymentRecordStatus.cancelled: return 'Cancelado';
    }
  }

  String get colorHex {
    switch (this) {
      case PaymentRecordStatus.pending: return '#F59E0B';
      case PaymentRecordStatus.completed: return '#10B981';
      case PaymentRecordStatus.failed: return '#EF4444';
      case PaymentRecordStatus.refunded: return '#6B7280';
      case PaymentRecordStatus.cancelled: return '#6B7280';
    }
  }
}

/// Registro de pago
class PaymentRecord extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String description;
  final PaymentRecordStatus status;
  final String? transactionId;
  final String? receiptUrl;
  final String? notes;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    required this.description,
    this.status = PaymentRecordStatus.completed,
    this.transactionId,
    this.receiptUrl,
    this.notes,
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  @override
  List<Object?> get props => [id, amount, date, status];
}

/// Sistema de congelamiento de membresía
class MembershipFreeze extends Equatable {
  final String id;
  final String membershipId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final FreezeReason freezeType;
  final bool isApproved;
  final DateTime? approvedAt;
  final String? approvedBy;

  const MembershipFreeze({
    required this.id,
    required this.membershipId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.freezeType,
    this.isApproved = false,
    this.approvedAt,
    this.approvedBy,
  });

  int get totalDays => endDate.difference(startDate).inDays;
  bool get isActive => 
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  @override
  List<Object?> get props => [id, membershipId, startDate, endDate];
}

enum FreezeReason {
  vacation,
  medical,
  travel,
  personal,
  other;

  String get displayName {
    switch (this) {
      case FreezeReason.vacation: return 'Vacaciones';
      case FreezeReason.medical: return 'Razones Médicas';
      case FreezeReason.travel: return 'Viaje';
      case FreezeReason.personal: return 'Personal';
      case FreezeReason.other: return 'Otro';
    }
  }

  int get maxDaysAllowed {
    switch (this) {
      case FreezeReason.vacation: return 14;
      case FreezeReason.medical: return 90;
      case FreezeReason.travel: return 30;
      case FreezeReason.personal: return 7;
      case FreezeReason.other: return 7;
    }
  }
}

/// Sistema de cargos adicionales
class MemberCharge extends Equatable {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String description;
  final ChargeType type;
  final bool isPaid;
  final DateTime? paidAt;
  final String? relatedItemId;

  const MemberCharge({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
    this.isPaid = false,
    this.paidAt,
    this.relatedItemId,
  });

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, memberId, amount, date, type];
}

enum ChargeType {
  membership,
  personalTraining,
  classPackage,
  storeProduct,
  lockerRental,
  lateFee,
  other;

  String get displayName {
    switch (this) {
      case ChargeType.membership: return 'Membresía';
      case ChargeType.personalTraining: return 'Entrenamiento Personal';
      case ChargeType.classPackage: return 'Paquete de Clases';
      case ChargeType.storeProduct: return 'Producto Tienda';
      case ChargeType.lockerRental: return 'Alquiler Locker';
      case ChargeType.lateFee: return 'Cargo por Mora';
      case ChargeType.other: return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case ChargeType.membership: return '💳';
      case ChargeType.personalTraining: return '🏋️';
      case ChargeType.classPackage: return '📦';
      case ChargeType.storeProduct: return '🛍️';
      case ChargeType.lockerRental: return '🔐';
      case ChargeType.lateFee: return '⚠️';
      case ChargeType.other: return '📋';
    }
  }
}

/// Estado de cuenta del miembro
class MemberStatement {
  final String memberId;
  final DateTime generatedAt;
  final List<MemberCharge> pendingCharges;
  final List<PaymentRecord> recentPayments;
  final double currentBalance;
  final double creditBalance;

  const MemberStatement({
    required this.memberId,
    required this.generatedAt,
    required this.pendingCharges,
    required this.recentPayments,
    required this.currentBalance,
    this.creditBalance = 0,
  });

  double get totalPending => pendingCharges
      .where((c) => !c.isPaid)
      .fold(0, (sum, c) => sum + c.amount);

  double get netBalance => totalPending - creditBalance;

  bool get hasDebt => netBalance > 0;
}
