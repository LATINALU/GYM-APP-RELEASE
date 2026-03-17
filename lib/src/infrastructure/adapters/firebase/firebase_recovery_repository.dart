import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/src/domain/entities/recovery_log.dart';
import 'package:gym_app/src/domain/ports/output/recovery_repository_port.dart';
import '../../mappers/recovery_mapper.dart';

class FirebaseRecoveryRepository implements RecoveryRepositoryPort {
  final FirebaseFirestore _firestore;
  FirebaseRecoveryRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection('recovery_logs');

  @override
  Future<void> save(RecoveryLog log) async {
    await _logs.doc(log.id).set(RecoveryMapper.toFirestore(log));
  }

  @override
  Future<RecoveryLog?> getToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final snap = await _logs
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RecoveryMapper.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  @override
  Future<List<RecoveryLog>> getHistory(String userId, {int limit = 14}) async {
    final snap = await _logs
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => RecoveryMapper.fromFirestore(d.data(), d.id)).toList();
  }

  @override
  Future<double> getAverageRecoveryScore(String userId, {int days = 7}) async {
    final logs = await getHistory(userId, limit: days);
    if (logs.isEmpty) return 0;
    return logs.fold(0.0, (s, l) => s + l.recoveryScore) / logs.length;
  }

  @override
  Future<void> delete(String logId) async {
    await _logs.doc(logId).delete();
  }
}
