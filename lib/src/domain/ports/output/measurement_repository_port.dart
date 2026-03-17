import 'package:gym_app/src/domain/entities/body_measurement.dart';

/// PORT - Output interface for body measurement persistence
abstract class MeasurementRepositoryPort {
  Future<void> save(BodyMeasurement measurement);
  Future<List<BodyMeasurement>> getHistory(String userId, {int limit = 30});
  Future<BodyMeasurement?> getLatest(String userId);
  Future<void> delete(String measurementId);
  Future<List<BodyMeasurement>> getByDateRange(
    String userId,
    DateTime from,
    DateTime to,
  );
}
