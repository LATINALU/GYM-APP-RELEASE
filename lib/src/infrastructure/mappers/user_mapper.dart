import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper for User entity to/from Firestore
class UserMapper {
  static String _roleValue(dynamic role) {
    if (role is String && role.isNotEmpty) return role;
    if (role is Map<String, dynamic>) {
      final type = role['type'];
      if (type is String && type.isNotEmpty) return type;
    }
    return 'client';
  }

  /// Convert Firestore document to User entity
  static User fromFirestore(Map<String, dynamic> data, String id) {
    return User.restore(
      id: UserId(id),
      email: Email(data['email'] as String),
      name: PersonName(
        firstName: data['firstName'] as String,
        lastName: (data['lastName'] as String?) ?? '',
      ),
      role: GymRole.fromString(_roleValue(data['role'])),
      gymId: GymId(data['gymId'] as String),
      phone: data['phone'] != null
          ? PhoneNumber.tryParse(data['phone'] as String)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'] as String)
          : null,
      isActive: (data['isActive'] as bool?) ?? true,
      membershipStatus: _membershipStatusFromString(
        data['membershipStatus'] as String?,
      ),
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      fitnessGoal: data['fitnessGoal'] as String?,
      membershipExpiresAt: data['membershipExpiresAt'] != null
          ? DateTime.parse(data['membershipExpiresAt'] as String)
          : null,
      memberNumber: data['memberNumber'] as String?,
      memberNumberAssignedAt: data['memberNumberAssignedAt'] != null
          ? DateTime.parse(data['memberNumberAssignedAt'] as String)
          : null,
    );
  }

  /// Convert User entity to Firestore document
  static Map<String, dynamic> toFirestore(User user) {
    return {
      'email': user.email.value,
      'firstName': user.name.firstName,
      'lastName': user.name.lastName,
      'role': user.role.toValue(),
      'gymId': user.gymId.value,
      'phone': user.phone?.value,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt?.toIso8601String(),
      'isActive': user.isActive,
      'membershipStatus': user.membershipStatus.name,
      'weight': user.weight,
      'height': user.height,
      'fitnessGoal': user.fitnessGoal,
      'membershipExpiresAt': user.membershipExpiresAt?.toIso8601String(),
      'memberNumber': user.memberNumber,
      'memberNumberAssignedAt': user.memberNumberAssignedAt?.toIso8601String(),
    };
  }

  static MembershipStatus _membershipStatusFromString(String? value) {
    return MembershipStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MembershipStatus.approved,
    );
  }

  /// Columnas snake_case de `public.gym_members` (Fase 3 de la migración
  /// a Supabase, ver 0008_gyms_and_members.sql). Una sola tabla
  /// reemplaza las 3 copias que mantenía Firestore por usuario
  /// (gyms/{gymId}/{role}s/{uid} + users/{uid} raíz + el 'user/{uid}'
  /// legacy, que resultó ser código muerto y no se migra).
  static Map<String, dynamic> toSupabase(User user) {
    return {
      'id': user.id.value,
      'gym_id': user.gymId.value,
      'email': user.email.value,
      'first_name': user.name.firstName,
      'last_name': user.name.lastName,
      'role': user.role.toValue(),
      'phone': user.phone?.value,
      'is_active': user.isActive,
      'membership_status': user.membershipStatus.name,
      'membership_expires_at': user.membershipExpiresAt?.toIso8601String(),
      'member_number': user.memberNumber,
      'member_number_assigned_at': user.memberNumberAssignedAt?.toIso8601String(),
      'weight': user.weight,
      'height': user.height,
      'fitness_goal': user.fitnessGoal,
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt.toIso8601String(),
    };
  }

  static User fromSupabase(Map<String, dynamic> row) {
    return User.restore(
      id: UserId(row['id'] as String),
      email: Email(row['email'] as String),
      name: PersonName(
        firstName: row['first_name'] as String,
        lastName: (row['last_name'] as String?) ?? '',
      ),
      role: GymRole.fromString(_roleValue(row['role'])),
      gymId: GymId(row['gym_id'] as String),
      phone: row['phone'] != null
          ? PhoneNumber.tryParse(row['phone'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastLoginAt: row['last_login_at'] != null
          ? DateTime.parse(row['last_login_at'] as String)
          : null,
      isActive: (row['is_active'] as bool?) ?? true,
      membershipStatus: _membershipStatusFromString(row['membership_status'] as String?),
      weight: (row['weight'] as num?)?.toDouble(),
      height: (row['height'] as num?)?.toDouble(),
      fitnessGoal: row['fitness_goal'] as String?,
      membershipExpiresAt: row['membership_expires_at'] != null
          ? DateTime.parse(row['membership_expires_at'] as String)
          : null,
      memberNumber: row['member_number'] as String?,
      memberNumberAssignedAt: row['member_number_assigned_at'] != null
          ? DateTime.parse(row['member_number_assigned_at'] as String)
          : null,
    );
  }
}

