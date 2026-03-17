import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';

/// Check-In Entity - Records client attendance
class CheckIn extends Equatable {
  final CheckInId id;
  final UserId clientId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final UserId? registeredById;
  final String? notes;

  const CheckIn._({
    required this.id,
    required this.clientId,
    required this.checkInTime,
    this.checkOutTime,
    this.registeredById,
    this.notes,
  });

  /// Create new check-in
  factory CheckIn.create({
    required UserId clientId,
    UserId? registeredById,
    String? notes,
  }) {
    return CheckIn._(
      id: CheckInId.generate(),
      clientId: clientId,
      checkInTime: DateTime.now(),
      registeredById: registeredById,
      notes: notes?.trim(),
    );
  }

  /// Restore from persistence
  factory CheckIn.restore({
    required CheckInId id,
    required UserId clientId,
    required DateTime checkInTime,
    DateTime? checkOutTime,
    UserId? registeredById,
    String? notes,
  }) {
    return CheckIn._(
      id: id,
      clientId: clientId,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      registeredById: registeredById,
      notes: notes,
    );
  }

  // === BEHAVIOR METHODS ===

  /// Record check-out
  CheckIn recordCheckOut() {
    return CheckIn._(
      id: id,
      clientId: clientId,
      checkInTime: checkInTime,
      checkOutTime: DateTime.now(),
      registeredById: registeredById,
      notes: notes,
    );
  }

  // === COMPUTED PROPERTIES ===

  /// Duration of the session
  Duration? get sessionDuration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  /// Formatted duration string
  String get durationDisplay {
    final duration = sessionDuration;
    if (duration == null) return 'En progreso';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Check if still checked in
  bool get isActive => checkOutTime == null;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'CheckIn(${clientId.value}, $checkInTime)';
}
