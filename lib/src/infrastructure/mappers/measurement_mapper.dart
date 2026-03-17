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
}
