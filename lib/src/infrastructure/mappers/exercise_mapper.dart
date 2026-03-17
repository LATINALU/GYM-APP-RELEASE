import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/value_objects/value_objects.dart';

/// Mapper para convertir Exercise entre dominio y Firestore
class ExerciseMapper {
  const ExerciseMapper._();

  /// Convertir de Firestore a entidad de dominio
  static Exercise fromFirestore(Map<String, dynamic> data, String id) {
    return Exercise.restore(
      id: ExerciseId(id),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      instructions: data['instructions'] as String?,
      imageUrl: data['imageUrl'] as String?,
      animationUrl: data['animationUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      movementPattern: _movementPatternFromString(data['movementPattern'] as String? ?? 'isolation'),
      exerciseType: _exerciseTypeFromString(data['exerciseType'] as String? ?? 'compound'),
      equipment: (data['equipment'] as List<dynamic>?)
          ?.map((e) => _equipmentFromString(e as String))
          .toList() ?? [EquipmentType.bodyweight],
      difficulty: _difficultyFromString(data['difficulty'] as String? ?? 'beginner'),
      heatmap: MuscleHeatmap.fromMap(
        Map<String, dynamic>.from(data['heatmap'] as Map? ?? {}),
      ),
      recommendedRepRange: data['recommendedRepRange'] != null 
          ? _repRangeFromString(data['recommendedRepRange'] as String) 
          : null,
      estimatedCalories: data['estimatedCalories'] as int?,
      scope: _exerciseScopeFromString(data['scope'] as String? ?? 'global'),
      createdBy: data['createdBy'] != null ? UserId(data['createdBy'] as String) : null,
      gymId: data['gymId'] != null ? GymId(data['gymId'] as String) : null,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir de entidad de dominio a Firestore
  static Map<String, dynamic> toFirestore(Exercise exercise) {
    return {
      'name': exercise.name,
      'description': exercise.description,
      'instructions': exercise.instructions,
      'imageUrl': exercise.imageUrl,
      'animationUrl': exercise.animationUrl,
      'videoUrl': exercise.videoUrl,
      'movementPattern': exercise.movementPattern.name,
      'exerciseType': exercise.exerciseType.name,
      'equipment': exercise.equipment.map((e) => e.name).toList(),
      'difficulty': exercise.difficulty.name,
      'heatmap': exercise.heatmap.toMap(),
      'recommendedRepRange': exercise.recommendedRepRange?.name,
      'estimatedCalories': exercise.estimatedCalories,
      'scope': exercise.scope.name,
      'createdBy': exercise.createdBy?.value,
      'gymId': exercise.gymId?.value,
      'isActive': exercise.isActive,
      'createdAt': Timestamp.fromDate(exercise.createdAt),
      'updatedAt': exercise.updatedAt != null 
          ? Timestamp.fromDate(exercise.updatedAt!) 
          : null,
      // Campos para búsquedas indexadas
      'searchTerms': _generateSearchTerms(exercise),
    };
  }

  /// Generar términos de búsqueda para indexación
  static List<String> _generateSearchTerms(Exercise exercise) {
    final terms = <String>{};
    
    // Nombre en minúsculas (cada palabra)
    terms.addAll(exercise.name.toLowerCase().split(' '));
    
    // Patrón de movimiento
    terms.add(exercise.movementPattern.name.toLowerCase());
    
    // Tipo de ejercicio
    terms.add(exercise.exerciseType.name.toLowerCase());
    
    // Equipamiento
    for (final eq in exercise.equipment) {
      terms.add(eq.name.toLowerCase());
    }
    
    // Dificultad
    terms.add(exercise.difficulty.name.toLowerCase());
    
    return terms.toList();
  }

  static MovementPattern _movementPatternFromString(String value) {
    return MovementPattern.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MovementPattern.isolation,
    );
  }

  static ExerciseType _exerciseTypeFromString(String value) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.compound,
    );
  }

  static EquipmentType _equipmentFromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EquipmentType.bodyweight,
    );
  }

  static ExerciseDifficulty _difficultyFromString(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseDifficulty.beginner,
    );
  }

  static ExerciseScope _exerciseScopeFromString(String value) {
    return ExerciseScope.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseScope.global,
    );
  }

  static RepRangeType _repRangeFromString(String value) {
    return RepRangeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepRangeType.hypertrophy,
    );
  }
}
