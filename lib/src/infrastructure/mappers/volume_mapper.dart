import 'package:gym_app/src/domain/entities/muscle_volume.dart';

class VolumeMapper {
  static Map<String, dynamic> toFirestore(MuscleVolumeRecord record) {
    return record.toMap();
  }

  static MuscleVolumeRecord fromFirestore(Map<String, dynamic> map, String id) {
    final data = Map<String, dynamic>.from(map);
    data['id'] = id;
    return MuscleVolumeRecord.restore(data);
  }
}
