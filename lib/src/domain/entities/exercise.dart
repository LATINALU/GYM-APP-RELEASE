import 'package:equatable/equatable.dart';
import '../value_objects/value_objects.dart';
import 'exercise_enums.dart';

// Re-export enums for convenience
export 'exercise_enums.dart';

/// Mapa de calor muscular - intensidad de activación por zona
class MuscleHeatmap extends Equatable {
  final Map<String, double> intensities;

  const MuscleHeatmap(this.intensities);

  factory MuscleHeatmap.empty() => const MuscleHeatmap({});

  factory MuscleHeatmap.fromMap(Map<String, dynamic> map) {
    final intensities = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    return MuscleHeatmap(intensities);
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(intensities);

  /// Obtener intensidad de un músculo específico (0.0 a 1.0)
  double getIntensity(String muscle) => intensities[muscle] ?? 0.0;

  /// Músculos primarios (intensidad >= 0.7)
  List<String> get primaryMuscles =>
      intensities.entries.where((e) => e.value >= 0.7).map((e) => e.key).toList();

  /// Músculos secundarios (intensidad entre 0.3 y 0.7)
  List<String> get secondaryMuscles =>
      intensities.entries.where((e) => e.value >= 0.3 && e.value < 0.7).map((e) => e.key).toList();

  @override
  List<Object?> get props => [intensities];
}

/// Entidad Exercise enriquecida con soporte visual
class Exercise extends Equatable {
  final ExerciseId id;
  final String name;
  final String description;
  final String? instructions;
  
  // Visual Assets
  final String? imageUrl;
  final String? animationUrl;
  final String? videoUrl;
  
  // Clasificación (usando enums de exercise_enums.dart)
  final MovementPattern movementPattern;
  final ExerciseType exerciseType;
  final List<EquipmentType> equipment;
  final ExerciseDifficulty difficulty;
  final MuscleHeatmap heatmap;
  
  // Training Parameters
  final RepRangeType? recommendedRepRange;
  final int? estimatedCalories;
  
  // Scope & Ownership
  final ExerciseScope scope;
  final UserId? createdBy;
  final GymId? gymId;
  
  // Metadata
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Exercise._({
    required this.id,
    required this.name,
    required this.description,
    this.instructions,
    this.imageUrl,
    this.animationUrl,
    this.videoUrl,
    required this.movementPattern,
    required this.exerciseType,
    required this.equipment,
    required this.difficulty,
    required this.heatmap,
    this.recommendedRepRange,
    this.estimatedCalories,
    this.scope = ExerciseScope.global,
    this.createdBy,
    this.gymId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 60,
    this.notes,
  });

  // Routine Context Fields (Technical Debt: Should be in WorkoutExercise)
  final int sets;
  final int reps;
  final int? restSeconds;
  final String? notes;

  /// Factory para crear nuevo ejercicio
  factory Exercise.create({
    required String name,
    required String description,
    String? instructions,
    String? imageUrl,
    String? animationUrl,
    String? videoUrl,
    required MovementPattern movementPattern,
    ExerciseType exerciseType = ExerciseType.compound,
    List<EquipmentType> equipment = const [EquipmentType.bodyweight],
    ExerciseDifficulty difficulty = ExerciseDifficulty.beginner,
    MuscleHeatmap? heatmap,
    RepRangeType? recommendedRepRange,
    int? estimatedCalories,
    ExerciseScope scope = ExerciseScope.global,
    UserId? createdBy,
    GymId? gymId,
  }) {
    return Exercise._(
      id: ExerciseId.generate(),
      name: name,
      description: description,
      instructions: instructions,
      imageUrl: imageUrl,
      animationUrl: animationUrl,
      videoUrl: videoUrl,
      movementPattern: movementPattern,
      exerciseType: exerciseType,
      equipment: equipment,
      difficulty: difficulty,
      heatmap: heatmap ?? MuscleHeatmap.empty(),
      recommendedRepRange: recommendedRepRange,
      estimatedCalories: estimatedCalories,
      scope: scope,
      createdBy: createdBy,
      gymId: gymId,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Factory para crear ejercicio desde plantilla (para rutinas)
  factory Exercise.createFromTemplate({
    required ExerciseTemplate template,
    int sets = 3,
    int reps = 10,
    int? restSeconds = 60,
    String? notes,
  }) {
    return Exercise._(
      id: ExerciseId.generate(),
      name: template.spanishName.isNotEmpty ? template.spanishName : template.name,
      description: template.description,
      instructions: template.tips.isNotEmpty ? template.tips.join('\n') : null,
      imageUrl: template.imageUrl,
      animationUrl: template.gifUrl,
      videoUrl: null,
      movementPattern: template.movementPattern,
      exerciseType: template.exerciseType,
      equipment: template.equipment,
      difficulty: template.difficulty,
      heatmap: MuscleHeatmap({
        for (final m in template.secondaryMuscles) m.name: 0.5,
        template.primaryMuscle.name: 0.9,
      }),
      recommendedRepRange: template.recommendedRepRanges?.first,
      estimatedCalories: null,
      isActive: true,
      createdAt: DateTime.now(),
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  /// Factory para restaurar desde persistencia
  factory Exercise.restore({
    required ExerciseId id,
    required String name,
    required String description,
    String? instructions,
    String? imageUrl,
    String? animationUrl,
    String? videoUrl,
    required MovementPattern movementPattern,
    required ExerciseType exerciseType,
    required List<EquipmentType> equipment,
    required ExerciseDifficulty difficulty,
    required MuscleHeatmap heatmap,
    RepRangeType? recommendedRepRange,
    int? estimatedCalories,
    ExerciseScope scope = ExerciseScope.global,
    UserId? createdBy,
    GymId? gymId,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    int sets = 3,
    int reps = 10,
    int? restSeconds = 60,
    String? notes,
  }) {
    return Exercise._(
      id: id,
      name: name,
      description: description,
      instructions: instructions,
      imageUrl: imageUrl,
      animationUrl: animationUrl,
      videoUrl: videoUrl,
      movementPattern: movementPattern,
      exerciseType: exerciseType,
      equipment: equipment,
      difficulty: difficulty,
      heatmap: heatmap,
      recommendedRepRange: recommendedRepRange,
      estimatedCalories: estimatedCalories,
      scope: scope,
      createdBy: createdBy,
      gymId: gymId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  /// Actualizar assets visuales
  Exercise updateMedia({
    String? imageUrl,
    String? animationUrl,
    String? videoUrl,
  }) {
    return Exercise._(
      id: id,
      name: name,
      description: description,
      instructions: instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      movementPattern: movementPattern,
      exerciseType: exerciseType,
      equipment: equipment,
      difficulty: difficulty,
      heatmap: heatmap,
      recommendedRepRange: recommendedRepRange,
      estimatedCalories: estimatedCalories,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Verificar si tiene contenido visual
  bool get hasVisualContent => imageUrl != null || animationUrl != null || videoUrl != null;

  /// Es ejercicio global (creado por Admin, visible para todos los gyms)
  bool get isGlobal => scope == ExerciseScope.global;

  /// Es ejercicio personalizado de un gym específico
  bool get isGymSpecific => scope == ExerciseScope.gym;

  /// Primary muscle (computed from heatmap or fallback)
  MuscleGroup get primaryMuscle {
    final primaryList = heatmap.primaryMuscles;
    if (primaryList.isNotEmpty) {
      return MuscleGroup.values.firstWhere(
        (m) => m.name == primaryList.first,
        orElse: () => MuscleGroup.fullBody,
      );
    }
    return MuscleGroup.fullBody;
  }

  /// Secondary muscles (computed from heatmap)
  List<MuscleGroup> get secondaryMuscles {
    return heatmap.secondaryMuscles
        .map((name) => MuscleGroup.values.firstWhere(
              (m) => m.name == name,
              orElse: () => MuscleGroup.fullBody,
            ))
        .toList();
  }

  /// All targeted muscles
  Set<MuscleGroup> get allMuscles => {primaryMuscle, ...secondaryMuscles};

  /// Display string for sets x reps
  String get setsRepsDisplay => '$sets x $reps';

  /// Display string for rest period
  String get restDisplay => restSeconds != null ? '$restSeconds seg' : '-';

  @override
  List<Object?> get props => [id, name, movementPattern, isActive];
}

/// MuscleGroup Enum - Grupos musculares
enum MuscleGroup {
  chest,
  back,
  shoulders,
  frontDelts,
  sideDelts,
  rearDelts,
  biceps,
  triceps,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  abs,
  lowerBack,
  traps,
  lats,
  upperBack,
  rhomboids,
  forearms,
  adductors,
  abductors,
  obliques,
  hipFlexors,
  cardio,
  fullBody,
}

extension MuscleGroupX on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest: return 'Pectorales';
      case MuscleGroup.back: return 'Espalda';
      case MuscleGroup.shoulders: return 'Hombros';
      case MuscleGroup.frontDelts: return 'Deltoides Anterior';
      case MuscleGroup.sideDelts: return 'Deltoides Lateral';
      case MuscleGroup.rearDelts: return 'Deltoides Posterior';
      case MuscleGroup.biceps: return 'Bíceps';
      case MuscleGroup.triceps: return 'Tríceps';
      case MuscleGroup.quadriceps: return 'Cuádriceps';
      case MuscleGroup.hamstrings: return 'Isquiotibiales';
      case MuscleGroup.glutes: return 'Glúteos';
      case MuscleGroup.calves: return 'Pantorrillas';
      case MuscleGroup.abs: return 'Abdominales';
      case MuscleGroup.lowerBack: return 'Lumbar';
      case MuscleGroup.traps: return 'Trapecios';
      case MuscleGroup.lats: return 'Dorsales';
      case MuscleGroup.upperBack: return 'Espalda Alta';
      case MuscleGroup.rhomboids: return 'Romboides';
      case MuscleGroup.forearms: return 'Antebrazos';
      case MuscleGroup.adductors: return 'Aductores';
      case MuscleGroup.abductors: return 'Abductores';
      case MuscleGroup.obliques: return 'Oblicuos';
      case MuscleGroup.hipFlexors: return 'Flexores de Cadera';
      case MuscleGroup.cardio: return 'Cardio';
      case MuscleGroup.fullBody: return 'Cuerpo Completo';
    }
  }
}

/// Plantilla para semilla de ejercicios (Legacy/Static Data)
class ExerciseTemplate extends Equatable {
  final String id;
  final String name;
  final String spanishName;
  final String description;
  final MovementPattern movementPattern;
  final ExerciseType exerciseType;
  final ExerciseDifficulty difficulty;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final List<EquipmentType> equipment;
  final List<RepRangeType>? recommendedRepRanges;
  final bool requiresSpotter;
  final List<String> tips;
  final List<String> variants;
  final bool isUnilateral;

  // Visual assets (dataset): GIF remoto y thumbnail empaquetado en assets
  final String? gifUrl;
  final String? imageUrl;
  final String? thumbAsset;

  const ExerciseTemplate({
    required this.id,
    required this.name,
    required this.spanishName,
    required this.description,
    required this.movementPattern,
    required this.exerciseType,
    required this.difficulty,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.recommendedRepRanges,
    this.requiresSpotter = false,
    this.tips = const [],
    this.variants = const [],
    this.isUnilateral = false,
    this.gifUrl,
    this.imageUrl,
    this.thumbAsset,
  });

  /// Get display name (Spanish if available, otherwise English)
  String get displayName => spanishName.isNotEmpty ? spanishName : name;

  /// Check if this is a compound movement (multiple muscle groups)
  bool get isCompound => exerciseType == ExerciseType.compound;

  @override
  List<Object?> get props => [id, name, spanishName, primaryMuscle];
}
