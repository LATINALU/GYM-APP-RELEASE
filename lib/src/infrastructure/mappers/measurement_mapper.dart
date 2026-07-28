import 'package:gym_app/src/domain/entities/entities.dart';

class MeasurementMapper {
  static Map<String, dynamic> toFirestore(BodyMeasurement measurement) {
    return measurement.toMap();
  }

  static BodyMeasurement fromFirestore(Map<String, dynamic> map, String id) {
    final data = Map<String, dynamic>.from(map);
    data['id'] = id;
    return BodyMeasurement.restore(data);
  }

  /// Columnas snake_case de `public.body_measurements` (piloto Supabase).
  static Map<String, dynamic> toSupabase(BodyMeasurement measurement) {
    final map = measurement.toMap();
    return {
      'id': map['id'],
      'user_id': map['userId'],
      'date': map['date'],
      'weight_kg': map['weightKg'],
      'body_fat_percentage': map['bodyFatPercentage'],
      'height_cm': map['heightCm'],
      'chest_cm': map['chestCm'],
      'waist_cm': map['waistCm'],
      'hips_cm': map['hipsCm'],
      'biceps_left_cm': map['bicepsLeftCm'],
      'biceps_right_cm': map['bicepsRightCm'],
      'thigh_left_cm': map['thighLeftCm'],
      'thigh_right_cm': map['thighRightCm'],
      'calf_left_cm': map['calfLeftCm'],
      'calf_right_cm': map['calfRightCm'],
      'shoulders_cm': map['shouldersCm'],
      'neck_cm': map['neckCm'],
      'forearm_left_cm': map['forearmLeftCm'],
      'forearm_right_cm': map['forearmRightCm'],
      'notes': map['notes'],
      'photo_url': map['photoUrl'],
    };
  }

  static BodyMeasurement fromSupabase(Map<String, dynamic> row) {
    return BodyMeasurement.restore({
      'id': row['id'],
      'userId': row['user_id'],
      'date': row['date'],
      'weightKg': row['weight_kg'],
      'bodyFatPercentage': row['body_fat_percentage'],
      'heightCm': row['height_cm'],
      'chestCm': row['chest_cm'],
      'waistCm': row['waist_cm'],
      'hipsCm': row['hips_cm'],
      'bicepsLeftCm': row['biceps_left_cm'],
      'bicepsRightCm': row['biceps_right_cm'],
      'thighLeftCm': row['thigh_left_cm'],
      'thighRightCm': row['thigh_right_cm'],
      'calfLeftCm': row['calf_left_cm'],
      'calfRightCm': row['calf_right_cm'],
      'shouldersCm': row['shoulders_cm'],
      'neckCm': row['neck_cm'],
      'forearmLeftCm': row['forearm_left_cm'],
      'forearmRightCm': row['forearm_right_cm'],
      'notes': row['notes'],
      'photoUrl': row['photo_url'],
    });
  }
}
