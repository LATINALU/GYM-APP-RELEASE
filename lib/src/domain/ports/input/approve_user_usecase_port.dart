import '../../../../core/types/typedefs.dart';
import '../../value_objects/value_objects.dart';

/// Input Port - Approve User Use Case Interface
abstract class ApproveUserUseCasePort {
  /// Approve a pending user in a gym
  /// [userId] is the user to be approved
  /// [approvedBy] is the ID of the person performing the action (Owner/Full Employee)
  FutureVoidResult execute({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    required UserId approvedById,
  });

  /// Reject a pending user
  FutureVoidResult reject({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    required UserId rejectedById,
  });
}
