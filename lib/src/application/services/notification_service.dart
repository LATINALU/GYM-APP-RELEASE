import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification service for push-style alerts
class NotificationService {
  final FirebaseFirestore _firestore;
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notifs => _firestore.collection('notifications');

  Future<List<AppNotification>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snap =
          await _notifs
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();
      return snap.docs
          .map((d) => AppNotification.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return const [];
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snap =
          await _notifs
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _notifs.doc(notifId).update({'isRead': true});
    } catch (e) {
      /* no-op */
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      final snap =
          await _notifs
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      /* no-op */
    }
  }

  Future<void> send({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    String? actionRoute,
  }) async {
    try {
      final notif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
        actionRoute: actionRoute,
      );
      await _notifs.doc(notif.id).set(notif.toMap());
    } catch (e) {
      /* no-op */
    }
  }
}

class AppNotification {
  final String id, userId, title, body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.actionRoute,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'] ?? '',
    userId: m['userId'] ?? '',
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.name == m['type'],
      orElse: () => NotificationType.general,
    ),
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    isRead: m['isRead'] ?? false,
    actionRoute: m['actionRoute'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'actionRoute': actionRoute,
  };
}

enum NotificationType {
  general,
  achievement,
  membership,
  classReminder,
  payment,
  promotion,
  health;

  String get icon {
    switch (this) {
      case general:
        return '📢';
      case achievement:
        return '🏆';
      case membership:
        return '💳';
      case classReminder:
        return '📅';
      case payment:
        return '💰';
      case promotion:
        return '🎁';
      case health:
        return '❤️';
    }
  }
}
