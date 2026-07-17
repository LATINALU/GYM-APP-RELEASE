/// Exercise Library - Complete exercise database
import 'package:equatable/equatable.dart';

import '../data/dataset_exercise_catalog.dart';
import 'exercise.dart' as core;

/// Muscle group enum
enum MuscleGroup {
  chest('Pecho', '🫁'),
  back('Espalda', '🔙'),
  shoulders('Hombros', '🦾'),
  biceps('Bíceps', '💪'),
  triceps('Tríceps', '🦵'),
  quadriceps('Cuádriceps', '🦿'),
  hamstrings('Isquiotibiales', '🦵'),
  glutes('Glúteos', '🍑'),
  calves('Gemelos', '🦶'),
  abs('Abdominales', '🎯'),
  forearms('Antebrazos', '✊'),
  traps('Trapecios', '🔺'),
  cardio('Cardio', '🏃');

  final String displayName;
  final String icon;
  const MuscleGroup(this.displayName, this.icon);
}

/// Equipment type
enum Equipment {
  barbell('Barra', '🏋️'),
  dumbbell('Mancuernas', '💪'),
  machine('Máquina', '⚙️'),
  cable('Polea/Cable', '🔗'),
  bodyweight('Peso Corporal', '🧍'),
  kettlebell('Kettlebell', '🔔'),
  resistanceBand('Banda Elástica', '〰️'),
  other('Otro', '📦');

  final String displayName;
  final String icon;
  const Equipment(this.displayName, this.icon);
}

/// Exercise difficulty
enum ExerciseDifficulty {
  beginner('Principiante', 1),
  intermediate('Intermedio', 2),
  advanced('Avanzado', 3);

  final String displayName;
  final int level;
  const ExerciseDifficulty(this.displayName, this.level);
}

/// Movement pattern
enum MovementPattern {
  push('Empuje'),
  pull('Tirón'),
  squat('Sentadilla'),
  hinge('Bisagra'),
  lunge('Zancada'),
  rotation('Rotación'),
  carry('Acarreo'),
  isolation('Aislamiento');

  final String displayName;
  const MovementPattern(this.displayName);
}

/// Complete exercise definition
class GymExercise extends Equatable {
  final String id;
  final String name;
  final String description;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final ExerciseDifficulty difficulty;
  final MovementPattern pattern;
  
  // Instructions
  final List<String> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  
  // Media
  final String? imageUrl;
  final String? videoUrl;
  final String? gifUrl;
  
  // Metadata
  final bool isCompound;
  final bool requiresSpotter;
  final List<String> variations;
  final List<String> alternatives;

  const GymExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.difficulty,
    required this.pattern,
    this.instructions = const [],
    this.tips = const [],
    this.commonMistakes = const [],
    this.imageUrl,
    this.videoUrl,
    this.gifUrl,
    this.isCompound = false,
    this.requiresSpotter = false,
    this.variations = const [],
    this.alternatives = const [],
  });

  /// All muscles worked
  List<MuscleGroup> get allMuscles => [primaryMuscle, ...secondaryMuscles];

  /// Formatted instruction steps
  String get formattedInstructions => instructions.asMap().entries
      .map((e) => '${e.key + 1}. ${e.value}')
      .join('\n');

  @override
  List<Object?> get props => [id, name, primaryMuscle, equipment];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'primaryMuscle': primaryMuscle.name,
    'secondaryMuscles': secondaryMuscles.map((m) => m.name).toList(),
    'equipment': equipment.name,
    'difficulty': difficulty.name,
    'pattern': pattern.name,
    'instructions': instructions,
    'tips': tips,
    'commonMistakes': commonMistakes,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'gifUrl': gifUrl,
    'isCompound': isCompound,
    'requiresSpotter': requiresSpotter,
    'variations': variations,
    'alternatives': alternatives,
  };

  factory GymExercise.fromJson(Map<String, dynamic> json) => GymExercise(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    primaryMuscle: MuscleGroup.values.firstWhere((m) => m.name == json['primaryMuscle']),
    secondaryMuscles: (json['secondaryMuscles'] as List?)?.map((m) => MuscleGroup.values.firstWhere((mg) => mg.name == m)).toList() ?? [],
    equipment: Equipment.values.firstWhere((e) => e.name == json['equipment']),
    difficulty: ExerciseDifficulty.values.firstWhere((d) => d.name == json['difficulty']),
    pattern: MovementPattern.values.firstWhere((p) => p.name == json['pattern']),
    instructions: List<String>.from(json['instructions'] ?? []),
    tips: List<String>.from(json['tips'] ?? []),
    commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
    imageUrl: json['imageUrl'],
    videoUrl: json['videoUrl'],
    gifUrl: json['gifUrl'],
    isCompound: json['isCompound'] ?? false,
    requiresSpotter: json['requiresSpotter'] ?? false,
    variations: List<String>.from(json['variations'] ?? []),
    alternatives: List<String>.from(json['alternatives'] ?? []),
  );
}

/// Exercise Library Service
///
/// Fachada sobre el dataset (1,324 ejercicios, diseño uniforme de
/// Gym visual). El catálogo estático anterior fue eliminado tras la purga
/// de rutinas antiguas (migración jul-2026).
class ExerciseLibrary {
  static List<GymExercise>? _datasetCache;
  static int _datasetVersion = -1;

  static List<GymExercise> get _exercises {
    if (!DatasetExerciseCatalog.isLoaded) return const [];
    if (_datasetCache == null ||
        _datasetVersion != DatasetExerciseCatalog.version) {
      _datasetCache = DatasetExerciseCatalog.exercises
          .map(_fromTemplate)
          .toList(growable: false);
      _datasetVersion = DatasetExerciseCatalog.version;
    }
    return _datasetCache!;
  }

  /// Convertir plantilla del dataset a GymExercise
  static GymExercise _fromTemplate(core.ExerciseTemplate t) {
    return GymExercise(
      id: t.id,
      name: t.name,
      description: t.description,
      primaryMuscle: _muscleFromCore(t.primaryMuscle),
      secondaryMuscles: t.secondaryMuscles
          .map(_muscleFromCore)
          .toSet()
          .toList(growable: false),
      equipment: _equipmentFromCore(
          t.equipment.isNotEmpty ? t.equipment.first : core.EquipmentType.bodyweight),
      difficulty: _difficultyFromCore(t.difficulty),
      pattern: _patternFromCore(t.movementPattern),
      instructions: t.tips,
      imageUrl: t.imageUrl,
      gifUrl: t.gifUrl,
      isCompound: t.exerciseType == core.ExerciseType.compound,
      requiresSpotter: t.requiresSpotter,
    );
  }

  static MuscleGroup _muscleFromCore(core.MuscleGroup m) {
    switch (m) {
      case core.MuscleGroup.chest: return MuscleGroup.chest;
      case core.MuscleGroup.back:
      case core.MuscleGroup.lats:
      case core.MuscleGroup.upperBack:
      case core.MuscleGroup.rhomboids:
      case core.MuscleGroup.lowerBack: return MuscleGroup.back;
      case core.MuscleGroup.shoulders:
      case core.MuscleGroup.frontDelts:
      case core.MuscleGroup.sideDelts:
      case core.MuscleGroup.rearDelts: return MuscleGroup.shoulders;
      case core.MuscleGroup.biceps: return MuscleGroup.biceps;
      case core.MuscleGroup.triceps: return MuscleGroup.triceps;
      case core.MuscleGroup.quadriceps: return MuscleGroup.quadriceps;
      case core.MuscleGroup.hamstrings: return MuscleGroup.hamstrings;
      case core.MuscleGroup.glutes:
      case core.MuscleGroup.adductors:
      case core.MuscleGroup.abductors: return MuscleGroup.glutes;
      case core.MuscleGroup.calves: return MuscleGroup.calves;
      case core.MuscleGroup.abs:
      case core.MuscleGroup.obliques:
      case core.MuscleGroup.hipFlexors: return MuscleGroup.abs;
      case core.MuscleGroup.forearms: return MuscleGroup.forearms;
      case core.MuscleGroup.traps: return MuscleGroup.traps;
      case core.MuscleGroup.cardio:
      case core.MuscleGroup.fullBody: return MuscleGroup.cardio;
    }
  }

  static Equipment _equipmentFromCore(core.EquipmentType e) {
    switch (e) {
      case core.EquipmentType.barbell:
      case core.EquipmentType.trapBar:
      case core.EquipmentType.ezBar:
      case core.EquipmentType.specialtyBar: return Equipment.barbell;
      case core.EquipmentType.dumbbell: return Equipment.dumbbell;
      case core.EquipmentType.kettlebell: return Equipment.kettlebell;
      case core.EquipmentType.cable: return Equipment.cable;
      case core.EquipmentType.machine:
      case core.EquipmentType.smithMachine: return Equipment.machine;
      case core.EquipmentType.bodyweight:
      case core.EquipmentType.pullupBar: return Equipment.bodyweight;
      case core.EquipmentType.resistanceBand: return Equipment.resistanceBand;
      case core.EquipmentType.medicineBall:
      case core.EquipmentType.bench:
      case core.EquipmentType.box: return Equipment.other;
    }
  }

  static ExerciseDifficulty _difficultyFromCore(core.ExerciseDifficulty d) {
    switch (d) {
      case core.ExerciseDifficulty.beginner: return ExerciseDifficulty.beginner;
      case core.ExerciseDifficulty.intermediate: return ExerciseDifficulty.intermediate;
      case core.ExerciseDifficulty.advanced:
      case core.ExerciseDifficulty.expert: return ExerciseDifficulty.advanced;
    }
  }

  static MovementPattern _patternFromCore(core.MovementPattern p) {
    switch (p) {
      case core.MovementPattern.verticalPush:
      case core.MovementPattern.horizontalPush: return MovementPattern.push;
      case core.MovementPattern.verticalPull:
      case core.MovementPattern.horizontalPull: return MovementPattern.pull;
      case core.MovementPattern.squat: return MovementPattern.squat;
      case core.MovementPattern.hipHinge:
      case core.MovementPattern.hipExtension: return MovementPattern.hinge;
      case core.MovementPattern.lunge: return MovementPattern.lunge;
      case core.MovementPattern.coreRotation: return MovementPattern.rotation;
      case core.MovementPattern.carry: return MovementPattern.carry;
      default: return MovementPattern.isolation;
    }
  }


  /// Get all exercises
  static List<GymExercise> get all => _exercises;

  /// Get exercise by ID
  static GymExercise? getById(String id) {
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Get exercises by muscle group
  static List<GymExercise> getByMuscle(MuscleGroup muscle) {
    return _exercises.where((e) => e.primaryMuscle == muscle || e.secondaryMuscles.contains(muscle)).toList();
  }

  /// Get exercises by equipment
  static List<GymExercise> getByEquipment(Equipment equipment) {
    return _exercises.where((e) => e.equipment == equipment).toList();
  }

  /// Get exercises by difficulty
  static List<GymExercise> getByDifficulty(ExerciseDifficulty difficulty) {
    return _exercises.where((e) => e.difficulty == difficulty).toList();
  }

  /// Get compound exercises only
  static List<GymExercise> get compoundOnly {
    return _exercises.where((e) => e.isCompound).toList();
  }

  /// Search exercises by name
  static List<GymExercise> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _exercises.where((e) => 
      e.name.toLowerCase().contains(lowerQuery) ||
      e.primaryMuscle.displayName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get exercise count
  static int get count => _exercises.length;
}
