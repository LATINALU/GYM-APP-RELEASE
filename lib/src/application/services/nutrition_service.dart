import '../../domain/entities/nutrition_plan.dart';
import '../../domain/ports/output/nutrition_repository_port.dart';

/// Application Service for Nutrition tracking
/// Inspired by wger-project's nutritional plan management
class NutritionService {
  final NutritionRepositoryPort _repo;

  NutritionService(this._repo);

  /// Get or create today's active nutrition plan for user
  Future<NutritionPlan> getActivePlan(String userId) async {
    try {
      final plan = await _repo.getActivePlan(userId);
      if (plan != null) return plan;

      // Create default plan
      final defaultPlan = NutritionPlan.create(
        userId: userId,
        name: 'Mi Plan Nutricional',
        targetCalories: 2200,
        targetProteinG: 150,
        targetCarbsG: 250,
        targetFatG: 70,
      );
      await _repo.savePlan(defaultPlan);
      return defaultPlan;
    } catch (e) {
      return _emptyPlan(userId);
    }
  }

  /// Log a meal to the active plan
  Future<void> logMeal(String planId, Meal meal) async {
    await _repo.logMeal(planId, meal);
  }

  /// Search food database
  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      return await _repo.searchFoods(query);
    } catch (e) {
      return const [];
    }
  }

  /// Get daily macro summary
  Future<Map<String, double>> getDailySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final plan = await getActivePlan(userId);
      return {
        'calories': plan.totalCalories,
        'protein': plan.totalProtein,
        'carbs': plan.totalCarbs,
        'fat': plan.totalFat,
        'targetCalories': plan.targetCalories,
        'targetProtein': plan.targetProteinG,
        'targetCarbs': plan.targetCarbsG,
        'targetFat': plan.targetFatG,
      };
    } catch (e) {
      return _emptyDailySummary();
    }
  }

  NutritionPlan _emptyPlan(String userId) {
    return NutritionPlan.create(
      userId: userId,
      name: 'Plan sin datos',
      targetCalories: 0,
      targetProteinG: 0,
      targetCarbsG: 0,
      targetFatG: 0,
    );
  }

  Map<String, double> _emptyDailySummary() => {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
    'targetCalories': 0,
    'targetProtein': 0,
    'targetCarbs': 0,
    'targetFat': 0,
  };
}
