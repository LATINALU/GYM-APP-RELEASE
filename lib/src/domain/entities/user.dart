import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';
import '../../../core/errors/exceptions.dart';

/// User membership status in a specific gym
enum MembershipStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case MembershipStatus.pending: return 'Pendiente';
      case MembershipStatus.approved: return 'Aprobado';
      case MembershipStatus.rejected: return 'Rechazado';
    }
  }
}

/// User Entity - Core domain entity with behavior
/// Represents any gym user (owner, employee, or client)
class User extends Equatable {
  final UserId id;
  final Email email;
  final PersonName name;
  final GymRole role;
  final GymId gymId; // Added for multi-tenancy
  final PhoneNumber? phone;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final MembershipStatus membershipStatus;
  final DateTime? membershipExpiresAt;
  final String? memberNumber;
  final DateTime? memberNumberAssignedAt;
  
  // Fitness Data
  final double? weight;
  final double? height;
  final String? fitnessGoal;

  const User._({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.gymId,
    this.phone,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    required this.membershipStatus,
    this.weight,
    this.height,
    this.fitnessGoal,
    this.membershipExpiresAt,
    this.memberNumber,
    this.memberNumberAssignedAt,
  });

  /// Factory: Create new user (for registration)
  factory User.create({
    required Email email,
    required PersonName name,
    required GymRole role,
    required GymId gymId,
    PhoneNumber? phone,
    MembershipStatus membershipStatus = MembershipStatus.pending,
    double? weight,
    double? height,
    String? fitnessGoal,
    DateTime? membershipExpiresAt,
    String? memberNumber,
    DateTime? memberNumberAssignedAt,
  }) {
    return User._(
      id: UserId.generate(),
      email: email,
      name: name,
      role: role,
      gymId: gymId,
      phone: phone,
      createdAt: DateTime.now(),
      isActive: true,
      membershipStatus: role.type == GymRoleType.owner ? MembershipStatus.approved : membershipStatus,
      weight: weight,
      height: height,
      fitnessGoal: fitnessGoal,
      membershipExpiresAt: membershipExpiresAt,
      memberNumber: memberNumber,
      memberNumberAssignedAt: memberNumberAssignedAt,
    );
  }

  /// Factory: Restore from persistence (reconstitution)
  factory User.restore({
    required UserId id,
    required Email email,
    required PersonName name,
    required GymRole role,
    required GymId gymId,
    PhoneNumber? phone,
    required DateTime createdAt,
    DateTime? lastLoginAt,
    bool isActive = true,
    MembershipStatus membershipStatus = MembershipStatus.approved,
    double? weight,
    double? height,
    String? fitnessGoal,
    DateTime? membershipExpiresAt,
    String? memberNumber,
    DateTime? memberNumberAssignedAt,
  }) {
    return User._(
      id: id,
      email: email,
      name: name,
      role: role,
      gymId: gymId,
      phone: phone,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isActive: isActive,
      membershipStatus: membershipStatus,
      weight: weight,
      height: height,
      fitnessGoal: fitnessGoal,
      membershipExpiresAt: membershipExpiresAt,
      memberNumber: memberNumber,
      memberNumberAssignedAt: memberNumberAssignedAt,
    );
  }

  // === BEHAVIOR METHODS ===

  /// Record login activity
  User recordLogin() {
    return _copyWith(lastLoginAt: DateTime.now());
  }

  /// Update profile information
  User updateProfile({
    PersonName? name,
    PhoneNumber? phone,
    double? weight,
    double? height,
    String? fitnessGoal,
  }) {
    return _copyWith(
      name: name,
      phone: phone,
      weight: weight,
      height: height,
      fitnessGoal: fitnessGoal,
    );
  }

  /// Assign user to a new gym
  User assignToGym(GymId newGymId) {
    return _copyWith(gymId: newGymId);
  }

  User assignMemberNumber(String newMemberNumber) {
    return _copyWith(
      memberNumber: newMemberNumber,
      memberNumberAssignedAt: DateTime.now(),
    );
  }

  /// Approve user membership
  User approve(User approvedBy) {
    if (!approvedBy.role.canManageEmployees && approvedBy.role.type != GymRoleType.owner) {
      throw const UnauthorizedException(
        'No tienes permisos para aprobar usuarios',
      );
    }
    return _copyWith(membershipStatus: MembershipStatus.approved);
  }

  /// Reject user membership
  User reject(User rejectedBy) {
    if (!rejectedBy.role.canManageEmployees && rejectedBy.role.type != GymRoleType.owner) {
      throw const UnauthorizedException(
        'No tienes permisos para rechazar usuarios',
      );
    }
    return _copyWith(membershipStatus: MembershipStatus.rejected);
  }

  /// Change user role (only higher authority can do this)
  User changeRole(GymRole newRole, User changedBy) {
    if (!changedBy.role.hasAuthorityOver(role)) {
      throw const UnauthorizedException(
        'No tienes permisos para cambiar el rol de este usuario',
      );
    }
    if (!changedBy.role.canManageEmployees && newRole.type == GymRoleType.employee) {
      throw const UnauthorizedException(
        'Solo el dueño puede asignar rol de empleado',
      );
    }
    return _copyWith(role: newRole);
  }

  /// Deactivate user
  User deactivate(User deactivatedBy) {
    if (!deactivatedBy.role.hasAuthorityOver(role)) {
      throw const UnauthorizedException(
        'No tienes permisos para desactivar este usuario',
      );
    }
    return _copyWith(isActive: false);
  }

  /// Reactivate user
  User activate(User activatedBy) {
    if (!activatedBy.role.canManageEmployees) {
      throw const UnauthorizedException(
        'No tienes permisos para activar usuarios',
      );
    }
    return _copyWith(isActive: true);
  }

  // === PERMISSION CHECKS ===

  /// Check if this user can assign routines to target
  bool canAssignRoutineTo(User target) {
    if (!role.canAssignRoutines) return false;
    if (!isActive) return false;
    if (membershipStatus != MembershipStatus.approved) return false;
    // Can only assign to clients
    return target.role.type == GymRoleType.client && 
           target.membershipStatus == MembershipStatus.approved;
  }

  /// Check if this user can view another user's data
  bool canView(User target) {
    if (!isActive) return false;
    // Everyone can view themselves
    if (id == target.id) return true;
    // Owner and employees can view all
    return role.canViewAllClients;
  }

  // === UTILITY ===

  /// Check if user is owner
  bool get isOwner => role.type == GymRoleType.owner;

  /// Check if user is employee
  bool get isEmployee => role.type == GymRoleType.employee;

  /// Check if user is client
  bool get isClient => role.type == GymRoleType.client;

  /// Check if user is pending
  bool get isPending => membershipStatus == MembershipStatus.pending;

  /// Get display name
  String get displayName => name.fullName;

  /// Get initials for avatar
  String get initials => name.initials;

  /// Get a shorter unique code for display and manual entry
  String get uniqueCode => memberNumber ?? id.value.toUpperCase().split('-').first;

  bool get hasMemberNumber => memberNumber != null && memberNumber!.trim().isNotEmpty;

  /// Days remaining for membership
  int? get daysRemaining {
    if (membershipExpiresAt == null) return null;
    final diff = membershipExpiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Check if membership is active (approved and not expired)
  bool get isSubscriptionActive {
    if (membershipStatus != MembershipStatus.approved) return false;
    if (membershipExpiresAt == null) return true; // Lifetime or not set
    return membershipExpiresAt!.isAfter(DateTime.now());
  }

  /// Returns true if the user should be notified about renewal (e.g., 5 days before expiration)
  bool get needsRenewalNotification {
    if (membershipExpiresAt == null || membershipStatus != MembershipStatus.approved) {
      return false;
    }
    final daysToExpiry = membershipExpiresAt!.difference(DateTime.now()).inDays;
    return daysToExpiry == 5; // The requested 5-day rule
  }

  /// Compute BMI if data available
  double? get bmi {
    if (weight == null || height == null || height == 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  User _copyWith({
    PersonName? name,
    GymRole? role,
    GymId? gymId,
    PhoneNumber? phone,
    DateTime? lastLoginAt,
    bool? isActive,
    MembershipStatus? membershipStatus,
    double? weight,
    double? height,
    String? fitnessGoal,
    DateTime? membershipExpiresAt,
    String? memberNumber,
    DateTime? memberNumberAssignedAt,
  }) {
    return User._(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      gymId: gymId ?? this.gymId,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      memberNumber: memberNumber ?? this.memberNumber,
      memberNumberAssignedAt: memberNumberAssignedAt ?? this.memberNumberAssignedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    gymId,
    membershipStatus,
    memberNumber,
    memberNumberAssignedAt,
    weight,
    height,
    fitnessGoal,
    membershipExpiresAt,
  ];

  @override
  String toString() => 'User(${id.value}, ${email.value}, ${role.displayName}, memberNumber: $memberNumber, Status: $membershipStatus)';
}



