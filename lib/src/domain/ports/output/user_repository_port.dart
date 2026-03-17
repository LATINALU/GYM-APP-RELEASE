import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - User Repository Interface
/// Defines contract for user persistence (implemented in infrastructure)
abstract class UserRepositoryPort {
  /// Get user by ID using the global index (for cases where gymId/role is unknown)
  /// Uses the root /users/{uid} collection which has basic user info
  FutureResult<User> findByIdGlobal(UserId id);

  /// Get user by ID (requires gymId and role for the nested path)
  FutureResult<User> findById({required UserId id, required GymId gymId, required GymRoleType role});

  /// Get user by email (this might need a global index if gymId is unknown)
  FutureResult<User> findByEmail(Email email);

  /// Get all users with specific role in a gym
  FutureResult<List<User>> findByRole({required GymId gymId, required GymRole role});

  /// Get all active users in a gym
  FutureResult<List<User>> findAllActive(GymId gymId);

  /// Save user (create or update)
  FutureVoidResult save(User user);

  /// Delete user
  FutureVoidResult delete({required UserId id, required GymId gymId, required GymRoleType role});

  /// Check if email is already registered (global check)
  Future<bool> existsByEmail(Email email);

  /// Search users by name in a gym
  FutureResult<List<User>> searchByName({required String query, required GymId gymId});

  /// Get pending users for approval in a gym
  FutureResult<List<User>> findPendingUsers(GymId gymId);
}
