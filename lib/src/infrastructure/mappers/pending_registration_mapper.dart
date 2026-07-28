import 'package:gym_app/src/domain/entities/pending_registration.dart';

/// Columnas snake_case de `public.pending_registrations` (Fase 2 de la
/// migración a Supabase, ver 0007_pending_registrations.sql). Una sola
/// tabla reemplaza la duplicación Firestore global + por-gym.
class PendingRegistrationMapper {
  static Map<String, dynamic> toSupabase(PendingRegistration reg) {
    return {
      'id': reg.id,
      'user_id': reg.userId,
      'user_email': reg.userEmail,
      'user_name': reg.userName,
      'user_phone': reg.userPhone,
      'user_photo_url': reg.userPhotoUrl,
      'target_gym_id': reg.targetGymId,
      'target_gym_name': reg.targetGymName,
      'target_gym_code': reg.targetGymCode,
      'access_code_used': reg.accessCodeUsed,
      'status': reg.status.name,
      'source': reg.source.name,
      'message': reg.message,
      'fitness_goal': reg.fitnessGoal,
      'weight': reg.weight,
      'height': reg.height,
      'reviewed_by': reg.reviewedBy,
      'reviewed_at': reg.reviewedAt?.toIso8601String(),
      'rejection_reason': reg.rejectionReason,
      'created_at': reg.createdAt.toIso8601String(),
      'expires_at': reg.expiresAt?.toIso8601String(),
      'metadata': reg.metadata,
    };
  }

  static PendingRegistration fromSupabase(Map<String, dynamic> row) {
    return PendingRegistration.restore(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      userEmail: row['user_email'] as String? ?? '',
      userName: row['user_name'] as String? ?? '',
      userPhone: row['user_phone'] as String?,
      userPhotoUrl: row['user_photo_url'] as String?,
      targetGymId: row['target_gym_id'] as String?,
      targetGymName: row['target_gym_name'] as String?,
      targetGymCode: row['target_gym_code'] as String?,
      accessCodeUsed: row['access_code_used'] as String?,
      status: _parseStatus(row['status'] as String? ?? 'pendingReview'),
      source: _parseSource(row['source'] as String? ?? 'manualCode'),
      message: row['message'] as String?,
      fitnessGoal: row['fitness_goal'] as String?,
      weight: (row['weight'] as num?)?.toDouble(),
      height: (row['height'] as num?)?.toDouble(),
      reviewedBy: row['reviewed_by'] as String?,
      reviewedAt: row['reviewed_at'] != null
          ? DateTime.tryParse(row['reviewed_at'].toString())
          : null,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: row['expires_at'] != null
          ? DateTime.tryParse(row['expires_at'].toString())
          : null,
      metadata: row['metadata'] as Map<String, dynamic>?,
    );
  }

  static RegistrationStatus _parseStatus(String value) {
    return RegistrationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RegistrationStatus.pendingReview,
    );
  }

  static RegistrationSource _parseSource(String value) {
    return RegistrationSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RegistrationSource.manualCode,
    );
  }
}
