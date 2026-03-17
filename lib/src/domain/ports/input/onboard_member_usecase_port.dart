import '../../../../core/types/typedefs.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Port for onboarding a new member to a gym via unique code or scan.
abstract class OnboardMemberUseCasePort {
  /// Onboards a user to the current gym.
  /// [identifier] can be a UserId or a unique UserCode.
  FutureVoidResult execute({
    required String identifier,
    required GymId gymId,
    required UserId ownerId,
  });
}
