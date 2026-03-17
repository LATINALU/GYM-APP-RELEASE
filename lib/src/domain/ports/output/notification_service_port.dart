import '../../value_objects/value_objects.dart';

/// Notification Service Port - Output Port for push notifications
/// Part of the domain layer, defines the contract for notification services
abstract class NotificationServicePort {
  /// Send a push notification to a specific user
  Future<NotificationResult> sendPushNotification({
    required UserId userId,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
  });

  /// Send notification to multiple users
  Future<List<NotificationResult>> sendBulkNotification({
    required List<UserId> userIds,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  });

  /// Send notification to a topic (e.g., all clients, all employees)
  Future<NotificationResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });

  /// Subscribe user to a notification topic
  Future<void> subscribeToTopic({
    required UserId userId,
    required String topic,
  });

  /// Unsubscribe user from a notification topic
  Future<void> unsubscribeFromTopic({
    required UserId userId,
    required String topic,
  });

  /// Get user's FCM token for push notifications
  Future<String?> getFcmToken(UserId userId);

  /// Update user's FCM token
  Future<void> updateFcmToken({
    required UserId userId,
    required String token,
  });

  /// Schedule a notification for later
  Future<ScheduledNotificationResult> scheduleNotification({
    required UserId userId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, dynamic>? data,
  });

  /// Cancel a scheduled notification
  Future<void> cancelScheduledNotification(String notificationId);
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Result of a notification operation
class NotificationResult {
  final bool success;
  final String? messageId;
  final String? errorMessage;
  final UserId? userId;
  final DateTime sentAt;

  const NotificationResult._({
    required this.success,
    this.messageId,
    this.errorMessage,
    this.userId,
    required this.sentAt,
  });

  factory NotificationResult.success({
    required String messageId,
    UserId? userId,
  }) {
    return NotificationResult._(
      success: true,
      messageId: messageId,
      userId: userId,
      sentAt: DateTime.now(),
    );
  }

  factory NotificationResult.failure({
    required String errorMessage,
    UserId? userId,
  }) {
    return NotificationResult._(
      success: false,
      errorMessage: errorMessage,
      userId: userId,
      sentAt: DateTime.now(),
    );
  }

  @override
  String toString() => success
      ? 'NotificationResult.success(messageId: $messageId)'
      : 'NotificationResult.failure(error: $errorMessage)';
}

/// Result of scheduling a notification
class ScheduledNotificationResult {
  final bool success;
  final String? notificationId;
  final DateTime? scheduledAt;
  final String? errorMessage;

  const ScheduledNotificationResult._({
    required this.success,
    this.notificationId,
    this.scheduledAt,
    this.errorMessage,
  });

  factory ScheduledNotificationResult.success({
    required String notificationId,
    required DateTime scheduledAt,
  }) {
    return ScheduledNotificationResult._(
      success: true,
      notificationId: notificationId,
      scheduledAt: scheduledAt,
    );
  }

  factory ScheduledNotificationResult.failure({required String errorMessage}) {
    return ScheduledNotificationResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Predefined notification topics for the gym app
class NotificationTopics {
  static const String allUsers = 'all_users';
  static const String allClients = 'clients';
  static const String allEmployees = 'employees';
  static const String owners = 'owners';
  static const String promotions = 'promotions';
  static const String announcements = 'announcements';
  
  /// Get topic for a specific gym role
  static String forRole(GymRoleType roleType) {
    switch (roleType) {
      case GymRoleType.admin:
        return allUsers; // Or some specific admin topic
      case GymRoleType.owner:
        return owners;
      case GymRoleType.employee:
        return allEmployees;
      case GymRoleType.client:
        return allClients;
    }
  }

  NotificationTopics._();
}
