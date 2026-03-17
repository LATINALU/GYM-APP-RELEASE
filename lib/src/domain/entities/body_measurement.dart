/// Body Measurement domain entity - inspired by wger-project/flutter
/// Tracks physical measurements over time for progress analysis
class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPercentage;
  final double? heightCm;

  // Circumference measurements (cm)
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bicepsLeftCm;
  final double? bicepsRightCm;
  final double? thighLeftCm;
  final double? thighRightCm;
  final double? calfLeftCm;
  final double? calfRightCm;
  final double? shouldersCm;
  final double? neckCm;
  final double? forearmLeftCm;
  final double? forearmRightCm;

  final String? notes;
  final String? photoUrl;

  BodyMeasurement._({
    required this.id,
    required this.userId,
    required this.date,
    this.weightKg,
    this.bodyFatPercentage,
    this.heightCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bicepsLeftCm,
    this.bicepsRightCm,
    this.thighLeftCm,
    this.thighRightCm,
    this.calfLeftCm,
    this.calfRightCm,
    this.shouldersCm,
    this.neckCm,
    this.forearmLeftCm,
    this.forearmRightCm,
    this.notes,
    this.photoUrl,
  });

  factory BodyMeasurement.create({
    required String userId,
    double? weightKg,
    double? bodyFatPercentage,
    double? heightCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bicepsLeftCm,
    double? bicepsRightCm,
    double? thighLeftCm,
    double? thighRightCm,
    double? calfLeftCm,
    double? calfRightCm,
    double? shouldersCm,
    double? neckCm,
    double? forearmLeftCm,
    double? forearmRightCm,
    String? notes,
  }) {
    return BodyMeasurement._(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: DateTime.now(),
      weightKg: weightKg,
      bodyFatPercentage: bodyFatPercentage,
      heightCm: heightCm,
      chestCm: chestCm,
      waistCm: waistCm,
      hipsCm: hipsCm,
      bicepsLeftCm: bicepsLeftCm,
      bicepsRightCm: bicepsRightCm,
      thighLeftCm: thighLeftCm,
      thighRightCm: thighRightCm,
      calfLeftCm: calfLeftCm,
      calfRightCm: calfRightCm,
      shouldersCm: shouldersCm,
      neckCm: neckCm,
      forearmLeftCm: forearmLeftCm,
      forearmRightCm: forearmRightCm,
      notes: notes,
    );
  }

  factory BodyMeasurement.restore(Map<String, dynamic> map) {
    return BodyMeasurement._(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      bodyFatPercentage: (map['bodyFatPercentage'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      chestCm: (map['chestCm'] as num?)?.toDouble(),
      waistCm: (map['waistCm'] as num?)?.toDouble(),
      hipsCm: (map['hipsCm'] as num?)?.toDouble(),
      bicepsLeftCm: (map['bicepsLeftCm'] as num?)?.toDouble(),
      bicepsRightCm: (map['bicepsRightCm'] as num?)?.toDouble(),
      thighLeftCm: (map['thighLeftCm'] as num?)?.toDouble(),
      thighRightCm: (map['thighRightCm'] as num?)?.toDouble(),
      calfLeftCm: (map['calfLeftCm'] as num?)?.toDouble(),
      calfRightCm: (map['calfRightCm'] as num?)?.toDouble(),
      shouldersCm: (map['shouldersCm'] as num?)?.toDouble(),
      neckCm: (map['neckCm'] as num?)?.toDouble(),
      forearmLeftCm: (map['forearmLeftCm'] as num?)?.toDouble(),
      forearmRightCm: (map['forearmRightCm'] as num?)?.toDouble(),
      notes: map['notes'],
      photoUrl: map['photoUrl'],
    );
  }

  /// Calculate BMI if weight and height are available
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  String? get bmiCategory {
    final b = bmi;
    if (b == null) return null;
    if (b < 18.5) return 'Bajo peso';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Lean body mass estimate (if body fat % is known)
  double? get leanBodyMassKg {
    if (weightKg == null || bodyFatPercentage == null) return null;
    return weightKg! * (1 - bodyFatPercentage! / 100);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'weightKg': weightKg,
    'bodyFatPercentage': bodyFatPercentage,
    'heightCm': heightCm,
    'chestCm': chestCm,
    'waistCm': waistCm,
    'hipsCm': hipsCm,
    'bicepsLeftCm': bicepsLeftCm,
    'bicepsRightCm': bicepsRightCm,
    'thighLeftCm': thighLeftCm,
    'thighRightCm': thighRightCm,
    'calfLeftCm': calfLeftCm,
    'calfRightCm': calfRightCm,
    'shouldersCm': shouldersCm,
    'neckCm': neckCm,
    'forearmLeftCm': forearmLeftCm,
    'forearmRightCm': forearmRightCm,
    'notes': notes,
    'photoUrl': photoUrl,
  };
}
