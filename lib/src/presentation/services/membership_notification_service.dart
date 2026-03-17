import '../../domain/entities/entities.dart';

/// Service responsible for handling business-logic based notifications
class MembershipNotificationService {
  /// Checks if a user needs a renewal notification and simulates sending it.
  /// This would typically run in a background job or cloud function.
  static void checkAndNotifyRenewal(User user, Gym gym) {
    if (!gym.financeConfig.autoNotifyExpiration) return;

    if (user.needsRenewalNotification) {
      print('PUSH NOTIFICATION: Hola ${user.displayName}, tu membresía vence en 5 días. ¡No olvides renovar!');
      // In a real app, this would call the NotificationServicePort
    }
  }

  /// Batch process for a list of users
  static void processMonthlyRenewals(List<User> users, Gym gym) {
    for (var user in users) {
      checkAndNotifyRenewal(user, gym);
    }
  }
}
