import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper for User entity to/from Firestore
class UserMapper {
  /// Convert Firestore document to User entity
  static User fromFirestore(Map<String, dynamic> data, String id) {
    return User.restore(
      id: UserId(id),
      email: Email(data['email'] as String),
      name: PersonName(
        firstName: data['firstName'] as String,
        lastName: (data['lastName'] as String?) ?? '',
      ),
      role: GymRole.fromString(data['role'] as String),
      gymId: GymId(data['gymId'] as String),
      phone: data['phone'] != null
          ? PhoneNumber.tryParse(data['phone'] as String)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'] as String)
          : null,
      isActive: (data['isActive'] as bool?) ?? true,
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      fitnessGoal: data['fitnessGoal'] as String?,
      membershipExpiresAt: data['membershipExpiresAt'] != null
          ? DateTime.parse(data['membershipExpiresAt'] as String)
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
      'weight': user.weight,
      'height': user.height,
      'fitnessGoal': user.fitnessGoal,
      'membershipExpiresAt': user.membershipExpiresAt?.toIso8601String(),
    };
  }
}
