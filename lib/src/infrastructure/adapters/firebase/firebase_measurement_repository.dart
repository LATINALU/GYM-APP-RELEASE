import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/src/domain/entities/body_measurement.dart';
import 'package:gym_app/src/domain/ports/output/measurement_repository_port.dart';
import '../../mappers/measurement_mapper.dart';

class FirebaseMeasurementRepository implements MeasurementRepositoryPort {
  final FirebaseFirestore _firestore;
  FirebaseMeasurementRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _measurements => _firestore.collection('body_measurements');

  @override
  Future<void> save(BodyMeasurement measurement) async {
    await _measurements.doc(measurement.id).set(MeasurementMapper.toFirestore(measurement));
  }

  @override
  Future<List<BodyMeasurement>> getHistory(String userId, {int limit = 30}) async {
    final snap = await _measurements
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => MeasurementMapper.fromFirestore(d.data(), d.id)).toList();
  }

  @override
  Future<BodyMeasurement?> getLatest(String userId) async {
    final snap = await _measurements
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MeasurementMapper.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  @override
  Future<void> delete(String measurementId) async {
    await _measurements.doc(measurementId).delete();
  }

  @override
  Future<List<BodyMeasurement>> getByDateRange(String userId, DateTime from, DateTime to) async {
    final snap = await _measurements
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('date', isLessThanOrEqualTo: to.toIso8601String())
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => MeasurementMapper.fromFirestore(d.data(), d.id)).toList();
  }
}
