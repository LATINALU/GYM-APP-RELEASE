import '../../../../core/types/typedefs.dart';
import '../../value_objects/value_objects.dart';

class AllocatedMemberNumber {
  final String memberNumber;
  final int sequence;
  final GymId gymId;
  final String format;
  final DateTime allocatedAt;

  const AllocatedMemberNumber({
    required this.memberNumber,
    required this.sequence,
    required this.gymId,
    required this.format,
    required this.allocatedAt,
  });
}

abstract class MemberNumberAllocatorPort {
  bool get isEnabled;

  FutureResult<AllocatedMemberNumber> allocate({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    String? idempotencyKey,
  });
}
