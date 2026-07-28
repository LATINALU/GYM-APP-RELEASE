import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/notification_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationService service;
  const userId = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = NotificationService(firestore: firestore);
  });

  group('getNotifications', () {
    test('devuelve solo las notificaciones del usuario, más nuevas primero', () async {
      await service.send(userId: userId, title: 'Vieja', body: '...');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await service.send(userId: userId, title: 'Nueva', body: '...');
      await service.send(userId: 'otro-usuario', title: 'Ajena', body: '...');

      final notifications = await service.getNotifications(userId);

      expect(notifications.length, 2);
      expect(notifications.first.title, 'Nueva');
    });
  });

  group('getUnreadCount', () {
    test('cuenta solo las no leídas del usuario', () async {
      await firestore.collection('notifications').add({
        'userId': userId, 'isRead': false, 'title': 'A', 'body': '', 'createdAt': DateTime.now().toIso8601String(), 'type': 'general',
      });
      await firestore.collection('notifications').add({
        'userId': userId, 'isRead': true, 'title': 'B', 'body': '', 'createdAt': DateTime.now().toIso8601String(), 'type': 'general',
      });
      await firestore.collection('notifications').add({
        'userId': 'otro', 'isRead': false, 'title': 'C', 'body': '', 'createdAt': DateTime.now().toIso8601String(), 'type': 'general',
      });

      final count = await service.getUnreadCount(userId);

      expect(count, 1);
    });
  });

  group('markAllRead', () {
    test('marca como leídas todas las no leídas del usuario, sin tocar las de otros', () async {
      final mine = await firestore.collection('notifications').add({
        'userId': userId, 'isRead': false, 'title': 'A', 'body': '', 'createdAt': DateTime.now().toIso8601String(), 'type': 'general',
      });
      final other = await firestore.collection('notifications').add({
        'userId': 'otro', 'isRead': false, 'title': 'C', 'body': '', 'createdAt': DateTime.now().toIso8601String(), 'type': 'general',
      });

      await service.markAllRead(userId);

      final mineDoc = await firestore.collection('notifications').doc(mine.id).get();
      final otherDoc = await firestore.collection('notifications').doc(other.id).get();
      expect(mineDoc.data()!['isRead'], isTrue);
      expect(otherDoc.data()!['isRead'], isFalse);
    });
  });

  group('AppNotification.fromMap', () {
    test('usa NotificationType.general como fallback para un type desconocido', () {
      final notif = AppNotification.fromMap({
        'id': 'n1',
        'userId': userId,
        'title': 'T',
        'body': 'B',
        'type': 'tipo-inexistente',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'isRead': false,
      });

      expect(notif.type, NotificationType.general);
    });
  });
}
