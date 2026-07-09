import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/ports/output/notification_service_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Handler for push notifications in the presentation layer
/// Responsible for device-specific initialization and foreground messages
class PushNotificationHandler {
  PushNotificationHandler({
    required NotificationServicePort notificationService,
  });

  /// Stream to listen for notification clicks and navigate accordingly
  final StreamController<Map<String, dynamic>> _notificationClickStream = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationClick => _notificationClickStream.stream;

  Future<void> initialize(UserId userId) async {
    debugPrint('Push Notifications initialized for ${userId.value}');
    // 1. Request permissions (iOS/Android 13+)
    // await _fcm.requestPermission(...)
  }

  void dispose() {
    _notificationClickStream.close();
  }
}
