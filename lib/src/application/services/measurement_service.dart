import '../../domain/entities/body_measurement.dart';
import '../../domain/ports/output/measurement_repository_port.dart';

/// Application Service for Body Measurements
/// Inspired by wger-project's measurement tracking
class MeasurementService {
  final MeasurementRepositoryPort _repo;

  MeasurementService(this._repo);

  /// Save a new measurement
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    await _repo.save(measurement);
  }

  /// Get measurement history sorted by date descending
  Future<List<BodyMeasurement>> getHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final List<BodyMeasurement> history = List<BodyMeasurement>.from(
        await _repo.getHistory(userId, limit: limit),
      );
      history.sort((a, b) => b.date.compareTo(a.date));
      return history;
    } catch (e) {
      return const [];
    }
  }

  /// Get latest measurement
  Future<BodyMeasurement?> getLatest(String userId) async {
    final history = await getHistory(userId, limit: 1);
    return history.isNotEmpty ? history.first : null;
  }

  /// Get progress summary comparing latest vs first measurement
  Future<Map<String, dynamic>> getProgressSummary(String userId) async {
    try {
      final history = await getHistory(userId);
      if (history.length < 2) {
        final latest = history.isNotEmpty ? history.first : null;
        return _emptyProgressSummary(
          currentWeight: latest?.weightKg,
          currentBmi: latest?.bmi,
          bmiCategory: latest?.bmiCategory,
          totalMeasurements: history.length,
        );
      }
      final latest = history.first;
      final oldest = history.last;
      return {
        'weightChange': (latest.weightKg ?? 0) - (oldest.weightKg ?? 0),
        'bodyFatChange':
            (latest.bodyFatPercentage ?? 0) - (oldest.bodyFatPercentage ?? 0),
        'chestChange': (latest.chestCm ?? 0) - (oldest.chestCm ?? 0),
        'waistChange': (latest.waistCm ?? 0) - (oldest.waistCm ?? 0),
        'bicepsChange':
            (latest.bicepsRightCm ?? 0) - (oldest.bicepsRightCm ?? 0),
        'totalMeasurements': history.length,
        'trackingDays': latest.date.difference(oldest.date).inDays,
        'currentBmi': latest.bmi,
        'bmiCategory': latest.bmiCategory,
        'currentWeight': latest.weightKg,
        'startWeight': oldest.weightKg,
      };
    } catch (e) {
      return _emptyProgressSummary();
    }
  }

  /// Delete a measurement
  Future<void> delete(String measurementId) async {
    await _repo.delete(measurementId);
  }

  Map<String, dynamic> _emptyProgressSummary({
    double? currentWeight,
    double? currentBmi,
    String? bmiCategory,
    int totalMeasurements = 0,
  }) => {
    'weightChange': 0.0,
    'bodyFatChange': 0.0,
    'chestChange': 0.0,
    'waistChange': 0.0,
    'bicepsChange': 0.0,
    'totalMeasurements': totalMeasurements,
    'trackingDays': 0,
    'currentBmi': currentBmi ?? 0.0,
    'bmiCategory': bmiCategory ?? 'Sin datos',
    'currentWeight': currentWeight ?? 0.0,
    'startWeight': currentWeight ?? 0.0,
  };
}
