import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/src/domain/data/food_catalog.dart';
import 'package:gym_app/src/domain/entities/nutrition_plan.dart';
import 'package:gym_app/src/domain/ports/output/nutrition_repository_port.dart';
import '../../mappers/nutrition_mapper.dart';

class FirebaseNutritionRepository implements NutritionRepositoryPort {
  final FirebaseFirestore _firestore;
  FirebaseNutritionRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _plans => _firestore.collection('nutrition_plans');

  @override
  Future<void> savePlan(NutritionPlan plan) async {
    await _plans.doc(plan.id).set(NutritionMapper.toFirestore(plan));
  }

  @override
  Future<NutritionPlan?> getActivePlan(String userId) async {
    final snap = await _plans
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return NutritionMapper.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  @override
  Future<void> logMeal(String planId, Meal meal) async {
    await _plans.doc(planId).update({
      'meals': FieldValue.arrayUnion([meal.toMap()])
    });
  }

  @override
  Future<void> deletePlan(String planId) async {
    await _plans.doc(planId).delete();
  }

  @override
  Future<List<NutritionPlan>> getAllPlans(String userId) async {
    final snap = await _plans
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => NutritionMapper.fromFirestore(d.data(), d.id)).toList();
  }

  @override
  Future<List<Meal>> getMealsByDate(String userId, DateTime date) async {
    final activePlan = await getActivePlan(userId);
    if (activePlan == null) return [];
    
    return activePlan.meals.where((m) {
      return m.loggedAt.year == date.year &&
             m.loggedAt.month == date.month &&
             m.loggedAt.day == date.day;
    }).toList();
  }

  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    // Cat\u00e1logo local: siempre disponible (offline, sin costo de lecturas).
    final localResults = FoodCatalog.search(query);

    // Alimentos personalizados en Firestore; si falla (offline, permisos)
    // se responde solo con el cat\u00e1logo local.
    List<FoodItem> remoteResults = const [];
    try {
      final snap = await _firestore
          .collection('food_database')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();
      remoteResults =
          snap.docs.map((d) => FoodItem.fromMap(d.data())).toList();
    } catch (_) {
      // Sin conexi\u00f3n o sin datos remotos: el cat\u00e1logo local basta.
    }

    // Los alimentos del gym tienen prioridad sobre el cat\u00e1logo ante nombres
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
