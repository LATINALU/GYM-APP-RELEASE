import 'package:gym_app/src/domain/entities/recovery_log.dart';

class RecoveryMapper {
  static Map<String, dynamic> toFirestore(RecoveryLog log) {
    return log.toMap();
  }

  static RecoveryLog fromFirestore(Map<String, dynamic> map, String id) {
    final data = Map<String, dynamic>.from(map);
    data['id'] = id;
    return RecoveryLog.restore(data);
  }
}
