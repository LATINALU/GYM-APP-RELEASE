/// Muscle Volume Tracker - GYM-APP
/// Tracks training volume (sets × reps × weight) per muscle group
/// for progressive overload and balanced development
class MuscleVolumeRecord {
  final String id;
  final String userId;
  final DateTime weekStart;
  final Map<MuscleGroup, MuscleVolumeData> volumes;

  MuscleVolumeRecord._({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.volumes,
  });

  factory MuscleVolumeRecord.create({
    required String userId,
    required DateTime weekStart,
  }) {
    return MuscleVolumeRecord._(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      weekStart: weekStart,
      volumes: {},
    );
  }

  factory MuscleVolumeRecord.restore(Map<String, dynamic> map) {
    final volumesRaw = map['volumes'] as Map<String, dynamic>? ?? {};
    final volumes = <MuscleGroup, MuscleVolumeData>{};
    volumesRaw.forEach((key, value) {
      final group = MuscleGroup.values.firstWhere(
        (e) => e.name == key,
        orElse: () => MuscleGroup.other,
      );
      volumes[group] = MuscleVolumeData.fromMap(value as Map<String, dynamic>);
    });

    return MuscleVolumeRecord._(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      weekStart: DateTime.tryParse(map['weekStart'] ?? '') ?? DateTime.now(),
      volumes: volumes,
    );
  }

  MuscleVolumeRecord addSet({
    required MuscleGroup muscle,
    required int reps,
    required double weightKg,
  }) {
    final updated = Map<MuscleGroup, MuscleVolumeData>.from(volumes);
    final existing = updated[muscle] ?? MuscleVolumeData.empty();
    updated[muscle] = existing.addSet(reps: reps, weightKg: weightKg);
    return MuscleVolumeRecord._(
      id: id,
      userId: userId,
      weekStart: weekStart,
      volumes: updated,
    );
  }

  /// Total volume across all muscles (kg)
  double get totalVolume =>
      volumes.values.fold(0, (sum, v) => sum + v.totalVolume);

  /// Total sets across all muscles
  int get totalSets =>
      volumes.values.fold(0, (sum, v) => sum + v.totalSets);

  /// Identify weakest muscle groups
  List<MuscleGroup> get undertrained {
    if (volumes.isEmpty) return [];
    final avgVolume = totalVolume / volumes.length;
    return volumes.entries
        .where((e) => e.value.totalVolume < avgVolume * 0.5)
        .map((e) => e.key)
        .toList();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'weekStart': weekStart.toIso8601String(),
    'volumes': volumes.map((k, v) => MapEntry(k.name, v.toMap())),
  };
}

class MuscleVolumeData {
  final int totalSets;
  final int totalReps;
  final double totalVolume; // sets × reps × weight
  final double maxWeight;
  final List<SetRecord> sets;

  MuscleVolumeData._({
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    required this.maxWeight,
    required this.sets,
  });

  factory MuscleVolumeData.empty() => MuscleVolumeData._(
    totalSets: 0,
    totalReps: 0,
    totalVolume: 0,
    maxWeight: 0,
    sets: [],
  );

  factory MuscleVolumeData.fromMap(Map<String, dynamic> map) {
    return MuscleVolumeData._(
      totalSets: map['totalSets'] ?? 0,
      totalReps: map['totalReps'] ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0,
      maxWeight: (map['maxWeight'] as num?)?.toDouble() ?? 0,
      sets: (map['sets'] as List<dynamic>?)
          ?.map((s) => SetRecord.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  MuscleVolumeData addSet({required int reps, required double weightKg}) {
    final newSet = SetRecord(reps: reps, weightKg: weightKg, timestamp: DateTime.now());
    final setVolume = reps * weightKg;
    return MuscleVolumeData._(
      totalSets: totalSets + 1,
      totalReps: totalReps + reps,
      totalVolume: totalVolume + setVolume,
      maxWeight: weightKg > maxWeight ? weightKg : maxWeight,
      sets: [...sets, newSet],
    );
  }

  double get averageWeight => totalSets > 0 ? totalVolume / totalReps : 0;

  Map<String, dynamic> toMap() => {
    'totalSets': totalSets,
    'totalReps': totalReps,
    'totalVolume': totalVolume,
    'maxWeight': maxWeight,
    'sets': sets.map((s) => s.toMap()).toList(),
  };
}

class SetRecord {
  final int reps;
  final double weightKg;
  final DateTime timestamp;

  SetRecord({required this.reps, required this.weightKg, required this.timestamp});

  factory SetRecord.fromMap(Map<String, dynamic> map) => SetRecord(
    reps: map['reps'] ?? 0,
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
    timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
  );

  double get volume => reps * weightKg;

  Map<String, dynamic> toMap() => {
    'reps': reps,
    'weightKg': weightKg,
    'timestamp': timestamp.toIso8601String(),
  };
}

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,
  traps,
  lats,
  other;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest: return 'Pecho';
      case MuscleGroup.back: return 'Espalda';
      case MuscleGroup.shoulders: return 'Hombros';
      case MuscleGroup.biceps: return 'Bíceps';
      case MuscleGroup.triceps: return 'Tríceps';
      case MuscleGroup.forearms: return 'Antebrazos';
      case MuscleGroup.quads: return 'Cuádriceps';
      case MuscleGroup.hamstrings: return 'Isquiotibiales';
      case MuscleGroup.glutes: return 'Glúteos';
      case MuscleGroup.calves: return 'Pantorrillas';
      case MuscleGroup.abs: return 'Abdominales';
      case MuscleGroup.traps: return 'Trapecios';
      case MuscleGroup.lats: return 'Dorsales';
      case MuscleGroup.other: return 'Otro';
    }
  }

  /// Color associated with this muscle for UI display
  String get colorHex {
    switch (this) {
      case MuscleGroup.chest: return '#FF6B6B';
      case MuscleGroup.back: return '#4ECDC4';
      case MuscleGroup.shoulders: return '#FFE66D';
      case MuscleGroup.biceps: return '#95E1D3';
      case MuscleGroup.triceps: return '#F38181';
      case MuscleGroup.forearms: return '#AA96DA';
      case MuscleGroup.quads: return '#FCBAD3';
      case MuscleGroup.hamstrings: return '#A8D8EA';
      case MuscleGroup.glutes: return '#FFB6C1';
      case MuscleGroup.calves: return '#B5EAD7';
      case MuscleGroup.abs: return '#C7CEEA';
      case MuscleGroup.traps: return '#E2F0CB';
      case MuscleGroup.lats: return '#FFDAC1';
      case MuscleGroup.other: return '#B5B5B5';
    }
  }
}
