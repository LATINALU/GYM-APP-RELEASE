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

  /// Columnas snake_case de `public.volume_records` (Fase 1 de la
  /// migración a Supabase, ver 0003_volume_records.sql).
  static Map<String, dynamic> toSupabase(MuscleVolumeRecord record) {
    final map = record.toMap();
    return {
      'id': map['id'],
      'user_id': map['userId'],
      'week_start': map['weekStart'],
      'volumes': map['volumes'],
    };
  }

  static MuscleVolumeRecord fromSupabase(Map<String, dynamic> row) {
    return MuscleVolumeRecord.restore({
      'id': row['id'],
      'userId': row['user_id'],
      'weekStart': row['week_start'],
      'volumes': row['volumes'],
    });
  }
}
