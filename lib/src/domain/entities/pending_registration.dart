import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';

/// Status of a pending registration request
enum RegistrationStatus {
  /// Waiting for gym owner/admin to review
  pendingReview('Pendiente de Revisión'),

  /// Approved by gym owner/admin
  approved('Aprobado'),

  /// Rejected by gym owner/admin
  rejected('Rechazado'),

  /// Expired (no action taken within time limit)
  expired('Expirado'),

  /// User cancelled their own request
  cancelled('Cancelado');

  final String displayName;
  const RegistrationStatus(this.displayName);
}

/// Source of how the user requested to join
enum RegistrationSource {
  /// User scanned gym's QR code
  qrScan('Escaneo QR'),

  /// User entered gym code manually
  manualCode('Código Manual'),

  /// User was invited by owner/staff
  invitation('Invitación'),

  /// User found gym through in-app search
  appSearch('Búsqueda en App'),

  /// Transferred from another gym
  transfer('Transferencia');

  final String displayName;
  const RegistrationSource(this.displayName);
}

/// Pending Registration Entity
/// 
/// Represents a user who has registered in the platform but has NOT yet
/// been accepted by any gym. These users sit in a "pre-approval" queue.
/// 
/// Flow: 
/// 1. User downloads app & creates account → goes to global `pending_registrations`
/// 2. User enters gym code or scans QR → registration request sent to specific gym
/// 3. Gym owner/admin reviews the request → Approve/Reject
/// 4. If approved → User moved to gym's member collection with role
/// 5. If rejected → User stays in pending_registrations, can try another gym
class PendingRegistration extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhone;
  final String? userPhotoUrl;
  
  /// The gym this registration targets
  final String? targetGymId;
  final String? targetGymName;
  final String? targetGymCode;
  
  /// Access code used to request registration
  final String? accessCodeUsed;
  
  /// Status of this registration
  final RegistrationStatus status;
  
  /// How the user got to this registration
  final RegistrationSource source;
  
  /// Additional info provided by the user
  final String? message; // "Quiero inscribirme, ya entrené aquí antes"
  final String? fitnessGoal;
  final double? weight;
  final double? height;
  
  /// Review info
  final String? reviewedBy; // UserId or name of who reviewed
  final DateTime? reviewedAt;
  final String? rejectionReason;
  
  /// Timestamps
  final DateTime createdAt;
  final DateTime? expiresAt; // Auto-expire if no action taken
  
  /// Metadata
  final Map<String, dynamic>? metadata;

  const PendingRegistration._({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhone,
    this.userPhotoUrl,
    this.targetGymId,
    this.targetGymName,
    this.targetGymCode,
    this.accessCodeUsed,
    required this.status,
    required this.source,
    this.message,
    this.fitnessGoal,
    this.weight,
    this.height,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
    this.expiresAt,
    this.metadata,
  });

  /// Factory: Create a new pending registration
  factory PendingRegistration.create({
    required String userId,
    required String userEmail,
    required String userName,
    String? userPhone,
    String? userPhotoUrl,
    String? targetGymId,
    String? targetGymName,
    String? targetGymCode,
    String? accessCodeUsed,
    required RegistrationSource source,
    String? message,
    String? fitnessGoal,
    double? weight,
    double? height,
    int autoExpireDays = 30,
  }) {
    final now = DateTime.now();
    final uid = '${now.millisecondsSinceEpoch}_${userId.hashCode.abs()}';
    
    return PendingRegistration._(
      id: uid,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      userPhotoUrl: userPhotoUrl,
      targetGymId: targetGymId,
      targetGymName: targetGymName,
      targetGymCode: targetGymCode,
      accessCodeUsed: accessCodeUsed,
      status: RegistrationStatus.pendingReview,
      source: source,
      message: message,
      fitnessGoal: fitnessGoal,
      weight: weight,
      height: height,
      createdAt: now,
      expiresAt: now.add(Duration(days: autoExpireDays)),
    );
  }

  /// Factory: Restore from persistence
  factory PendingRegistration.restore({
    required String id,
    required String userId,
    required String userEmail,
    required String userName,
    String? userPhone,
    String? userPhotoUrl,
    String? targetGymId,
    String? targetGymName,
    String? targetGymCode,
    String? accessCodeUsed,
    required RegistrationStatus status,
    required RegistrationSource source,
    String? message,
    String? fitnessGoal,
    double? weight,
    double? height,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    required DateTime createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return PendingRegistration._(
      id: id,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      userPhotoUrl: userPhotoUrl,
      targetGymId: targetGymId,
      targetGymName: targetGymName,
      targetGymCode: targetGymCode,
      accessCodeUsed: accessCodeUsed,
      status: status,
      source: source,
      message: message,
      fitnessGoal: fitnessGoal,
      weight: weight,
      height: height,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  // === BEHAVIOR ===

  /// Check if this registration can still be reviewed
  bool get canBeReviewed =>
      status == RegistrationStatus.pendingReview && !isExpired;

  /// Check if registration has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Days remaining before auto-expiration
  int? get daysRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Time since registration was created
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  /// Approve this registration
  PendingRegistration approve({required String approvedBy}) {
    if (!canBeReviewed) {
      throw const DomainException(
        'Esta solicitud no puede ser revisada (ya fue procesada o expiró)',
      );
    }
    return _copyWith(
      status: RegistrationStatus.approved,
      reviewedBy: approvedBy,
      reviewedAt: DateTime.now(),
    );
  }

  /// Reject this registration
  PendingRegistration reject({
    required String rejectedBy,
    String? reason,
  }) {
    if (!canBeReviewed) {
      throw const DomainException(
        'Esta solicitud no puede ser revisada (ya fue procesada o expiró)',
      );
    }
    return _copyWith(
      status: RegistrationStatus.rejected,
      reviewedBy: rejectedBy,
      reviewedAt: DateTime.now(),
      rejectionReason: reason,
    );
  }

  /// Cancel by the user themselves
  PendingRegistration cancel() {
    if (status != RegistrationStatus.pendingReview) {
      throw const DomainException(
        'Solo puedes cancelar solicitudes pendientes',
      );
    }
    return _copyWith(status: RegistrationStatus.cancelled);
  }

  /// Mark as expired
  PendingRegistration markExpired() {
    return _copyWith(status: RegistrationStatus.expired);
  }

  /// Assign to a specific gym (when user enters code after initial registration)
  PendingRegistration assignToGym({
    required String gymId,
    required String gymName,
    String? gymCode,
    String? accessCode,
  }) {
    if (status != RegistrationStatus.pendingReview) {
      throw const DomainException(
        'Solo puedes asignar gym a solicitudes pendientes',
      );
    }
    return _copyWith(
      targetGymId: gymId,
      targetGymName: gymName,
      targetGymCode: gymCode,
      accessCodeUsed: accessCode,
    );
  }

  PendingRegistration _copyWith({
    RegistrationStatus? status,
    String? targetGymId,
    String? targetGymName,
    String? targetGymCode,
    String? accessCodeUsed,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return PendingRegistration._(
      id: id,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      userPhotoUrl: userPhotoUrl,
      targetGymId: targetGymId ?? this.targetGymId,
      targetGymName: targetGymName ?? this.targetGymName,
      targetGymCode: targetGymCode ?? this.targetGymCode,
      accessCodeUsed: accessCodeUsed ?? this.accessCodeUsed,
      status: status ?? this.status,
      source: source,
      message: message,
      fitnessGoal: fitnessGoal,
      weight: weight,
      height: height,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [id, userId, targetGymId, status];

  @override
  String toString() =>
      'PendingRegistration($id, user: $userName, gym: $targetGymName, status: ${status.displayName})';
}
