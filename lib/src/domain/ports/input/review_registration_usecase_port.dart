import '../../../../core/types/typedefs.dart';
import '../../entities/pending_registration.dart';
import '../../value_objects/value_objects.dart';

/// Input Port - Review Registration Use Case Interface
/// Used by gym owners/admins to approve or reject pending registrations
abstract class ReviewRegistrationUseCasePort {
  /// Approve a pending registration and create the user in the gym
  FutureVoidResult approve({
    required String registrationId,
    required UserId reviewedBy,
    required GymId gymId,
    GymRoleType assignedRole = GymRoleType.client,
  });

  /// Reject a pending registration with optional reason
  FutureVoidResult reject({
    required String registrationId,
    required UserId rejectedBy,
    String? reason,
  });

  /// Get all pending registrations for a specific gym
  FutureResult<List<PendingRegistration>> getPendingForGym(GymId gymId);

  /// Get count of pending registrations (for badge display)
  Future<int> getPendingCount(GymId gymId);
}
