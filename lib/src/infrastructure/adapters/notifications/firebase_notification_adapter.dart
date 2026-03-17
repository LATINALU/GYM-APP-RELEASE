import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import '../../../domain/ports/output/notification_service_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase Cloud Messaging (FCM) Adapter for Push Notifications
/// 
/// This adapter handles:
/// 1. Sending push notifications to individual users
/// 2. Sending notifications to topics (groups)
/// 3. Managing FCM tokens
/// 4. Scheduling notifications via Firestore + Cloud Functions
class FirebaseNotificationAdapter implements NotificationServicePort {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  /// Collection for user FCM tokens
  static const String _tokensCollection = 'fcm_tokens';
  
  /// Collection for scheduled notifications
  static const String _scheduledCollection = 'scheduled_notifications';
  
  /// Collection for notification queue (processed by Cloud Functions)
  static const String _notificationQueue = 'notification_queue';

  FirebaseNotificationAdapter(this._messaging, this._firestore);

  @override
  Future<NotificationResult> sendPushNotification({
    required UserId userId,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // Get user's FCM token
      final token = await getFcmToken(userId);
      if (token == null) {
        return NotificationResult.failure(
          errorMessage: 'Usuario no tiene token FCM registrado',
          userId: userId,
        );
      }

      // Queue notification for Cloud Function to process
      final docRef = await _firestore.collection(_notificationQueue).add({
        'type': 'single',
        'token': token,
        'userId': userId.value,
        'notification': {
          'title': title,
          'body': body,
          'imageUrl': imageUrl,
        },
        'data': data ?? {},
        'priority': priority.name,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Notification queued: ${docRef.id} -> ${userId.value}');
      return NotificationResult.success(
        messageId: docRef.id,
        userId: userId,
      );
    } catch (e) {
      _logger.e('Failed to queue notification', error: e);
      return NotificationResult.failure(
        errorMessage: 'Error al enviar notificación: $e',
        userId: userId,
      );
    }
  }

  @override
  Future<List<NotificationResult>> sendBulkNotification({
    required List<UserId> userIds,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    final results = <NotificationResult>[];

    // Send notifications in batches to avoid overwhelming the system
    const batchSize = 10;
    for (var i = 0; i < userIds.length; i += batchSize) {
      final batch = userIds.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((userId) => sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          priority: priority,
          data: data,
        )),
      );
      results.addAll(batchResults);
    }

    final successCount = results.where((r) => r.success).length;
    _logger.i('Bulk notification sent: $successCount/${userIds.length} successful');

    return results;
  }

  @override
  Future<NotificationResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Queue topic notification for Cloud Function
      final docRef = await _firestore.collection(_notificationQueue).add({
        'type': 'topic',
        'topic': topic,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Topic notification queued: ${docRef.id} -> $topic');
      return NotificationResult.success(messageId: docRef.id);
    } catch (e) {
      _logger.e('Failed to queue topic notification', error: e);
      return NotificationResult.failure(
        errorMessage: 'Error al enviar notificación a topic: $e',
      );
    }
  }

  @override
  Future<void> subscribeToTopic({
    required UserId userId,
    required String topic,
  }) async {
    try {
      await _messaging.subscribeToTopic(topic);
      
      // Track subscription in Firestore for management
      await _firestore
          .collection(_tokensCollection)
          .doc(userId.value)
          .update({
        'topics': FieldValue.arrayUnion([topic]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('User ${userId.value} subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Failed to subscribe to topic', error: e);
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeFromTopic({
    required UserId userId,
    required String topic,
  }) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      
      await _firestore
          .collection(_tokensCollection)
          .doc(userId.value)
          .update({
        'topics': FieldValue.arrayRemove([topic]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('User ${userId.value} unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Failed to unsubscribe from topic', error: e);
      rethrow;
    }
  }

  @override
  Future<String?> getFcmToken(UserId userId) async {
    try {
      final doc = await _firestore
          .collection(_tokensCollection)
          .doc(userId.value)
          .get();

      if (!doc.exists) return null;
      
      final data = doc.data();
      return data?['token'] as String?;
    } catch (e) {
      _logger.e('Failed to get FCM token', error: e);
      return null;
    }
  }

  @override
  Future<void> updateFcmToken({
    required UserId userId,
    required String token,
  }) async {
    try {
      await _firestore.collection(_tokensCollection).doc(userId.value).set({
        'token': token,
        'userId': userId.value,
        'platform': _getPlatform(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.i('FCM token updated for user: ${userId.value}');
    } catch (e) {
      _logger.e('Failed to update FCM token', error: e);
      rethrow;
    }
  }

  @override
  Future<ScheduledNotificationResult> scheduleNotification({
    required UserId userId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Validate scheduled time is in the future
      if (scheduledAt.isBefore(DateTime.now())) {
        return ScheduledNotificationResult.failure(
          errorMessage: 'La fecha programada debe ser en el futuro',
        );
      }

      final docRef = await _firestore.collection(_scheduledCollection).add({
        'userId': userId.value,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Scheduled notification created: ${docRef.id} for $scheduledAt');
      return ScheduledNotificationResult.success(
        notificationId: docRef.id,
        scheduledAt: scheduledAt,
      );
    } catch (e) {
      _logger.e('Failed to schedule notification', error: e);
      return ScheduledNotificationResult.failure(
        errorMessage: 'Error al programar notificación: $e',
      );
    }
  }

  @override
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_scheduledCollection)
          .doc(notificationId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Scheduled notification cancelled: $notificationId');
    } catch (e) {
      _logger.e('Failed to cancel scheduled notification', error: e);
      rethrow;
    }
  }

  // === HELPER METHODS ===

  String _getPlatform() {
    // In a real implementation, detect the platform
    return 'unknown';
  }

  /// Initialize FCM and request permissions
  /// Call this during app startup
  static Future<void> initialize(FirebaseMessaging messaging) async {
    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger().i('FCM: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      Logger().i('FCM: User granted provisional permission');
    } else {
      Logger().w('FCM: User denied permission');
    }

    // Get initial token
    final token = await messaging.getToken();
    Logger().i('FCM Token: $token');
  }
}
