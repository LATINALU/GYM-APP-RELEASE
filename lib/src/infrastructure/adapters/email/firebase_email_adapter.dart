import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../domain/ports/output/email_service_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase Email Adapter - Uses Firebase Extensions (Trigger Email)
/// 
/// This adapter writes emails to a Firestore collection that is watched
/// by the Firebase "Trigger Email" extension, which sends the emails via
/// a configured SMTP service (SendGrid, Mailgun, etc.)
/// 
/// Setup required:
/// 1. Install "Trigger Email" extension in Firebase Console
/// 2. Configure SMTP settings in the extension
/// 3. Create 'mail' collection in Firestore
class FirebaseEmailAdapter implements EmailServicePort {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();
  
  /// Collection where emails are queued for sending
  static const String _mailCollection = 'mail';

  FirebaseEmailAdapter(this._firestore);

  @override
  Future<EmailResult> sendWelcomeEmail({
    required Email to,
    required String userName,
    required String temporaryPassword,
    required String appDownloadLink,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'welcome',
          'data': {
            'userName': userName,
            'temporaryPassword': temporaryPassword,
            'appDownloadLink': appDownloadLink,
            'year': DateTime.now().year,
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Welcome email queued: ${docRef.id} -> ${to.value}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue welcome email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  @override
  Future<EmailResult> sendRoutineAssignedEmail({
    required Email to,
    required String clientName,
    required String routineName,
    required String assignedByName,
    required DateTime startDate,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'routine_assigned',
          'data': {
            'clientName': clientName,
            'routineName': routineName,
            'assignedByName': assignedByName,
            'startDate': _formatDate(startDate),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Routine assigned email queued: ${docRef.id}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue routine email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  @override
  Future<EmailResult> sendCheckInReminder({
    required Email to,
    required String clientName,
    required int daysSinceLastVisit,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'checkin_reminder',
          'data': {
            'clientName': clientName,
            'daysSinceLastVisit': daysSinceLastVisit,
            'motivationalMessage': _getMotivationalMessage(daysSinceLastVisit),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Check-in reminder email queued: ${docRef.id}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue reminder email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  @override
  Future<EmailResult> sendPasswordResetEmail({
    required Email to,
    required String userName,
    required String resetLink,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'password_reset',
          'data': {
            'userName': userName,
            'resetLink': resetLink,
            'expiresIn': '24 horas',
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Password reset email queued: ${docRef.id}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue password reset email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  @override
  Future<EmailResult> sendMembershipExpiryWarning({
    required Email to,
    required String clientName,
    required DateTime expiryDate,
    required int daysRemaining,
  }) async {
    try {
      final urgency = daysRemaining <= 3 ? 'urgent' : 'normal';
      
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'membership_expiry',
          'data': {
            'clientName': clientName,
            'expiryDate': _formatDate(expiryDate),
            'daysRemaining': daysRemaining,
            'urgency': urgency,
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Membership expiry email queued: ${docRef.id}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue membership expiry email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  @override
  Future<EmailResult> sendWeeklyProgressReport({
    required Email to,
    required String clientName,
    required int checkInsThisWeek,
    required int totalCheckIns,
    required String progressSummary,
  }) async {
    try {
      final docRef = await _firestore.collection(_mailCollection).add({
        'to': [to.value],
        'template': {
          'name': 'weekly_progress',
          'data': {
            'clientName': clientName,
            'checkInsThisWeek': checkInsThisWeek,
            'totalCheckIns': totalCheckIns,
            'progressSummary': progressSummary,
            'weekEnding': _formatDate(DateTime.now()),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Weekly progress email queued: ${docRef.id}');
      return EmailResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue weekly progress email', error: e);
      return EmailResult.failure(errorMessage: 'Error al enviar email: $e');
    }
  }

  // === HELPER METHODS ===
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMotivationalMessage(int daysSinceLastVisit) {
    if (daysSinceLastVisit <= 3) {
      return '¡Un pequeño descanso está bien! Vuelve cuando estés listo. 💪';
    } else if (daysSinceLastVisit <= 7) {
      return '¡Te esperamos de vuelta! Tu progreso te está esperando. 🏃';
    } else if (daysSinceLastVisit <= 14) {
      return '¡No pierdas el ritmo! Cada día cuenta hacia tus metas. 🎯';
    } else {
      return '¡Nunca es tarde para volver! Tu cuerpo te lo agradecerá. 🔥';
    }
  }
}
