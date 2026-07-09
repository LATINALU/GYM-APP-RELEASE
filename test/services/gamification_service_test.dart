import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/gamification_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late GamificationService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = GamificationService(firestore: firestore);
  });

  group('getProfile', () {
    test('devuelve perfil vacío si el documento no existe', () async {
      final profile = await service.getProfile('nuevo');

      expect(profile.userId, 'nuevo');
      expect(profile.totalXp, 0);
      expect(profile.level, 1);
      expect(profile.achievements, isEmpty);
    });

    test('parsea datos y deriva el nivel del XP cuando level es 0', () async {
      await firestore.collection('gamification').doc('u1').set({
        'totalXp': 1200,
        'currentStreak': 4,
        'longestStreak': 9,
        'totalWorkouts': 30,
      });

      final profile = await service.getProfile('u1');

      expect(profile.totalXp, 1200);
      expect(profile.level, 3); // (1200 / 500).floor() + 1
      expect(profile.currentStreak, 4);
      expect(profile.longestStreak, 9);
    });

    test('tolera achievements corruptos sin lanzar', () async {
      await firestore.collection('gamification').doc('u1').set({
        'totalXp': 100,
        'achievements': [
          'no-soy-un-mapa',
          {'campo': 'incompleto'},
        ],
      });

      final profile = await service.getProfile('u1');

      expect(profile.totalXp, 100);
    });
  });

  group('awardXp', () {
    test('crea el documento si no existe (usuario nuevo)', () async {
      await service.awardXp('nuevo', 50, 'workout');

      final doc =
          await firestore.collection('gamification').doc('nuevo').get();
      expect(doc.data()?['totalXp'], 50);
    });

    test('acumula XP en llamadas sucesivas', () async {
      await service.awardXp('u1', 50, 'workout');
      await service.awardXp('u1', 100, 'racha');

      final doc = await firestore.collection('gamification').doc('u1').get();
      expect(doc.data()?['totalXp'], 150);
      expect((doc.data()?['xpHistory'] as List).length, 2);
    });
  });

  group('updateStreak', () {
    test('primer workout inicia racha en 1 y crea el documento', () async {
      final streak = await service.updateStreak('nuevo');

      expect(streak, 1);
      final doc =
          await firestore.collection('gamification').doc('nuevo').get();
      expect(doc.data()?['currentStreak'], 1);
      expect(doc.data()?['longestStreak'], 1);
    });

    test('día consecutivo incrementa la racha', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await firestore.collection('gamification').doc('u1').set({
        'currentStreak': 3,
        'longestStreak': 5,
        'lastWorkoutDate': yesterday.toIso8601String(),
      });

      final streak = await service.updateStreak('u1');

      expect(streak, 4);
    });

    test('hueco de más de un día reinicia la racha a 1', () async {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      await firestore.collection('gamification').doc('u1').set({
        'currentStreak': 10,
        'longestStreak': 10,
        'lastWorkoutDate': lastWeek.toIso8601String(),
      });

      final streak = await service.updateStreak('u1');

      expect(streak, 1);
      final doc = await firestore.collection('gamification').doc('u1').get();
      // La racha más larga se conserva aunque la actual se reinicie.
      expect(doc.data()?['longestStreak'], 10);
    });

    test('actualiza longestStreak cuando la racha actual la supera', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await firestore.collection('gamification').doc('u1').set({
        'currentStreak': 5,
        'longestStreak': 5,
        'lastWorkoutDate': yesterday.toIso8601String(),
      });

      await service.updateStreak('u1');

      final doc = await firestore.collection('gamification').doc('u1').get();
      expect(doc.data()?['longestStreak'], 6);
    });
  });

  group('getLeaderboard', () {
    test('ordena por totalXp descendente y limita resultados', () async {
      await firestore.collection('gamification').doc('a').set({'totalXp': 10});
      await firestore.collection('gamification').doc('b').set({'totalXp': 300});
      await firestore.collection('gamification').doc('c').set({'totalXp': 100});

      final board = await service.getLeaderboard(limit: 2);

      expect(board.length, 2);
      expect(board.first['userId'], 'b');
      expect(board.last['userId'], 'c');
    });
  });
}
