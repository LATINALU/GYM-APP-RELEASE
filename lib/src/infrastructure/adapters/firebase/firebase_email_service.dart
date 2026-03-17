import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/ports/output/email_service_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase implementation of EmailServicePort
/// Uses the popular 'Trigger Email' Firebase extension pattern 
/// by writing to a 'mail' collection.
class FirebaseEmailService implements EmailServicePort {
  final FirebaseFirestore _firestore;
  
  static const String _mailCollection = 'mail';

  FirebaseEmailService(this._firestore);

  @override
  Future<EmailResult> sendWelcomeEmail({
    required Email to,
    required String userName,
    required String temporaryPassword,
    required String appDownloadLink,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'welcome',
      templateData: {
        'userName': userName,
        'temporaryPassword': temporaryPassword,
        'appDownloadLink': appDownloadLink,
        'year': DateTime.now().year,
      },
    );
  }

  @override
  Future<EmailResult> sendRoutineAssignedEmail({
    required Email to,
    required String clientName,
    required String routineName,
    required String assignedByName,
    required DateTime startDate,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'routine_assigned',
      templateData: {
        'clientName': clientName,
        'routineName': routineName,
        'assignedByName': assignedByName,
        'startDate': startDate.toIso8601String(),
      },
    );
  }

  @override
  Future<EmailResult> sendCheckInReminder({
    required Email to,
    required String clientName,
    required int daysSinceLastVisit,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'checkin_reminder',
      templateData: {
        'clientName': clientName,
        'daysSinceLastVisit': daysSinceLastVisit,
      },
    );
  }

  @override
  Future<EmailResult> sendPasswordResetEmail({
    required Email to,
    required String userName,
    required String resetLink,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'password_reset',
      templateData: {
        'userName': userName,
        'resetLink': resetLink,
      },
    );
  }

  @override
  Future<EmailResult> sendMembershipExpiryWarning({
    required Email to,
    required String clientName,
    required DateTime expiryDate,
    required int daysRemaining,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'membership_expiry',
      templateData: {
        'clientName': clientName,
        'expiryDate': expiryDate.toIso8601String(),
        'daysRemaining': daysRemaining,
      },
    );
  }

  @override
  Future<EmailResult> sendWeeklyProgressReport({
    required Email to,
    required String clientName,
    required int checkInsThisWeek,
    required int totalCheckIns,
    required String progressSummary,
  }) async {
    return _sendMail(
      to: to.value,
      template: 'weekly_progress',
      templateData: {
        'clientName': clientName,
        'checkInsThisWeek': checkInsThisWeek,
        'totalCheckIns': totalCheckIns,
        'progressSummary': progressSummary,
      },
    );
  }

  /// Helper to write to 'mail' collection
  Future<EmailResult> _sendMail({
    required String to,
    required String template,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to],
        'template': {
          'name': template,
          'data': templateData,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      return EmailResult.failure(errorMessage: e.toString());
    }
  }
}
