import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper for Gym entity to/from Firestore
class GymMapper {
  /// Convert Firestore document to Gym entity
  static Gym fromFirestore(Map<String, dynamic> data, String id) {
    return Gym.restore(
      id: GymId.fromString(id),
      code: GymCode(data['code'] as String),
      name: data['name'] as String,
      address: data['address'] as String?,
      phone: data['phone'] != null
          ? PhoneNumber.tryParse(data['phone'] as String)
          : null,
      logoUrl: data['logoUrl'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  /// Convert Gym entity to Firestore document
  static Map<String, dynamic> toFirestore(Gym gym) {
    return {
      'code': gym.code.value,
      'name': gym.name,
      'address': gym.address,
      'phone': gym.phone?.value,
      'logoUrl': gym.logoUrl,
      'createdAt': gym.createdAt.toIso8601String(),
      'isActive': gym.isActive,
    };
  }
}

