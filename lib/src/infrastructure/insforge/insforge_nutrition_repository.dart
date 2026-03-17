import '../../domain/entities/nutrition_plan.dart';
import '../../domain/ports/output/nutrition_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of NutritionRepositoryPort
class InsForgeNutritionRepository implements NutritionRepositoryPort {
  final InsForgeClient _client;

  InsForgeNutritionRepository(this._client);

  @override
  Future<void> savePlan(NutritionPlan plan) async {
    try {
      await _client.insert('nutrition_plans', {
        'id': plan.id,
        'user_id': plan.userId,
        'name': plan.name,
        'description': plan.description,
        'daily_calories': plan.targetCalories,
        'protein_grams': plan.targetProteinG,
        'carbs_grams': plan.targetCarbsG,
        'fat_grams': plan.targetFatG,
        'meals': plan.meals.map((m) => m.toMap()).toList(),
        'is_active': plan.isActive,
      });
    } catch (_) {}
  }

  @override
  Future<NutritionPlan?> getActivePlan(String userId) async {
    try {
      final response = await _client.from('nutrition_plans',
          query: 'user_id=eq.$userId&is_active=eq.true&select=*&order=created_at.desc&limit=1');
      if (!response.isSuccess || response.dataList.isEmpty) return null;
      return _mapPlan(response.firstItem!);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NutritionPlan>> getAllPlans(String userId) async {
    try {
      final response = await _client.from('nutrition_plans',
          query: 'user_id=eq.$userId&select=*&order=created_at.desc');
      if (!response.isSuccess) return [];
      return response.dataList.map((e) => _mapPlan(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      await _client.delete('nutrition_plans', 'id=eq.$planId');
    } catch (_) {}
  }

  @override
  Future<void> logMeal(String planId, Meal meal) async {
    // Meals are stored as JSONB within the plan; update the plan's meals array
    // For a more robust solution, a separate meal_logs table would be better
  }

  @override
  Future<List<Meal>> getMealsByDate(String userId, DateTime date) async {
    // Would require a separate meal_logs table for proper date-based querying
    return [];
  }

  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    // Would connect to a food database API or local food_items table
    return [];
  }

  NutritionPlan _mapPlan(Map<String, dynamic> data) {
    final mealsData = data['meals'] as List? ?? [];
    final meals = mealsData.map<Meal>((m) {
      final mMap = m as Map<String, dynamic>;
      return Meal.fromMap(mMap);
    }).toList();

    return NutritionPlan.restore(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      targetCalories: (data['daily_calories'] as num?)?.toDouble() ?? 2000.0,
      targetProteinG: (data['protein_grams'] as num?)?.toDouble() ?? 0.0,
      targetCarbsG: (data['carbs_grams'] as num?)?.toDouble() ?? 0.0,
      targetFatG: (data['fat_grams'] as num?)?.toDouble() ?? 0.0,
      meals: meals,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      isActive: data['is_active'] as bool? ?? true,
    );
  }
}
