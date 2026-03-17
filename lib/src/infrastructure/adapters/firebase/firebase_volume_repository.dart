import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/src/domain/entities/muscle_volume.dart';
import 'package:gym_app/src/domain/ports/output/volume_repository_port.dart';
import '../../mappers/volume_mapper.dart';

class FirebaseVolumeRepository implements VolumeRepositoryPort {
  final FirebaseFirestore _firestore;
  FirebaseVolumeRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _records => _firestore.collection('volume_records');

  @override
  Future<MuscleVolumeRecord?> getCurrentWeek(String userId) async {
    final today = DateTime.now();
    final weekStart = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final snap = await _records
        .where('userId', isEqualTo: userId)
        .where('weekStart', isEqualTo: weekStart.toIso8601String())
        .limit(1)
        .get();
    
    if (snap.docs.isEmpty) return null;
    return VolumeMapper.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  @override
  Future<void> save(MuscleVolumeRecord record) async {
    await _records.doc(record.id).set(VolumeMapper.toFirestore(record));
  }

  @override
  Future<void> logSet({required String userId, required MuscleGroup muscle, required int reps, required double weightKg}) async {
    final today = DateTime.now();
    final weekStart = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    
    MuscleVolumeRecord? record = await getCurrentWeek(userId);
    
    record ??= MuscleVolumeRecord.create(userId: userId, weekStart: weekStart);

    final updated = record.addSet(muscle: muscle, reps: reps, weightKg: weightKg);
    await save(updated);
  }

  @override
  Future<List<MuscleVolumeRecord>> getHistory(String userId, {int weeks = 8}) async {
    final snap = await _records
        .where('userId', isEqualTo: userId)
        .orderBy('weekStart', descending: true)
        .limit(weeks)
        .get();
    return snap.docs.map((d) => VolumeMapper.fromFirestore(d.data(), d.id)).toList();
  }
}
