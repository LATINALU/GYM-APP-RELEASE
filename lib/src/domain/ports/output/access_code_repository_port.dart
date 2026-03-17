import '../../../../core/types/typedefs.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - Access Code Repository Interface
/// Manages all cryptographically secure access codes in the system
abstract class AccessCodeRepositoryPort {
  /// Generate and store a new access code for a gym
  FutureResult<AccessCode> generate({
    required GymId gymId,
    required AccessCodeType type,
    required UserId generatedBy,
    int length = 8,
    int expirationMinutes = 30,
  });

  /// Validate and consume an access code
  /// Returns the code details if valid, failure if invalid/expired/used
  FutureResult<AccessCode> validateAndConsume({
    required String code,
    required UserId consumedBy,
  });

  /// Find an access code by its value
  FutureResult<AccessCode> findByCode(String code);

  /// Get all active (non-expired, non-used) codes for a gym
  FutureResult<List<AccessCode>> findActiveByGymId(GymId gymId);

  /// Revoke (invalidate) a specific code
  FutureVoidResult revoke(String code);

  /// Revoke all active codes for a gym (emergency security measure)
  FutureVoidResult revokeAllForGym(GymId gymId);

  /// Clean up expired codes (for maintenance)
  FutureVoidResult cleanupExpired();

  /// Get usage statistics for a gym's access codes
  FutureResult<Map<String, dynamic>> getUsageStats(GymId gymId);
}
