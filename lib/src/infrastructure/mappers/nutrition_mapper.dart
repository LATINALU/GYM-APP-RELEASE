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

  /// Columnas snake_case de `public.nutrition_plans` (Fase 1 de la
  /// migración a Supabase, ver 0004_nutrition_plans.sql). gym_id se omite:
  /// el dominio nunca lo puebla hoy (ver advertencia en la migración).
  static Map<String, dynamic> toSupabase(NutritionPlan plan) {
    final map = plan.toMap();
    return {
      'id': map['id'],
      'user_id': map['userId'],
      'name': map['name'],
      'description': map['description'],
      'target_calories': map['targetCalories'],
      'target_protein_g': map['targetProteinG'],
      'target_carbs_g': map['targetCarbsG'],
      'target_fat_g': map['targetFatG'],
      'meals': map['meals'],
      'is_active': map['isActive'],
    };
  }

  static NutritionPlan fromSupabase(Map<String, dynamic> row) {
    return NutritionPlan.restore(
      id: row['id'] ?? '',
      userId: row['user_id'] ?? '',
      name: row['name'] ?? '',
      description: row['description'],
      targetCalories: (row['target_calories'] as num?)?.toDouble() ?? 0,
      targetProteinG: (row['target_protein_g'] as num?)?.toDouble() ?? 0,
      targetCarbsG: (row['target_carbs_g'] as num?)?.toDouble() ?? 0,
      targetFatG: (row['target_fat_g'] as num?)?.toDouble() ?? 0,
      meals: (row['meals'] as List?)
              ?.map((m) => Meal.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
      isActive: row['is_active'] ?? false,
    );
  }
}

/// Columnas snake_case de `public.food_database` (Fase 1 de la migración
/// a Supabase, ver 0005_food_database.sql).
class FoodDatabaseMapper {
  static Map<String, dynamic> toSupabase(FoodItem item) => {
    'id': item.id,
    'name': item.name,
    'serving_size': item.servingSize,
    'serving_unit': item.servingUnit,
    'calories': item.calories,
    'protein_g': item.proteinG,
    'carbs_g': item.carbsG,
    'fat_g': item.fatG,
    'fiber_g': item.fiberG,
    'sugar_g': item.sugarG,
    'sodium_mg': item.sodiumMg,
  };

  static FoodItem fromSupabase(Map<String, dynamic> row) => FoodItem(
    id: row['id'] ?? '',
    name: row['name'] ?? '',
    servingSize: (row['serving_size'] as num?)?.toDouble() ?? 100,
    servingUnit: row['serving_unit'] ?? 'g',
    calories: (row['calories'] as num?)?.toDouble() ?? 0,
    proteinG: (row['protein_g'] as num?)?.toDouble() ?? 0,
    carbsG: (row['carbs_g'] as num?)?.toDouble() ?? 0,
    fatG: (row['fat_g'] as num?)?.toDouble() ?? 0,
    fiberG: (row['fiber_g'] as num?)?.toDouble(),
    sugarG: (row['sugar_g'] as num?)?.toDouble(),
    sodiumMg: (row['sodium_mg'] as num?)?.toDouble(),
  );
}
