import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';
import 'user.dart';
import '../../../core/errors/exceptions.dart';

/// Assignment status
enum AssignmentStatus {
  active,     // Currently assigned
  completed,  // Client finished the routine
  cancelled,  // Assignment was cancelled
}

extension AssignmentStatusX on AssignmentStatus {
  String get displayName {
    switch (this) {
      case AssignmentStatus.active:
        return 'Activa';
      case AssignmentStatus.completed:
        return 'Completada';
      case AssignmentStatus.cancelled:
        return 'Cancelada';
    }
  }
}

/// Routine Assignment Entity - Links routine to client
class RoutineAssignment extends Equatable {
  final AssignmentId id;
  final RoutineId routineId;
  final UserId clientId;
  final UserId assignedById;
  final DateTime assignedAt;
  final DateTime startDate;
  final DateTime? endDate;
  final AssignmentStatus status;
  final String? notes;

  const RoutineAssignment._({
    required this.id,
    required this.routineId,
    required this.clientId,
    required this.assignedById,
    required this.assignedAt,
    required this.startDate,
    this.endDate,
    this.status = AssignmentStatus.active,
    this.notes,
  });

  /// Create new assignment
  factory RoutineAssignment.create({
    required RoutineId routineId,
    required UserId clientId,
    required User assignedBy,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    // Validate assigner has permission
    if (!assignedBy.role.canAssignRoutines) {
      throw const UnauthorizedException(
        'No tienes permisos para asignar rutinas',
      );
    }

    final now = DateTime.now();
    final start = startDate ?? now;

    if (endDate != null && endDate.isBefore(start)) {
      throw const DomainException(
        'La fecha de fin no puede ser anterior a la fecha de inicio',
        code: 'INVALID_DATES',
      );
    }

    return RoutineAssignment._(
      id: AssignmentId.generate(),
      routineId: routineId,
      clientId: clientId,
      assignedById: assignedBy.id,
      assignedAt: now,
      startDate: start,
      endDate: endDate,
      status: AssignmentStatus.active,
      notes: notes?.trim(),
    );
  }

  /// Restore from persistence
  factory RoutineAssignment.restore({
    required AssignmentId id,
    required RoutineId routineId,
    required UserId clientId,
    required UserId assignedById,
    required DateTime assignedAt,
    required DateTime startDate,
    DateTime? endDate,
    required AssignmentStatus status,
    String? notes,
  }) {
    return RoutineAssignment._(
      id: id,
      routineId: routineId,
      clientId: clientId,
      assignedById: assignedById,
      assignedAt: assignedAt,
      startDate: startDate,
      endDate: endDate,
      status: status,
      notes: notes,
    );
  }

  // === BEHAVIOR METHODS ===

  /// Complete the assignment
  RoutineAssignment complete() {
    if (status != AssignmentStatus.active) {
      throw const DomainException(
        'No se puede completar una asignación que no está activa',
        code: 'INVALID_STATUS',
      );
    }
    return _copyWith(
      status: AssignmentStatus.completed,
      endDate: DateTime.now(),
    );
  }

  /// Cancel the assignment
  RoutineAssignment cancel(User cancelledBy) {
    if (status != AssignmentStatus.active) {
      throw const DomainException(
        'No se puede cancelar una asignación que no está activa',
        code: 'INVALID_STATUS',
      );
    }
    if (!cancelledBy.role.canAssignRoutines && cancelledBy.id != clientId) {
      throw const UnauthorizedException(
        'No tienes permisos para cancelar esta asignación',
      );
    }
    return _copyWith(
      status: AssignmentStatus.cancelled,
      endDate: DateTime.now(),
    );
  }

  /// Update notes
  RoutineAssignment updateNotes(String notes) {
    return _copyWith(notes: notes.trim());
  }

  // === COMPUTED PROPERTIES ===

  /// Check if assignment is currently active
  bool get isActive => status == AssignmentStatus.active;

  /// Check if assignment has started
  bool get hasStarted => DateTime.now().isAfter(startDate);

  /// Days remaining (null if no end date)
  int? get daysRemaining {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  RoutineAssignment _copyWith({
    AssignmentStatus? status,
    DateTime? endDate,
    String? notes,
  }) {
    return RoutineAssignment._(
      id: id,
      routineId: routineId,
      clientId: clientId,
      assignedById: assignedById,
      assignedAt: assignedAt,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'RoutineAssignment(${id.value}, ${status.displayName})';
}
