import 'package:equatable/equatable.dart';

/// Gym user role with permissions
/// 3-layer hierarchy: Admin > Owner > Employee > Client
enum GymRoleType {
  admin,    // Super Admin - gestión de todos los gimnasios y dueños
  owner,    // Dueño del gimnasio - acceso total a su gimnasio
  employee, // Empleado - gestión de clientes y rutinas
  client,   // Cliente - solo ver sus rutinas y check-ins
}

/// Value Object for Gym Role with permission methods
class GymRole extends Equatable {
  final GymRoleType type;

  const GymRole._(this.type);

  // Named constructors for each role
  const GymRole.admin() : this._(GymRoleType.admin);
  const GymRole.owner() : this._(GymRoleType.owner);
  const GymRole.employee() : this._(GymRoleType.employee);
  const GymRole.client() : this._(GymRoleType.client);

  /// Factory from string (for deserialization)
  factory GymRole.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return const GymRole.admin();
      case 'owner':
        return const GymRole.owner();
      case 'employee':
        return const GymRole.employee();
      case 'client':
        return const GymRole.client();
      default:
        return const GymRole.client(); // Default to lowest privilege
    }
  }

  // === PERMISSION CHECKS ===

  /// Can manage all gyms and owners (Admin only)
  bool get canManageGyms => type == GymRoleType.admin;

  /// Can manage owners (Admin only)
  bool get canManageOwners => type == GymRoleType.admin;

  /// Can view global reports across all gyms (Admin only)
  bool get canViewGlobalReports => type == GymRoleType.admin;

  /// Can manage employees (hire/fire)
  bool get canManageEmployees =>
      type == GymRoleType.admin || type == GymRoleType.owner;

  /// Can assign routines to clients
  bool get canAssignRoutines =>
      type == GymRoleType.admin ||
      type == GymRoleType.owner ||
      type == GymRoleType.employee;

  /// Can create/edit routines
  bool get canManageRoutines =>
      type == GymRoleType.admin ||
      type == GymRoleType.owner ||
      type == GymRoleType.employee;

  /// Can view all clients
  bool get canViewAllClients =>
      type == GymRoleType.admin ||
      type == GymRoleType.owner ||
      type == GymRoleType.employee;

  /// Can view reports/statistics
  bool get canViewReports =>
      type == GymRoleType.admin || type == GymRoleType.owner;

  /// Can register check-ins for clients
  bool get canRegisterCheckIns =>
      type == GymRoleType.admin ||
      type == GymRoleType.owner ||
      type == GymRoleType.employee;

  /// Can view own profile and routine
  bool get canViewOwnProfile => true; // All roles can

  /// Can modify gym settings
  bool get canModifySettings =>
      type == GymRoleType.admin || type == GymRoleType.owner;

  /// Can manage finances
  bool get canManageFinances =>
      type == GymRoleType.admin || type == GymRoleType.owner;

  /// Can manage subscriptions and billing
  bool get canManageBilling => type == GymRoleType.admin;

  /// Can suspend/activate gyms
  bool get canSuspendGyms => type == GymRoleType.admin;

  // === UTILITY METHODS ===

  /// Get display name in Spanish
  String get displayName {
    switch (type) {
      case GymRoleType.admin:
        return 'Administrador';
      case GymRoleType.owner:
        return 'Dueño';
      case GymRoleType.employee:
        return 'Empleado';
      case GymRoleType.client:
        return 'Cliente';
    }
  }

  /// Get role priority (higher = more permissions)
  int get priority {
    switch (type) {
      case GymRoleType.admin:
        return 1000;
      case GymRoleType.owner:
        return 100;
      case GymRoleType.employee:
        return 50;
      case GymRoleType.client:
        return 10;
    }
  }

  /// Check if this role has higher or equal priority than another
  bool hasAuthorityOver(GymRole other) => priority >= other.priority;

  /// Convert to string for persistence
  String toValue() => type.name;

  @override
  List<Object?> get props => [type];

  @override
  String toString() => displayName;
}
