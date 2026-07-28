import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/services/measurement_service.dart';
import 'package:gym_app/src/domain/entities/body_measurement.dart';
import 'package:gym_app/src/domain/ports/output/measurement_repository_port.dart';
import 'package:mocktail/mocktail.dart';

class _MockMeasurementRepository extends Mock implements MeasurementRepositoryPort {}

void main() {
  late _MockMeasurementRepository repo;
  late MeasurementService service;
  const userId = 'u1';

  setUp(() {
    repo = _MockMeasurementRepository();
    service = MeasurementService(repo);
  });

  BodyMeasurement measurementAt(DateTime date, {double? weightKg}) {
    final m = BodyMeasurement.create(userId: userId, weightKg: weightKg);
    return BodyMeasurement.restore({...m.toMap(), 'date': date.toIso8601String()});
  }

  group('getHistory', () {
    test('ordena por fecha descendente sin importar el orden del repositorio', () async {
      final oldest = measurementAt(DateTime(2026, 1, 1));
      final newest = measurementAt(DateTime(2026, 1, 15));
      when(() => repo.getHistory(userId, limit: 30))
          .thenAnswer((_) async => [oldest, newest]);

      final history = await service.getHistory(userId);

      expect(history.first.date, DateTime(2026, 1, 15));
      expect(history.last.date, DateTime(2026, 1, 1));
    });

    test('si el repositorio falla, devuelve lista vacía en vez de propagar el error', () async {
      when(() => repo.getHistory(userId, limit: 30)).thenThrow(Exception('offline'));

      final history = await service.getHistory(userId);

      expect(history, isEmpty);
    });
  });

  group('getLatest', () {
    test('devuelve la medición más reciente', () async {
      final oldest = measurementAt(DateTime(2026, 1, 1));
      final newest = measurementAt(DateTime(2026, 1, 15));
      when(() => repo.getHistory(userId, limit: 1)).thenAnswer((_) async => [newest]);
      when(() => repo.getHistory(userId, limit: 30))
          .thenAnswer((_) async => [oldest, newest]);

      final latest = await service.getLatest(userId);

      expect(latest?.date, DateTime(2026, 1, 15));
    });
  });

  group('getProgressSummary', () {
    test('sin mediciones: devuelve el resumen vacío', () async {
      when(() => repo.getHistory(userId, limit: 30)).thenAnswer((_) async => []);

      final summary = await service.getProgressSummary(userId);

      expect(summary['totalMeasurements'], 0);
      expect(summary['weightChange'], 0.0);
      expect(summary['bmiCategory'], 'Sin datos');
    });

    test('con 2+ mediciones: calcula el cambio entre la más vieja y la más nueva', () async {
      final oldest = measurementAt(DateTime(2026, 1, 1), weightKg: 80);
      final newest = measurementAt(DateTime(2026, 1, 15), weightKg: 76);
      when(() => repo.getHistory(userId, limit: 30))
          .thenAnswer((_) async => [oldest, newest]);

      final summary = await service.getProgressSummary(userId);

      expect(summary['weightChange'], -4.0);
      expect(summary['totalMeasurements'], 2);
      expect(summary['trackingDays'], 14);
      expect(summary['startWeight'], 80);
      expect(summary['currentWeight'], 76);
    });

    test('si el repositorio falla, devuelve el resumen vacío en vez de propagar el error', () async {
      when(() => repo.getHistory(userId, limit: 30)).thenThrow(Exception('offline'));

      final summary = await service.getProgressSummary(userId);

      expect(summary['totalMeasurements'], 0);
    });
  });
}
