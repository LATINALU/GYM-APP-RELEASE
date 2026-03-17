import '../../../../core/types/typedefs.dart';
import '../../entities/pending_registration.dart';
import '../../value_objects/value_objects.dart';

/// Output Port - Pending Registration Repository Interface
/// Manages the pre-approval queue where users wait to be accepted by a gym
abstract class PendingRegistrationRepositoryPort {
  /// Save a new pending registration request
  FutureVoidResult save(PendingRegistration registration);

  /// Find a specific registration by ID
  FutureResult<PendingRegistration> findById(String registrationId);

  /// Find all pending registrations for a specific gym
  /// (used by gym owners to see their approval queue)
  FutureResult<List<PendingRegistration>> findByGymId(GymId gymId);

  /// Find all registrations by a specific user
  /// (used by user to see their pending requests)
  FutureResult<List<PendingRegistration>> findByUserId(UserId userId);

  /// Find all pending registrations that haven't been assigned to a gym yet
  /// (users who registered but haven't entered a gym code)
  FutureResult<List<PendingRegistration>> findUnassigned();

  /// Update a registration (approve, reject, expire, etc.)
  FutureVoidResult update(PendingRegistration registration);

  /// Delete a registration (hard delete for GDPR compliance)
  FutureVoidResult delete(String registrationId);

  /// Stream of pending registrations for real-time updates
  /// (gym owner gets notified when new requests arrive)
  Stream<List<PendingRegistration>> watchByGymId(GymId gymId);

  /// Count pending registrations for badge/notification count
  Future<int> countPendingByGymId(GymId gymId);

  /// Find expired registrations (for cleanup jobs)
  FutureResult<List<PendingRegistration>> findExpired();

  /// Search registrations by user name or email
  FutureResult<List<PendingRegistration>> search({
    required String query,
    GymId? gymId,
  });
}
