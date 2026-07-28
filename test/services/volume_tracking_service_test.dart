import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/volume_tracking_service.dart';
import 'package:gym_app/src/domain/entities/muscle_volume.dart';
import 'package:gym_app/src/domain/ports/output/volume_repository_port.dart';
import 'package:mocktail/mocktail.dart';

class _MockVolumeRepository extends Mock implements VolumeRepositoryPort {}

void main() {
  late _MockVolumeRepository repo;
  late VolumeTrackingService service;
  const userId = 'u1';

  setUp(() {
    repo = _MockVolumeRepository();
    service = VolumeTrackingService(repo);
  });

  DateTime weekStartOf(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  group('getCurrentWeek', () {
    test('sin historial: crea un registro vacío para la semana actual', () async {
      when(() => repo.getHistory(userId, weeks: 1)).thenAnswer((_) async => []);

      final record = await service.getCurrentWeek(userId);

      expect(record.userId, userId);
      expect(record.totalVolume, 0);
      expect(record.weekStart, weekStartOf(DateTime.now()));
    });

    test('con historial de la semana actual: devuelve ese registro', () async {
      final currentWeekStart = weekStartOf(DateTime.now());
      final existing = MuscleVolumeRecord.create(userId: userId, weekStart: currentWeekStart)
          .addSet(muscle: MuscleGroup.chest, reps: 8, weightKg: 60);
      when(() => repo.getHistory(userId, weeks: 1)).thenAnswer((_) async => [existing]);

      final record = await service.getCurrentWeek(userId);

      expect(record.totalVolume, 480);
    });

    test('con historial de una semana pasada: crea un registro nuevo en vez de reusar el viejo', () async {
      final lastWeek = weekStartOf(DateTime.now()).subtract(const Duration(days: 7));
      final stale = MuscleVolumeRecord.create(userId: userId, weekStart: lastWeek)
          .addSet(muscle: MuscleGroup.back, reps: 10, weightKg: 50);
      when(() => repo.getHistory(userId, weeks: 1)).thenAnswer((_) async => [stale]);

      final record = await service.getCurrentWeek(userId);

      expect(record.totalVolume, 0);
      expect(record.weekStart, weekStartOf(DateTime.now()));
    });

    test('si el repositorio falla: devuelve un registro vacío en vez de propagar el error', () async {
      when(() => repo.getHistory(userId, weeks: 1)).thenThrow(Exception('offline'));

      final record = await service.getCurrentWeek(userId);

      expect(record.totalVolume, 0);
      expect(record.userId, userId);
    });
  });

  group('logSet', () {
    test('delega en el repositorio con los parámetros exactos', () async {
      when(() => repo.logSet(userId: userId, muscle: MuscleGroup.quads, reps: 5, weightKg: 100))
          .thenAnswer((_) async {});
      when(() => repo.getHistory(userId, weeks: 1)).thenAnswer((_) async => []);

      await service.logSet(userId: userId, muscle: MuscleGroup.quads, reps: 5, weightKg: 100);

      verify(() => repo.logSet(userId: userId, muscle: MuscleGroup.quads, reps: 5, weightKg: 100))
          .called(1);
    });
  });

  group('getHistory', () {
    test('si el repositorio falla: devuelve lista vacía en vez de propagar el error', () async {
      when(() => repo.getHistory(userId, weeks: 8)).thenThrow(Exception('offline'));

      final history = await service.getHistory(userId);

      expect(history, isEmpty);
    });
  });

  group('getDistribution', () {
    test('calcula el porcentaje de volumen por músculo sobre el total', () async {
      final currentWeekStart = weekStartOf(DateTime.now());
      final record = MuscleVolumeRecord.create(userId: userId, weekStart: currentWeekStart)
          .addSet(muscle: MuscleGroup.chest, reps: 10, weightKg: 60) // 600
          .addSet(muscle: MuscleGroup.back, reps: 10, weightKg: 40); // 400
      when(() => repo.getHistory(userId, weeks: 1)).thenAnswer((_) async => [record]);

      final distribution = await service.getDistribution(userId);

      expect(distribution['totalVolume'], 1000);
      expect(distribution['distribution']['Pecho'], 60.0);
      expect(distribution['distribution']['Espalda'], 40.0);
    });
  });

  group('compareWeeks', () {
    test('con menos de 2 semanas de historial: no hay comparación', () async {
      when(() => repo.getHistory(userId, weeks: 2)).thenAnswer((_) async => []);

      final result = await service.compareWeeks(userId);

      expect(result['hasComparison'], false);
    });

    test('con 2 semanas de historial: calcula cambio de volumen y porcentaje', () async {
      final w1 = weekStartOf(DateTime.now());
      final w0 = w1.subtract(const Duration(days: 7));
      final current = MuscleVolumeRecord.create(userId: userId, weekStart: w1)
          .addSet(muscle: MuscleGroup.chest, reps: 10, weightKg: 60); // 600
      final previous = MuscleVolumeRecord.create(userId: userId, weekStart: w0)
          .addSet(muscle: MuscleGroup.chest, reps: 10, weightKg: 40); // 400
      when(() => repo.getHistory(userId, weeks: 2)).thenAnswer((_) async => [current, previous]);

      final result = await service.compareWeeks(userId);

      expect(result['hasComparison'], true);
      expect(result['currentVolume'], 600);
      expect(result['previousVolume'], 400);
      expect(result['volumeChange'], 200);
      expect(result['changePercent'], 50.0);
    });

    test('si la semana previa no tuvo volumen: el cambio porcentual es 0 (evita división por cero)', () async {
      final w1 = weekStartOf(DateTime.now());
      final w0 = w1.subtract(const Duration(days: 7));
      final current = MuscleVolumeRecord.create(userId: userId, weekStart: w1)
          .addSet(muscle: MuscleGroup.chest, reps: 10, weightKg: 60);
      final previous = MuscleVolumeRecord.create(userId: userId, weekStart: w0);
      when(() => repo.getHistory(userId, weeks: 2)).thenAnswer((_) async => [current, previous]);

      final result = await service.compareWeeks(userId);

      expect(result['changePercent'], 0);
    });
  });
}
