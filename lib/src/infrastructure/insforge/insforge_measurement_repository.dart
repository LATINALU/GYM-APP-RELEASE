import '../../domain/entities/body_measurement.dart';
import '../../domain/ports/output/measurement_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of MeasurementRepositoryPort
class InsForgeMeasurementRepository implements MeasurementRepositoryPort {
  final InsForgeClient _client;

  InsForgeMeasurementRepository(this._client);

  @override
  Future<void> save(BodyMeasurement measurement) async {
    try {
      await _client.insert('body_measurements', {
        'id': measurement.id,
        'user_id': measurement.userId,
        'weight': measurement.weightKg,
        'body_fat_percentage': measurement.bodyFatPercentage,
        'chest': measurement.chestCm,
        'waist': measurement.waistCm,
        'hips': measurement.hipsCm,
        'biceps': measurement.bicepsLeftCm,
        'thighs': measurement.thighLeftCm,
        'calves': measurement.calfLeftCm,
        'notes': measurement.notes,
        'measured_at': measurement.date.toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<List<BodyMeasurement>> getHistory(String userId, {int limit = 30}) async {
    try {
      final response = await _client.from('body_measurements',
          query: 'user_id=eq.$userId&select=*&order=measured_at.desc&limit=$limit');
      if (!response.isSuccess) return [];
      return response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<BodyMeasurement?> getLatest(String userId) async {
    try {
      final response = await _client.from('body_measurements',
          query: 'user_id=eq.$userId&select=*&order=measured_at.desc&limit=1');
      if (!response.isSuccess || response.dataList.isEmpty) return null;
      return _map(response.firstItem!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String measurementId) async {
    try {
      await _client.delete('body_measurements', 'id=eq.$measurementId');
    } catch (_) {}
  }

  @override
  Future<List<BodyMeasurement>> getByDateRange(String userId, DateTime from, DateTime to) async {
    try {
      final response = await _client.from('body_measurements',
          query: 'user_id=eq.$userId&measured_at=gte.${from.toIso8601String()}&measured_at=lte.${to.toIso8601String()}&select=*&order=measured_at.desc');
      if (!response.isSuccess) return [];
      return response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  BodyMeasurement _map(Map<String, dynamic> data) {
    return BodyMeasurement.restore({
      'id': data['id'] as String? ?? '',
      'userId': data['user_id'] as String? ?? '',
      'date': data['measured_at'] as String? ?? DateTime.now().toIso8601String(),
      'weightKg': data['weight'],
      'bodyFatPercentage': data['body_fat_percentage'],
      'chestCm': data['chest'],
      'waistCm': data['waist'],
      'hipsCm': data['hips'],
      'bicepsLeftCm': data['biceps'],
      'thighLeftCm': data['thighs'],
      'calfLeftCm': data['calves'],
      'notes': data['notes'],
    });
  }
}
