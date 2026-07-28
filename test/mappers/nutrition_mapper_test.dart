import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/entities/nutrition_plan.dart';
import 'package:gym_app/src/infrastructure/mappers/nutrition_mapper.dart';

void main() {
  group('NutritionMapper Supabase round-trip', () {
    test('toSupabase produce columnas snake_case y fromSupabase reconstruye el mismo valor', () {
      final plan = NutritionPlan.create(
        userId: 'firebase-uid-123',
        name: 'Plan de volumen',
        description: 'Alto en proteína',
        targetCalories: 2800,
        targetProteinG: 180,
        targetCarbsG: 300,
        targetFatG: 80,
      ).addMeal(Meal(
        id: 'm1',
        name: 'Desayuno',
        mealTime: MealTime.breakfast,
        items: [
          FoodItem(
            id: 'f1',
            name: 'Avena',
            servingSize: 100,
            servingUnit: 'g',
            calories: 389,
            proteinG: 16.9,
            carbsG: 66.3,
            fatG: 6.9,
          ),
        ],
        loggedAt: DateTime(2026, 1, 5, 8, 0),
      ));

      final row = NutritionMapper.toSupabase(plan);

      expect(row['user_id'], 'firebase-uid-123');
      expect(row['target_calories'], 2800);
      expect(row['target_protein_g'], 180);
      expect(row.containsKey('userId'), isFalse);
      expect(row.containsKey('targetCalories'), isFalse);

      // Simula lo que devolvería PostgREST (created_at ya asignado por la DB)
      final fromDb = NutritionMapper.fromSupabase({
        ...row,
        'created_at': plan.createdAt.toIso8601String(),
      });

      expect(fromDb.id, plan.id);
      expect(fromDb.userId, plan.userId);
      expect(fromDb.name, plan.name);
      expect(fromDb.targetCalories, plan.targetCalories);
      expect(fromDb.meals, hasLength(1));
      expect(fromDb.meals.first.name, 'Desayuno');
      expect(fromDb.meals.first.items.first.name, 'Avena');
      expect(fromDb.totalCalories, 389);
    });

    test('fromSupabase tolera un plan sin comidas', () {
      final row = {
        'id': 'p1',
        'user_id': 'u1',
        'name': 'Plan vacío',
        'description': null,
        'target_calories': 2000,
        'target_protein_g': 150,
        'target_carbs_g': 200,
        'target_fat_g': 60,
        'meals': <dynamic>[],
        'is_active': true,
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      final plan = NutritionMapper.fromSupabase(row);

      expect(plan.id, 'p1');
      expect(plan.meals, isEmpty);
      expect(plan.totalCalories, 0);
    });
  });

  group('FoodDatabaseMapper Supabase round-trip', () {
    test('toSupabase/fromSupabase conservan los macros', () {
      final item = FoodItem(
        id: 'f1',
        name: 'Pechuga de pollo',
        servingSize: 100,
        servingUnit: 'g',
        calories: 165,
        proteinG: 31,
        carbsG: 0,
        fatG: 3.6,
        fiberG: 0,
        sodiumMg: 74,
      );

      final row = FoodDatabaseMapper.toSupabase(item);
      final fromDb = FoodDatabaseMapper.fromSupabase(row);

      expect(row['protein_g'], 31);
      expect(fromDb.name, 'Pechuga de pollo');
      expect(fromDb.proteinG, 31);
      expect(fromDb.sodiumMg, 74);
      expect(fromDb.sugarG, isNull);
    });
  });
}
