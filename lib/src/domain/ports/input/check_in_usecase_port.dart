import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Command for client check-in
class CheckInCommand {
  final UserId clientId;
  final UserId? registeredById;
  final String? notes;
  final String? qrPayload;

  const CheckInCommand({
    required this.clientId,
    this.registeredById,
    this.notes,
    this.qrPayload,
  });
}

/// Command for client check-out
class CheckOutCommand {
  final UserId clientId;

  const CheckOutCommand({required this.clientId});
}

/// Input Port - Check-In Use Case Interface
abstract class CheckInUseCasePort {
  /// Execute check-in for a client
  FutureResult<CheckIn> checkIn(CheckInCommand command);

  /// Execute check-out for a client
  FutureResult<CheckIn> checkOut(CheckOutCommand command);
}
