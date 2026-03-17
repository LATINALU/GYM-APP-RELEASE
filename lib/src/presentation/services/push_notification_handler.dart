import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/ports/output/notification_service_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Handler for push notifications in the presentation layer
/// Responsible for device-specific initialization and foreground messages
class PushNotificationHandler {
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  PushNotificationHandler({
    required NotificationServicePort notificationService,
  });

  /// Stream to listen for notification clicks and navigate accordingly
  final StreamController<Map<String, dynamic>> _notificationClickStream = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationClick => _notificationClickStream.stream;

  Future<void> initialize(UserId userId) async {
    print('Push Notifications initialized for ${userId.value}');
    // 1. Request permissions (iOS/Android 13+)
    // await _fcm.requestPermission(...)
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'gym_app_channel',
            'Gym App Notifications',
            channelDescription: 'Standard notifications for Gym App',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void dispose() {
    _notificationClickStream.close();
  }
}
