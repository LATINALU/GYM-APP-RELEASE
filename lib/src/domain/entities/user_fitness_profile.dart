/// User Fitness Profile - Complete user data for gym tracking
import 'package:equatable/equatable.dart';

/// Experience level of the user
enum ExperienceLevel {
  beginner('Principiante', 'Menos de 6 meses'),
  intermediate('Intermedio', '6 meses - 2 años'),
  advanced('Avanzado', 'Más de 2 años');

  final String displayName;
  final String description;
  const ExperienceLevel(this.displayName, this.description);
}

/// Primary fitness goal
enum FitnessGoal {
  loseWeight('Perder Peso', '🔥', 'Déficit calórico + cardio'),
  buildMuscle('Ganar Masa', '💪', 'Superávit + hipertrofia'),
  maintain('Mantener', '⚖️', 'Balance calórico'),
  strength('Fuerza', '🏋️', 'Cargas pesadas, bajo rep'),
  endurance('Resistencia', '🏃', 'Cardio + circuitos'),
  definition('Definir', '✨', 'Déficit + alta intensidad');

  final String displayName;
  final String icon;
  final String description;
  const FitnessGoal(this.displayName, this.icon, this.description);
}

/// Gender for calculations
enum Gender {
  male('Masculino'),
  female('Femenino'),
  other('Otro');

  final String displayName;
  const Gender(this.displayName);
}

/// Weight entry for tracking history
class WeightEntry extends Equatable {
  final DateTime date;
  final double weight; // kg
  final String? notes;

  const WeightEntry({
    required this.date,
    required this.weight,
    this.notes,
  });

  @override
  List<Object?> get props => [date, weight, notes];

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'notes': notes,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    date: DateTime.parse(json['date']),
    weight: json['weight'].toDouble(),
    notes: json['notes'],
  );
}

/// Body measurement entry
class BodyMeasurement extends Equatable {
  final DateTime date;
  final Map<String, double> measurements; // cm - 'chest', 'waist', 'biceps', etc.

  const BodyMeasurement({
    required this.date,
    required this.measurements,
  });

  double? get chest => measurements['chest'];
  double? get waist => measurements['waist'];
  double? get hips => measurements['hips'];
  double? get bicepsLeft => measurements['biceps_left'];
  double? get bicepsRight => measurements['biceps_right'];
  double? get thighLeft => measurements['thigh_left'];
  double? get thighRight => measurements['thigh_right'];
  double? get calfLeft => measurements['calf_left'];
  double? get calfRight => measurements['calf_right'];
  double? get shoulders => measurements['shoulders'];
  double? get neck => measurements['neck'];

  @override
  List<Object?> get props => [date, measurements];

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'measurements': measurements,
  };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
    date: DateTime.parse(json['date']),
    measurements: Map<String, double>.from(json['measurements']),
  );
}

/// Progress photo
class ProgressPhoto extends Equatable {
  final String id;
  final DateTime date;
  final String imagePath;
  final String? notes;
  final double? weight;

  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.imagePath,
    this.notes,
    this.weight,
  });

  @override
  List<Object?> get props => [id, date, imagePath, notes, weight];
}

/// Personal Record for an exercise
class PersonalRecord extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  /// Calculate 1RM using Brzycki formula
  double get estimated1RM => weight * (36 / (37 - reps));

  @override
  List<Object?> get props => [exerciseId, weight, reps, date];

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'weight': weight,
    'reps': reps,
    'date': date.toIso8601String(),
  };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    weight: json['weight'].toDouble(),
    reps: json['reps'],
    date: DateTime.parse(json['date']),
  );
}

/// Complete user fitness profile
class UserFitnessProfile extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final DateTime? birthDate;
  final Gender gender;
  final double height; // cm
  
  // Current stats
  final double currentWeight; // kg
  final ExperienceLevel level;
  final FitnessGoal primaryGoal;
  
  // Targets
  final double? targetWeight;
  final DateTime? targetDate;
  
  // History
  final List<WeightEntry> weightHistory;
  final List<BodyMeasurement> measurementHistory;
  final List<ProgressPhoto> progressPhotos;
  final Map<String, PersonalRecord> personalRecords; // exerciseId -> PR
  
  // Stats
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;
  
  const UserFitnessProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.birthDate,
    required this.gender,
    required this.height,
    required this.currentWeight,
    required this.level,
    required this.primaryGoal,
    this.targetWeight,
    this.targetDate,
    this.weightHistory = const [],
    this.measurementHistory = const [],
    this.progressPhotos = const [],
    this.personalRecords = const {},
    this.totalWorkouts = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWorkoutDate,
  });

  /// Calculate age from birth date
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  /// Calculate BMI
  double get bmi => currentWeight / ((height / 100) * (height / 100));

  /// BMI category
  String get bmiCategory {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Weight change from start
  double? get weightChange {
    if (weightHistory.isEmpty) return null;
    return currentWeight - weightHistory.first.weight;
  }

  /// Days to target
  int? get daysToTarget {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  /// Copy with modifications
  UserFitnessProfile copyWith({
    String? id,
    String? name,
    String? photoUrl,
    DateTime? birthDate,
    Gender? gender,
    double? height,
    double? currentWeight,
    ExperienceLevel? level,
    FitnessGoal? primaryGoal,
    double? targetWeight,
    DateTime? targetDate,
    List<WeightEntry>? weightHistory,
    List<BodyMeasurement>? measurementHistory,
    List<ProgressPhoto>? progressPhotos,
    Map<String, PersonalRecord>? personalRecords,
    int? totalWorkouts,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
  }) {
    return UserFitnessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      level: level ?? this.level,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDate: targetDate ?? this.targetDate,
      weightHistory: weightHistory ?? this.weightHistory,
      measurementHistory: measurementHistory ?? this.measurementHistory,
      progressPhotos: progressPhotos ?? this.progressPhotos,
      personalRecords: personalRecords ?? this.personalRecords,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }

  @override
  List<Object?> get props => [
    id, name, gender, height, currentWeight, level, primaryGoal,
    weightHistory, measurementHistory, personalRecords, totalWorkouts, currentStreak,
  ];

}
