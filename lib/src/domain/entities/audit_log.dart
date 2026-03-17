import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AuditAction {
  createExercise,
  updateExerciseMedia,
  createRoutine,
  updateSchedules,
  userAccess,
  securityAlert
}

class AuditLog extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final AuditAction action;
  final String details;
  final DateTime timestamp;
  final String? ipAddress;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.details,
    required this.timestamp,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'action': action.name,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
    };
  }

  @override
  List<Object?> get props => [id, userId, action, timestamp];
}
