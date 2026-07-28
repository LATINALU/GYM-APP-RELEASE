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

  /// Columnas snake_case de `public.recovery_logs` (Fase 1 de la migración
  /// a Supabase). gym_id se omite: RecoveryLog (dominio) no lo puebla hoy,
  /// la columna queda null y las políticas RLS lo toleran (ver 0002_recovery_logs.sql).
  static Map<String, dynamic> toSupabase(RecoveryLog log) {
    final map = log.toMap();
    return {
      'id': map['id'],
      'user_id': map['userId'],
      'date': map['date'],
      'sleep_hours': map['sleepHours'],
      'sleep_quality': map['sleepQuality'],
      'hydration_liters': map['hydrationLiters'],
      'stress_level': map['stressLevel'],
      'muscle_soreness': map['muscleSoreness'],
      'energy_level': map['energyLevel'],
      'motivation_level': map['motivationLevel'],
      'heart_rate_resting': map['heartRateResting'],
      'notes': map['notes'],
    };
  }

  static RecoveryLog fromSupabase(Map<String, dynamic> row) {
    return RecoveryLog.restore({
      'id': row['id'],
      'userId': row['user_id'],
      'date': row['date'],
      'sleepHours': row['sleep_hours'],
      'sleepQuality': row['sleep_quality'],
      'hydrationLiters': row['hydration_liters'],
      'stressLevel': row['stress_level'],
      'muscleSoreness': row['muscle_soreness'],
      'energyLevel': row['energy_level'],
      'motivationLevel': row['motivation_level'],
      'heartRateResting': row['heart_rate_resting'],
      'notes': row['notes'],
    });
  }
}
