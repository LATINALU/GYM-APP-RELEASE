import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper for RoutineAssignment entity to/from Firestore
class AssignmentMapper {
  /// Convert Firestore document to RoutineAssignment entity
  static RoutineAssignment fromFirestore(Map<String, dynamic> data, String id) {
    return RoutineAssignment.restore(
      id: AssignmentId(id),
      routineId: RoutineId(data['routineId'] as String),
      clientId: UserId(data['clientId'] as String),
      assignedById: UserId(data['assignedById'] as String),
      assignedAt: DateTime.parse(data['assignedAt'] as String),
      startDate: DateTime.parse(data['startDate'] as String),
      endDate: data['endDate'] != null
          ? DateTime.parse(data['endDate'] as String)
          : null,
      status: _statusFromString(data['status'] as String),
      notes: data['notes'] as String?,
    );
  }

  /// Convert RoutineAssignment entity to Firestore document
  static Map<String, dynamic> toFirestore(RoutineAssignment assignment) {
    return {
      'routineId': assignment.routineId.value,
      'clientId': assignment.clientId.value,
      'assignedById': assignment.assignedById.value,
      'assignedAt': assignment.assignedAt.toIso8601String(),
      'startDate': assignment.startDate.toIso8601String(),
      'endDate': assignment.endDate?.toIso8601String(),
      'status': assignment.status.name,
      'notes': assignment.notes,
    };
  }

  static AssignmentStatus _statusFromString(String value) {
    return AssignmentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AssignmentStatus.active,
    );
  }
}

/// Mapper for CheckIn entity to/from Firestore
class CheckInMapper {
  /// Convert Firestore document to CheckIn entity
  static CheckIn fromFirestore(Map<String, dynamic> data, String id) {
    return CheckIn.restore(
      id: CheckInId(id),
      clientId: UserId(data['clientId'] as String),
      checkInTime: DateTime.parse(data['checkInTime'] as String),
      checkOutTime: data['checkOutTime'] != null
          ? DateTime.parse(data['checkOutTime'] as String)
          : null,
      registeredById: data['registeredById'] != null
          ? UserId(data['registeredById'] as String)
          : null,
      notes: data['notes'] as String?,
    );
  }

  /// Convert CheckIn entity to Firestore document
  static Map<String, dynamic> toFirestore(CheckIn checkIn) {
    return {
      'clientId': checkIn.clientId.value,
      'checkInTime': checkIn.checkInTime.toIso8601String(),
      'checkOutTime': checkIn.checkOutTime?.toIso8601String(),
      'registeredById': checkIn.registeredById?.value,
      'notes': checkIn.notes,
    };
  }
}
