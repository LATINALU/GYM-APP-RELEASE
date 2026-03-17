import 'package:gym_app/src/domain/entities/nutrition_plan.dart';

class NutritionMapper {
  static Map<String, dynamic> toFirestore(NutritionPlan plan) {
    return plan.toMap();
  }

  static NutritionPlan fromFirestore(Map<String, dynamic> map, String id) {
    // Ensuring ID consistency
    final updatedMap = Map<String, dynamic>.from(map);
    updatedMap['id'] = id;
    return NutritionPlan.restore(
      id: id,
      userId: updatedMap['userId'] ?? '',
      name: updatedMap['name'] ?? '',
      description: updatedMap['description'],
      targetCalories: (updatedMap['targetCalories'] as num).toDouble(),
      targetProteinG: (updatedMap['targetProteinG'] as num).toDouble(),
      targetCarbsG: (updatedMap['targetCarbsG'] as num).toDouble(),
      targetFatG: (updatedMap['targetFatG'] as num).toDouble(),
      meals: (updatedMap['meals'] as List?)
          ?.map((m) => Meal.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(updatedMap['createdAt'] ?? '') ?? DateTime.now(),
      isActive: updatedMap['isActive'] ?? false,
    );
  }
}
