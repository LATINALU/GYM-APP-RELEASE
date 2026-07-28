import 'package:supabase/supabase.dart';
import 'package:gym_app/src/domain/data/food_catalog.dart';
import 'package:gym_app/src/domain/entities/nutrition_plan.dart';
import 'package:gym_app/src/domain/ports/output/nutrition_repository_port.dart';
import '../../mappers/nutrition_mapper.dart';

/// Fase 1 de la migración Firebase->Supabase: mismo contrato que
/// [FirebaseNutritionRepository], respaldado por `public.nutrition_plans`
/// y `public.food_database` (ver supabase/migrations/0004_nutrition_plans.sql
/// y 0005_food_database.sql).
class SupabaseNutritionRepository implements NutritionRepositoryPort {
  final SupabaseClient _client;
  SupabaseNutritionRepository(this._client);

  SupabaseQueryBuilder get _plans => _client.from('nutrition_plans');
  SupabaseQueryBuilder get _foods => _client.from('food_database');

  @override
  Future<void> savePlan(NutritionPlan plan) async {
    await _plans.upsert(NutritionMapper.toSupabase(plan));
  }

  @override
  Future<NutritionPlan?> getActivePlan(String userId) async {
    final rows = await _plans
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);
    if (rows.isEmpty) return null;
    return NutritionMapper.fromSupabase(rows.first);
  }

  @override
  Future<void> logMeal(String planId, Meal meal) async {
    final row = await _plans.select().eq('id', planId).single();
    final plan = NutritionMapper.fromSupabase(row).addMeal(meal);
    await savePlan(plan);
  }

  @override
  Future<void> deletePlan(String planId) async {
    await _plans.delete().eq('id', planId);
  }

  @override
  Future<List<NutritionPlan>> getAllPlans(String userId) async {
    final rows = await _plans
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((r) => NutritionMapper.fromSupabase(r)).toList();
  }

  @override
  Future<List<Meal>> getMealsByDate(String userId, DateTime date) async {
    final activePlan = await getActivePlan(userId);
    if (activePlan == null) return [];
    return activePlan.meals
        .where((m) =>
            m.loggedAt.year == date.year &&
            m.loggedAt.month == date.month &&
            m.loggedAt.day == date.day)
        .toList();
  }

  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    // Catálogo local: siempre disponible (offline, sin costo de lecturas).
    final localResults = FoodCatalog.search(query);

    // Alimentos personalizados en Postgres; si falla (offline, permisos)
    // se responde solo con el catálogo local.
    List<FoodItem> remoteResults = const [];
    try {
      final rows = await _foods.select().ilike('name', '%$query%').limit(10);
      remoteResults = rows.map((r) => FoodDatabaseMapper.fromSupabase(r)).toList();
    } catch (_) {
      // Sin conexión o sin datos remotos: el catálogo local basta.
    }

    // Los alimentos del gym tienen prioridad sobre el catálogo ante nombres
    // duplicados.
    final seenNames = <String>{};
    final merged = <FoodItem>[];
    for (final item in [...remoteResults, ...localResults]) {
      if (seenNames.add(item.name.toLowerCase())) {
        merged.add(item);
      }
    }
    return merged;
  }
}
