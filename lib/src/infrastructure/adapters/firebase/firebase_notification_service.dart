import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/ports/output/notification_service_port.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Firebase implementation of NotificationServicePort
/// Handles FCM token management and queues notifications in Firestore
class FirebaseNotificationService implements NotificationServicePort {
  final FirebaseFirestore _firestore;

  static const String _tokensCollection = 'fcmTokens';
  static const String _notificationsCollection = 'notifications';
  static const String _usersCollection = 'users';

  FirebaseNotificationService(this._firestore);

  Future<String> _resolveGymIdByUserId(String userId) async {
    final userDoc =
        await _firestore.collection(_usersCollection).doc(userId).get();
    final gymId = userDoc.data()?['gymId']?.toString();
    if (gymId == null || gymId.trim().isEmpty) {
      throw Exception('gymId no disponible para usuario $userId');
    }
    return gymId;
  }

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
      final docRef = await _firestore.collection(_notificationsCollection).add({
        'recipientId': userId.value,
        'title': title,
        'body': body,
        'priority': priority.name,
        'data': data,
        'imageUrl': imageUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return NotificationResult.success(messageId: docRef.id, userId: userId);
    } catch (e) {
      return NotificationResult.failure(
        errorMessage: e.toString(),
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
    // En producción usaría un batch o una Cloud Function que reciba la lista
    for (final id in userIds) {
      results.add(
        await sendPushNotification(
          userId: id,
          title: title,
          body: body,
          priority: priority,
          data: data,
        ),
      );
    }
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
      final docRef = await _firestore.collection(_notificationsCollection).add({
        'topic': topic,
        'title': title,
        'body': body,
        'data': data,
        'status': 'pending',
        'type': 'topic',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return NotificationResult.success(messageId: docRef.id);
    } catch (e) {
      return NotificationResult.failure(errorMessage: e.toString());
    }
  }

  @override
  Future<void> subscribeToTopic({
    required UserId userId,
    required String topic,
  }) async {
    // Esto generalmente se hace vía Cloud Function o directamente
    // en el cliente usando FirebaseMessaging.instance.subscribeToTopic(topic)
    // Guardamos la intención en Firestore para consistencia
    final gymId = await _resolveGymIdByUserId(userId.value);
    await _firestore.collection('subscriptions').add({
      'gymId': gymId,
      'userId': userId.value,
      'topic': topic,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unsubscribeFromTopic({
    required UserId userId,
    required String topic,
  }) async {
    final gymId = await _resolveGymIdByUserId(userId.value);
    final query =
        await _firestore
            .collection('subscriptions')
            .where('gymId', isEqualTo: gymId)
            .where('userId', isEqualTo: userId.value)
            .where('topic', isEqualTo: topic)
            .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<String?> getFcmToken(UserId userId) async {
    final doc =
        await _firestore.collection(_tokensCollection).doc(userId.value).get();
    if (doc.exists) {
      return doc.data()?['token'] as String?;
    }
    return null;
  }

  @override
  Future<void> updateFcmToken({
    required UserId userId,
    required String token,
  }) async {
    await _firestore.collection(_tokensCollection).doc(userId.value).set({
      'token': token,
      'lastUpdated': FieldValue.serverTimestamp(),
      'platform': 'unknown', // Se podría pasar como parámetro
    });
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
      final docRef = await _firestore
          .collection('scheduled_notifications')
          .add({
            'recipientId': userId.value,
            'title': title,
            'body': body,
            'scheduledAt': Timestamp.fromDate(scheduledAt),
            'data': data,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });

      return ScheduledNotificationResult.success(
        notificationId: docRef.id,
        scheduledAt: scheduledAt,
      );
    } catch (e) {
      return ScheduledNotificationResult.failure(errorMessage: e.toString());
    }
  }

  @override
  Future<void> cancelScheduledNotification(String notificationId) async {
    await _firestore
        .collection('scheduled_notifications')
        .doc(notificationId)
        .update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
  }
}
