import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/workout_analysis_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WorkoutAnalysisService service;
  const userId = 'u1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = WorkoutAnalysisService(firestore: firestore);
  });

  DateTime day(int daysAgo) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: daysAgo));
  }

  Future<void> seedSession({
    required DateTime date,
    List<Map<String, dynamic>> exercises = const [],
    String uid = userId,
  }) {
    return firestore.collection('workout_sessions').add({
      'userId': uid,
      'date': Timestamp.fromDate(date),
      'exercises': exercises,
    }).then((_) {});
  }

  group('getAnalytics', () {
    test('sin sesiones: devuelve analytics vacío', () async {
      final analytics = await service.getAnalytics(userId);

      expect(analytics['totalWorkouts'], 0);
      expect(analytics['mostTrainedMuscle'], 'Sin datos');
      expect(analytics['currentStreak'], 0);
      expect(analytics['longestStreak'], 0);
    });

    test('racha actual cuenta días consecutivos desde hoy hacia atrás', () async {
      await seedSession(date: day(0));
      await seedSession(date: day(1));
      // hueco en day(2)..day(4)
      await seedSession(date: day(5));
      await seedSession(date: day(6));
      await seedSession(date: day(7));

      final analytics = await service.getAnalytics(userId);

      expect(analytics['currentStreak'], 2);
      expect(analytics['longestStreak'], 3);
    });

    test('calcula volumen total y promedio por sesión desde los sets', () async {
      await seedSession(date: day(0), exercises: [
        {
          'name': 'Press banca',
          'muscleGroup': 'Pecho',
          'sets': [
            {'reps': 8, 'weight': 80},
            {'reps': 8, 'weight': 80},
          ],
        },
      ]); // 1280
      await seedSession(date: day(1), exercises: [
        {
          'name': 'Sentadilla',
          'muscleGroup': 'Pierna',
          'sets': [
            {'reps': 5, 'weight': 100},
          ],
        },
      ]); // 500

      final analytics = await service.getAnalytics(userId);

      expect(analytics['totalVolume'], 1780);
      expect(analytics['avgVolumePerSession'], 890);
    });

    test('identifica el músculo más y menos entrenado', () async {
      await seedSession(date: day(0), exercises: [
        {'name': 'Press banca', 'muscleGroup': 'Pecho', 'sets': [{'reps': 8, 'weight': 60}]},
      ]);
      await seedSession(date: day(1), exercises: [
        {'name': 'Press inclinado', 'muscleGroup': 'Pecho', 'sets': [{'reps': 8, 'weight': 60}]},
      ]);
      await seedSession(date: day(2), exercises: [
        {'name': 'Sentadilla', 'muscleGroup': 'Pierna', 'sets': [{'reps': 5, 'weight': 100}]},
      ]);

      final analytics = await service.getAnalytics(userId);

      expect(analytics['mostTrainedMuscle'], 'Pecho');
      expect(analytics['leastTrainedMuscle'], 'Pierna');
    });

    test('no mezcla sesiones de otro usuario', () async {
      await seedSession(date: day(0), uid: 'otro-usuario');

      final analytics = await service.getAnalytics(userId);

      expect(analytics['totalWorkouts'], 0);
    });
  });

  group('getPersonalRecords', () {
    test('usa la colección personal_records cuando existe', () async {
      await firestore.collection('personal_records').add({
        'userId': userId,
        'exercise': 'Press banca',
        'weight': 100.0,
        'reps': 3,
        'date': DateTime(2026, 1, 10).toIso8601String(),
      });

      final records = await service.getPersonalRecords(userId);

      expect(records, hasLength(1));
      expect(records.first['exercise'], 'Press banca');
      expect(records.first['weight'], 100.0);
    });

    test('sin personal_records, deriva el PR de mayor peso desde las sesiones', () async {
      await seedSession(date: day(10), exercises: [
        {'name': 'Peso muerto', 'muscleGroup': 'Espalda', 'sets': [{'reps': 5, 'weight': 120}]},
      ]);
      await seedSession(date: day(3), exercises: [
        {'name': 'Peso muerto', 'muscleGroup': 'Espalda', 'sets': [{'reps': 3, 'weight': 140}]},
      ]);
      await seedSession(date: day(0), exercises: [
        {'name': 'Peso muerto', 'muscleGroup': 'Espalda', 'sets': [{'reps': 5, 'weight': 110}]},
      ]);

      final records = await service.getPersonalRecords(userId);

      expect(records, hasLength(1));
      expect(records.first['exercise'], 'Peso muerto');
      expect(records.first['weight'], 140.0);
      expect(records.first['previous'], 120.0);
    });
  });

  group('getFrequencyByDay', () {
    test('cuenta entrenamientos por día de la semana e inicializa el resto en 0', () async {
      final monday = DateTime(2026, 1, 5); // lunes
      await seedSession(date: monday);
      await seedSession(date: monday);
      await seedSession(date: monday.add(const Duration(days: 2))); // miércoles

      final frequency = await service.getFrequencyByDay(userId);

      expect(frequency['Lun'], 2);
      expect(frequency['Mié'], 1);
      expect(frequency['Mar'], 0);
      expect(frequency.keys, containsAll(['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']));
    });
  });
}
