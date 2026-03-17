/// Nutrition Plan domain entity - inspired by wger-project/flutter
/// Tracks daily meals, macros, and caloric intake for gym members
class NutritionPlan {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final List<Meal> meals;
  final DateTime createdAt;
  final bool isActive;

  NutritionPlan._({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.meals,
    required this.createdAt,
    required this.isActive,
  });

  factory NutritionPlan.create({
    required String userId,
    required String name,
    String? description,
    required double targetCalories,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
  }) {
    return NutritionPlan._(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      description: description,
      targetCalories: targetCalories,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      meals: [],
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  factory NutritionPlan.restore({
    required String id,
    required String userId,
    required String name,
    String? description,
    required double targetCalories,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    required List<Meal> meals,
    required DateTime createdAt,
    required bool isActive,
  }) {
    return NutritionPlan._(
      id: id,
      userId: userId,
      name: name,
      description: description,
      targetCalories: targetCalories,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      meals: meals,
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  double get totalCalories => meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  double get totalProtein => meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.totalCarbs);
  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.totalFat);

  double get calorieProgress => targetCalories > 0 ? (totalCalories / targetCalories).clamp(0, 2) : 0;
  double get proteinProgress => targetProteinG > 0 ? (totalProtein / targetProteinG).clamp(0, 2) : 0;

  NutritionPlan addMeal(Meal meal) {
    return NutritionPlan._(
      id: id,
      userId: userId,
      name: name,
      description: description,
      targetCalories: targetCalories,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      meals: [...meals, meal],
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'description': description,
    'targetCalories': targetCalories,
    'targetProteinG': targetProteinG,
    'targetCarbsG': targetCarbsG,
    'targetFatG': targetFatG,
    'meals': meals.map((m) => m.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };
}

class Meal {
  final String id;
  final String name;
  final MealTime mealTime;
  final List<FoodItem> items;
  final DateTime loggedAt;

  Meal({
    required this.id,
    required this.name,
    required this.mealTime,
    required this.items,
    required this.loggedAt,
  });

  double get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0, (sum, item) => sum + item.proteinG);
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.carbsG);
  double get totalFat => items.fold(0, (sum, item) => sum + item.fatG);
  
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      mealTime: MealTime.values.firstWhere(
        (e) => e.name == map['mealTime'],
        orElse: () => MealTime.breakfast,
      ),
      items: (map['items'] as List?)
          ?.map((i) => FoodItem.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      loggedAt: DateTime.tryParse(map['loggedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mealTime': mealTime.name,
    'items': items.map((i) => i.toMap()).toList(),
    'loggedAt': loggedAt.toIso8601String(),
  };
}

class FoodItem {
  final String id;
  final String name;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      servingSize: (map['servingSize'] as num?)?.toDouble() ?? 100,
      servingUnit: map['servingUnit'] ?? 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (map['fatG'] as num?)?.toDouble() ?? 0,
      fiberG: (map['fiberG'] as num?)?.toDouble(),
      sugarG: (map['sugarG'] as num?)?.toDouble(),
      sodiumMg: (map['sodiumMg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'servingSize': servingSize,
    'servingUnit': servingUnit,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
  };
}

enum MealTime {
  breakfast,
  morningSnack,
  lunch,
  afternoonSnack,
  dinner,
  eveningSnack;

  String get displayName {
    switch (this) {
      case MealTime.breakfast: return 'Desayuno';
      case MealTime.morningSnack: return 'Snack Mañana';
      case MealTime.lunch: return 'Almuerzo';
      case MealTime.afternoonSnack: return 'Snack Tarde';
      case MealTime.dinner: return 'Cena';
      case MealTime.eveningSnack: return 'Snack Noche';
    }
  }
}
