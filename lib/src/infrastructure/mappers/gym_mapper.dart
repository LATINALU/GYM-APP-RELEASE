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

  /// Columnas snake_case de `public.gyms` (Fase 3 de la migración a
  /// Supabase, ver 0008_gyms_and_members.sql). platform_plan_id/status
  /// no son parte del dominio Gym (los escribe directo AdminGymsLiveScreen,
  /// ver commit d7c0640) — no se tocan acá, quedan null en altas nuevas.
  static Map<String, dynamic> toSupabase(Gym gym) {
    return {
      'id': gym.id.value,
      'code': gym.code.value,
      'name': gym.name,
      'address': gym.address,
      'phone': gym.phone?.value,
      'logo_url': gym.logoUrl,
      'created_at': gym.createdAt.toIso8601String(),
      'is_active': gym.isActive,
    };
  }

  static Gym fromSupabase(Map<String, dynamic> row) {
    return Gym.restore(
      id: GymId.fromString(row['id'] as String),
      code: GymCode(row['code'] as String),
      name: row['name'] as String,
      address: row['address'] as String?,
      phone: row['phone'] != null
          ? PhoneNumber.tryParse(row['phone'] as String)
          : null,
      logoUrl: row['logo_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }
}

