import 'package:flutter/material.dart';
import '../../../application/services/nutrition_service.dart';
import '../../../domain/entities/nutrition_plan.dart';
import '../../../../src/infrastructure/config/di.dart';

/// Nutrition Tracking Screen - inspired by wger's nutritional plan UI
/// Displays daily macros, meal logging, and food search
class NutritionTrackingScreen extends StatefulWidget {
  const NutritionTrackingScreen({super.key});

  @override
  State<NutritionTrackingScreen> createState() => _NutritionTrackingScreenState();
}

class _NutritionTrackingScreenState extends State<NutritionTrackingScreen> {
  final NutritionService _nutritionService = getIt<NutritionService>();
  NutritionPlan? _plan;
  Map<String, double> _dailySummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plan = await _nutritionService.getActivePlan('current-user');
      final summary = await _nutritionService.getDailySummary('current-user', DateTime.now());
      setState(() {
        _plan = plan;
        _dailySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildMacroRings()),
                SliverToBoxAdapter(child: _buildMacroDetails()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Comidas de Hoy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: _showAddMealSheet,
                          icon: const Icon(Icons.add_circle, color: Color(0xFF6C63FF), size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildMealList(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      backgroundColor: const Color(0xFF0A0A0F),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Nutrición', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
          onPressed: _showFoodSearch,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white54),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMacroRings() {
    final calories = _dailySummary['calories'] ?? 0;
    final target = _dailySummary['targetCalories'] ?? 2200;
    final remaining = (target - calories).clamp(0, target);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.15),
            const Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: CircularProgressIndicator(
                    value: (calories / target).clamp(0, 1),
                    strokeWidth: 12,
                    backgroundColor: Colors.white10,
                    color: calories > target ? Colors.redAccent : const Color(0xFF6C63FF),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${remaining.toInt()}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                    ),
                    const Text('kcal restantes', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('Consumidas', '${calories.toInt()}', 'kcal'),
              Container(height: 30, width: 1, color: Colors.white12),
              _buildMiniStat('Objetivo', '${target.toInt()}', 'kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text('$label ($unit)', style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildMacroDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildMacroCard('Proteína', _dailySummary['protein'] ?? 0, _dailySummary['targetProtein'] ?? 150, 'g', const Color(0xFFFF6B6B)),
          const SizedBox(width: 12),
          _buildMacroCard('Carbos', _dailySummary['carbs'] ?? 0, _dailySummary['targetCarbs'] ?? 250, 'g', const Color(0xFF4ECDC4)),
          const SizedBox(width: 12),
          _buildMacroCard('Grasa', _dailySummary['fat'] ?? 0, _dailySummary['targetFat'] ?? 70, 'g', const Color(0xFFFFE66D)),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String name, double current, double target, String unit, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${current.toInt()}$unit', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('/ ${target.toInt()}$unit', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealList() {
    final meals = _plan?.meals ?? [];
    if (meals.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                const Text('Sin comidas registradas', style: TextStyle(color: Colors.white38, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Toca + para agregar tu primera comida', style: TextStyle(color: Colors.white24, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final meal = meals[index];
          return _buildMealCard(meal);
        },
        childCount: meals.length,
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final mealColors = {
      MealTime.breakfast: const Color(0xFFFFE66D),
      MealTime.morningSnack: const Color(0xFF95E1D3),
      MealTime.lunch: const Color(0xFF6C63FF),
      MealTime.afternoonSnack: const Color(0xFFFF6B6B),
      MealTime.dinner: const Color(0xFF4ECDC4),
      MealTime.eveningSnack: const Color(0xFFAA96DA),
    };
    final color = mealColors[meal.mealTime] ?? const Color(0xFF6C63FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getMealIcon(meal.mealTime), color: color, size: 22),
        ),
        title: Text(meal.mealTime.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${meal.totalCalories.toInt()} kcal · P:${meal.totalProtein.toInt()}g · C:${meal.totalCarbs.toInt()}g · G:${meal.totalFat.toInt()}g',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white24,
        children: meal.items.map((item) => _buildFoodItemRow(item, color)).toList(),
      ),
    );
  }

  Widget _buildFoodItemRow(FoodItem item, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                Text('${item.servingSize.toInt()} ${item.servingUnit}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.calories.toInt()} kcal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('P${item.proteinG.toInt()} C${item.carbsG.toInt()} G${item.fatG.toInt()}', style: const TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(MealTime time) {
    switch (time) {
      case MealTime.breakfast: return Icons.wb_sunny;
      case MealTime.morningSnack: return Icons.apple;
      case MealTime.lunch: return Icons.restaurant;
      case MealTime.afternoonSnack: return Icons.cookie;
      case MealTime.dinner: return Icons.dinner_dining;
      case MealTime.eveningSnack: return Icons.nightlight;
    }
  }

  void _showAddMealSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar Comida', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...MealTime.values.map((time) => ListTile(
              leading: Icon(_getMealIcon(time), color: const Color(0xFF6C63FF)),
              title: Text(time.displayName, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () {
                Navigator.pop(ctx);
                _showFoodSearch();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFoodSearch() async {
    final foods = await _nutritionService.searchFoods('');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar alimento...',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: foods.length,
                  itemBuilder: (_, i) {
                    final food = foods[i];
                    return ListTile(
                      title: Text(food.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${food.calories.toInt()} kcal · P:${food.proteinG.toInt()}g · C:${food.carbsG.toInt()}g · G:${food.fatG.toInt()}g',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: Text('${food.servingSize.toInt()} ${food.servingUnit}', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${food.name} agregado'), backgroundColor: const Color(0xFF6C63FF)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
