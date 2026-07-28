import 'package:gym_app/src/domain/value_objects/value_objects.dart';

/// Columnas snake_case de `public.access_codes` (Fase 2 de la migración
/// a Supabase, ver 0006_access_codes.sql). A diferencia de Firestore
/// (que necesitaba duplicar el código en /access_codes y en
/// /gyms/{gymId}/access_codes para poder consultarlo por gym), acá una
/// sola tabla con columna gym_id + índice alcanza para ambos casos de
/// uso — no hace falta doble escritura.
class AccessCodeMapper {
  static Map<String, dynamic> toSupabase(
    AccessCode code, {
    required String gymId,
    required String generatedBy,
  }) {
    return {
      'value': code.value,
      'gym_id': gymId,
      'type': code.type.name,
      'generated_by': generatedBy,
      'created_at': code.createdAt.toIso8601String(),
      'expires_at': code.expiresAt.toIso8601String(),
      'is_used': code.isUsed,
      'used_by': code.usedBy,
      'used_at': code.usedAt?.toIso8601String(),
    };
  }

  static AccessCode fromSupabase(Map<String, dynamic> row) {
    return AccessCode.restore(
      value: row['value'] as String? ?? '',
      type: _parseType(row['type'] as String? ?? 'gymEntry'),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(row['expires_at']?.toString() ?? '') ?? DateTime.now(),
      isUsed: row['is_used'] as bool? ?? false,
      usedBy: row['used_by'] as String?,
      usedAt: row['used_at'] != null
          ? DateTime.tryParse(row['used_at'].toString())
          : null,
    );
  }

  static AccessCodeType _parseType(String value) {
    return AccessCodeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AccessCodeType.gymEntry,
    );
  }
}
