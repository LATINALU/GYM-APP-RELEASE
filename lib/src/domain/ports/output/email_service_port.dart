import '../../value_objects/value_objects.dart';

/// Email Service Port - Output Port for sending emails
/// Part of the domain layer, defines the contract for email services
abstract class EmailServicePort {
  /// Send welcome email to new user with temporary credentials
  Future<EmailResult> sendWelcomeEmail({
    required Email to,
    required String userName,
    required String temporaryPassword,
    required String appDownloadLink,
  });

  /// Send notification when a routine is assigned to client
  Future<EmailResult> sendRoutineAssignedEmail({
    required Email to,
    required String clientName,
    required String routineName,
    required String assignedByName,
    required DateTime startDate,
  });

  /// Send check-in reminder to inactive clients
  Future<EmailResult> sendCheckInReminder({
    required Email to,
    required String clientName,
    required int daysSinceLastVisit,
  });

  /// Send password reset email
  Future<EmailResult> sendPasswordResetEmail({
    required Email to,
    required String userName,
    required String resetLink,
  });

  /// Send membership expiry warning
  Future<EmailResult> sendMembershipExpiryWarning({
    required Email to,
    required String clientName,
    required DateTime expiryDate,
    required int daysRemaining,
  });

  /// Send weekly progress report to client
  Future<EmailResult> sendWeeklyProgressReport({
    required Email to,
    required String clientName,
    required int checkInsThisWeek,
    required int totalCheckIns,
    required String progressSummary,
  });
}

/// Result of an email operation
class EmailResult {
  final bool success;
  final String? messageId;
  final String? errorMessage;
  final DateTime sentAt;

  const EmailResult._({
    required this.success,
    this.messageId,
    this.errorMessage,
    required this.sentAt,
  });

  factory EmailResult.success({required String messageId}) {
    return EmailResult._(
      success: true,
      messageId: messageId,
      sentAt: DateTime.now(),
    );
  }

  factory EmailResult.failure({required String errorMessage}) {
    return EmailResult._(
      success: false,
      errorMessage: errorMessage,
      sentAt: DateTime.now(),
    );
  }

  @override
  String toString() => success 
    ? 'EmailResult.success(messageId: $messageId)' 
    : 'EmailResult.failure(error: $errorMessage)';
}

/// Email template types for structured email generation
enum EmailTemplateType {
  welcome,
  routineAssigned,
  checkInReminder,
  passwordReset,
  membershipExpiry,
  weeklyProgress,
}

/// Email template data container
class EmailTemplateData {
  final EmailTemplateType type;
  final Map<String, dynamic> variables;
  final String? customSubject;

  const EmailTemplateData({
    required this.type,
    required this.variables,
    this.customSubject,
  });

  String get defaultSubject {
    switch (type) {
      case EmailTemplateType.welcome:
        return '¡Bienvenido a Gym App! 🏋️';
      case EmailTemplateType.routineAssigned:
        return '¡Nueva rutina asignada! 💪';
      case EmailTemplateType.checkInReminder:
        return 'Te extrañamos en el gym 🏃';
      case EmailTemplateType.passwordReset:
        return 'Restablecer contraseña';
      case EmailTemplateType.membershipExpiry:
        return '⚠️ Tu membresía está por vencer';
      case EmailTemplateType.weeklyProgress:
        return '📊 Tu progreso semanal';
    }
  }

  String get subject => customSubject ?? defaultSubject;
}
