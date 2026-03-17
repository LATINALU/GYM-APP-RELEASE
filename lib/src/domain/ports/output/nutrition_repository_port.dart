import 'package:gym_app/src/domain/entities/nutrition_plan.dart';

/// PORT - Output interface for nutrition data persistence
abstract class NutritionRepositoryPort {
  Future<void> savePlan(NutritionPlan plan);
  Future<NutritionPlan?> getActivePlan(String userId);
  Future<List<NutritionPlan>> getAllPlans(String userId);
  Future<void> deletePlan(String planId);
  Future<void> logMeal(String planId, Meal meal);
  Future<List<Meal>> getMealsByDate(String userId, DateTime date);
  Future<List<FoodItem>> searchFoods(String query);
}
