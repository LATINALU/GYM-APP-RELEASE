/// Recovery Log domain entity - GYM-APP
/// Tracks recovery metrics to optimize training and prevent overtraining
class RecoveryLog {
  final String id;
  final String userId;
  final DateTime date;
  final double sleepHours;
  final SleepQuality sleepQuality;
  final double hydrationLiters;
  final int stressLevel; // 1-10
  final Map<String, SorenessLevel> muscleSoreness;
  final int energyLevel; // 1-10
  final int motivationLevel; // 1-10
  final double? heartRateResting;
  final String? notes;

  RecoveryLog._({
    required this.id,
    required this.userId,
    required this.date,
    required this.sleepHours,
    required this.sleepQuality,
    required this.hydrationLiters,
    required this.stressLevel,
    required this.muscleSoreness,
    required this.energyLevel,
    required this.motivationLevel,
    this.heartRateResting,
    this.notes,
  });

  factory RecoveryLog.create({
    required String userId,
    required double sleepHours,
    required SleepQuality sleepQuality,
    required double hydrationLiters,
    required int stressLevel,
    Map<String, SorenessLevel>? muscleSoreness,
    required int energyLevel,
    required int motivationLevel,
    double? heartRateResting,
    String? notes,
  }) {
    if (stressLevel < 1 || stressLevel > 10) {
      throw ArgumentError('Stress level must be between 1 and 10');
    }
    if (energyLevel < 1 || energyLevel > 10) {
      throw ArgumentError('Energy level must be between 1 and 10');
    }
    return RecoveryLog._(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: DateTime.now(),
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
      hydrationLiters: hydrationLiters,
      stressLevel: stressLevel.clamp(1, 10),
      muscleSoreness: muscleSoreness ?? {},
      energyLevel: energyLevel.clamp(1, 10),
      motivationLevel: motivationLevel.clamp(1, 10),
      heartRateResting: heartRateResting,
      notes: notes,
    );
  }

  factory RecoveryLog.restore(Map<String, dynamic> map) {
    return RecoveryLog._(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0,
      sleepQuality: SleepQuality.values.firstWhere(
        (e) => e.name == map['sleepQuality'],
        orElse: () => SleepQuality.fair,
      ),
      hydrationLiters: (map['hydrationLiters'] as num?)?.toDouble() ?? 0,
      stressLevel: (map['stressLevel'] as int?) ?? 5,
      muscleSoreness: _parseSoreness(map['muscleSoreness']),
      energyLevel: (map['energyLevel'] as int?) ?? 5,
      motivationLevel: (map['motivationLevel'] as int?) ?? 5,
      heartRateResting: (map['heartRateResting'] as num?)?.toDouble(),
      notes: map['notes'],
    );
  }

  static Map<String, SorenessLevel> _parseSoreness(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    return (raw as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SorenessLevel.values.firstWhere(
        (e) => e.name == v,
        orElse: () => SorenessLevel.none,
      )),
    );
  }

  /// Overall recovery score out of 100
  double get recoveryScore {
    double score = 0;
    // Sleep contribution (30%)
    score += (sleepHours / 8.0).clamp(0, 1) * 15;
    score += (sleepQuality.index / 3) * 15;
    // Hydration (15%)
    score += (hydrationLiters / 3.0).clamp(0, 1) * 15;
    // Stress inverse (20%)
    score += ((10 - stressLevel) / 9) * 20;
    // Energy (20%)
    score += (energyLevel / 10) * 20;
    // Motivation (15%)
    score += (motivationLevel / 10) * 15;
    return score.clamp(0, 100);
  }

  String get recoveryStatus {
    final s = recoveryScore;
    if (s >= 80) return 'Óptima';
    if (s >= 60) return 'Buena';
    if (s >= 40) return 'Moderada';
    return 'Baja — Descanso Recomendado';
  }

  bool get shouldTrainHeavy => recoveryScore >= 70;
  bool get shouldRest => recoveryScore < 40;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'sleepHours': sleepHours,
    'sleepQuality': sleepQuality.name,
    'hydrationLiters': hydrationLiters,
    'stressLevel': stressLevel,
    'muscleSoreness': muscleSoreness.map((k, v) => MapEntry(k, v.name)),
    'energyLevel': energyLevel,
    'motivationLevel': motivationLevel,
    'heartRateResting': heartRateResting,
    'notes': notes,
  };
}

enum SleepQuality {
  poor,
  fair,
  good,
  excellent;

  String get displayName {
    switch (this) {
      case SleepQuality.poor: return 'Mala';
      case SleepQuality.fair: return 'Regular';
      case SleepQuality.good: return 'Buena';
      case SleepQuality.excellent: return 'Excelente';
    }
  }
}

enum SorenessLevel {
  none,
  mild,
  moderate,
  severe;

  String get displayName {
    switch (this) {
      case SorenessLevel.none: return 'Sin dolor';
      case SorenessLevel.mild: return 'Leve';
      case SorenessLevel.moderate: return 'Moderado';
      case SorenessLevel.severe: return 'Severo';
    }
  }
}
