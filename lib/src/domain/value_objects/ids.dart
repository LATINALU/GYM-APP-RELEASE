import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';

/// Value Object for User ID (UUID)
class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  /// Generate new unique ID
  factory UserId.generate() => UserId._(const Uuid().v4());

  /// Create from existing string (with validation)
  factory UserId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de usuario no puede estar vacío',
        code: 'INVALID_USER_ID',
      );
    }
    return UserId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Value Object for Routine ID (UUID)
class RoutineId extends Equatable {
  final String value;

  const RoutineId._(this.value);

  /// Generate new unique ID
  factory RoutineId.generate() => RoutineId._(const Uuid().v4());

  /// Create from existing string
  factory RoutineId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de rutina no puede estar vacío',
        code: 'INVALID_ROUTINE_ID',
      );
    }
    return RoutineId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Value Object for Exercise ID (UUID)
class ExerciseId extends Equatable {
  final String value;

  const ExerciseId._(this.value);

  factory ExerciseId.generate() => ExerciseId._(const Uuid().v4());

  factory ExerciseId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de ejercicio no puede estar vacío',
        code: 'INVALID_EXERCISE_ID',
      );
    }
    return ExerciseId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Value Object for Assignment ID (UUID)
class AssignmentId extends Equatable {
  final String value;

  const AssignmentId._(this.value);

  factory AssignmentId.generate() => AssignmentId._(const Uuid().v4());

  factory AssignmentId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de asignación no puede estar vacío',
        code: 'INVALID_ASSIGNMENT_ID',
      );
    }
    return AssignmentId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Value Object for Plan ID (UUID)
class PlanId extends Equatable {
  final String value;

  const PlanId._(this.value);

  factory PlanId.generate() => PlanId._(const Uuid().v4());

  factory PlanId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de plan no puede estar vacío',
        code: 'INVALID_PLAN_ID',
      );
    }
    return PlanId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Value Object for CheckIn ID (UUID)
class CheckInId extends Equatable {
  final String value;

  const CheckInId._(this.value);

  factory CheckInId.generate() => CheckInId._(const Uuid().v4());

  factory CheckInId(String value) {
    if (value.isEmpty) {
      throw const DomainException(
        'El ID de check-in no puede estar vacío',
        code: 'INVALID_CHECKIN_ID',
      );
    }
    return CheckInId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
