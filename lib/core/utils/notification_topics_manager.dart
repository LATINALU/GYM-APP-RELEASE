import 'package:flutter/foundation.dart';
import '../../src/domain/value_objects/value_objects.dart';

/// Helper to manage FCM topic subscriptions based on roles and gyms
class NotificationTopicsManager {
  // static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Subscribe user to relevant topics based on their auth profile
  static Future<void> subscribeToUserTopics({
    required String gymId,
    required String userId,
    required GymRoleType role,
  }) async {
    debugPrint('Subscribing to topics for $userId in gym $gymId (Role: $role)');
    // if (role == GymRoleType.owner || role == GymRoleType.employee) {
    //   await _messaging.subscribeToTopic('gym_${gymId}_staff');
    // }
    // ...
  }

  /// Unsubscribe from all topics on logout
  static Future<void> unsubscribeFromUserTopics({
    required String gymId,
    required String userId,
    required GymRoleType role,
  }) async {
    debugPrint('Unsubscribing from topics for $userId');
  }
}
