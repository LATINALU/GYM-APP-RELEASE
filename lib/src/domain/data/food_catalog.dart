import '../entities/nutrition_plan.dart';

/// Catálogo local de alimentos comunes (valores aproximados por porción).
/// Disponible offline y sin costo de lecturas; se combina con la colección
/// `food_database` de Firestore para alimentos personalizados del gym.
class FoodCatalog {
  FoodCatalog._();

  static FoodItem _f(
    String id,
    String name,
    double kcal,
    double protein,
    double carbs,
    double fat, {
    double size = 100,
    String unit = 'g',
  }) {
    return FoodItem(
      id: 'local_$id',
      name: name,
      servingSize: size,
      servingUnit: unit,
      calories: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }

  /// Búsqueda por nombre (contains, sin distinción de mayúsculas).
  /// Query vacía devuelve el catálogo completo.
  static List<FoodItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List.unmodifiable(all);
    return all
        .where((food) => food.name.toLowerCase().contains(normalized))
        .toList();
  }

  static final List<FoodItem> all = [
    // ── Proteínas animales ─────────────────────────────────────────────
    _f('pechuga_pollo', 'Pechuga de pollo (cocida)', 165, 31, 0, 3.6),
    _f('muslo_pollo', 'Muslo de pollo (cocido)', 209, 26, 0, 11),
    _f('carne_res_magra', 'Carne de res magra (cocida)', 217, 26, 0, 12),
    _f('carne_molida', 'Carne molida 80/20 (cocida)', 254, 26, 0, 17),
    _f('lomo_cerdo', 'Lomo de cerdo (cocido)', 196, 27, 0, 9),
    _f('atun_agua', 'Atún en agua (lata)', 116, 26, 0, 1),
    _f('salmon', 'Salmón (cocido)', 208, 20, 0, 13),
    _f('tilapia', 'Tilapia (cocida)', 128, 26, 0, 2.7),
    _f('camarones', 'Camarones (cocidos)', 99, 24, 0.2, 0.3),
    _f('huevo', 'Huevo entero', 72, 6.3, 0.4, 4.8, size: 1, unit: 'pieza'),
    _f('clara_huevo', 'Clara de huevo', 17, 3.6, 0.2, 0.1, size: 1, unit: 'pieza'),
    _f('jamon_pavo', 'Jamón de pavo', 104, 17, 2.5, 3),
    _f('salchicha_pavo', 'Salchicha de pavo', 196, 12, 3, 15),

    // ── Lácteos ────────────────────────────────────────────────────────
    _f('leche_entera', 'Leche entera', 61, 3.2, 4.8, 3.3, unit: 'ml'),
    _f('leche_light', 'Leche descremada', 35, 3.4, 5, 0.2, unit: 'ml'),
    _f('yogur_griego', 'Yogur griego natural', 59, 10, 3.6, 0.4),
    _f('yogur_natural', 'Yogur natural', 61, 3.5, 4.7, 3.3),
    _f('queso_panela', 'Queso panela', 270, 21, 3, 20),
    _f('queso_oaxaca', 'Queso Oaxaca', 356, 26, 2, 28),
    _f('queso_cottage', 'Queso cottage', 98, 11, 3.4, 4.3),
    _f('requeson', 'Requesón', 96, 11, 3, 4),

    // ── Carbohidratos ──────────────────────────────────────────────────
    _f('arroz_blanco', 'Arroz blanco (cocido)', 130, 2.7, 28, 0.3),
    _f('arroz_integral', 'Arroz integral (cocido)', 112, 2.6, 24, 0.9),
    _f('avena', 'Avena (cruda)', 389, 17, 66, 7),
    _f('pasta', 'Pasta (cocida)', 158, 5.8, 31, 0.9),
    _f('papa', 'Papa (cocida)', 87, 1.9, 20, 0.1),
    _f('camote', 'Camote (cocido)', 90, 2, 21, 0.2),
    _f('tortilla_maiz', 'Tortilla de maíz', 52, 1.4, 11, 0.7, size: 1, unit: 'pieza'),
    _f('tortilla_harina', 'Tortilla de harina', 90, 2.4, 15, 2.3, size: 1, unit: 'pieza'),
    _f('pan_integral', 'Pan integral', 69, 3.6, 12, 1.1, size: 1, unit: 'rebanada'),
    _f('pan_blanco', 'Pan blanco', 74, 2.6, 14, 1, size: 1, unit: 'rebanada'),
    _f('bolillo', 'Bolillo', 175, 5.5, 34, 1.5, size: 1, unit: 'pieza'),
    _f('quinoa', 'Quinoa (cocida)', 120, 4.4, 21, 1.9),
    _f('frijoles', 'Frijoles (cocidos)', 127, 8.7, 23, 0.5),
    _f('lentejas', 'Lentejas (cocidas)', 116, 9, 20, 0.4),
    _f('garbanzos', 'Garbanzos (cocidos)', 164, 8.9, 27, 2.6),
    _f('elote', 'Elote (grano cocido)', 96, 3.4, 21, 1.5),
    _f('tostada_horneada', 'Tostada horneada', 60, 1.5, 12, 0.5, size: 1, unit: 'pieza'),

    // ── Frutas ─────────────────────────────────────────────────────────
    _f('platano', 'Plátano', 105, 1.3, 27, 0.4, size: 1, unit: 'pieza'),
    _f('manzana', 'Manzana', 95, 0.5, 25, 0.3, size: 1, unit: 'pieza'),
    _f('naranja', 'Naranja', 62, 1.2, 15, 0.2, size: 1, unit: 'pieza'),
    _f('fresas', 'Fresas', 32, 0.7, 7.7, 0.3),
    _f('uvas', 'Uvas', 69, 0.7, 18, 0.2),
    _f('mango', 'Mango', 60, 0.8, 15, 0.4),
    _f('papaya', 'Papaya', 43, 0.5, 11, 0.3),
    _f('sandia', 'Sandía', 30, 0.6, 7.6, 0.2),
    _f('melon', 'Melón', 34, 0.8, 8.2, 0.2),
    _f('pina', 'Piña', 50, 0.5, 13, 0.1),
    _f('arandanos', 'Arándanos', 57, 0.7, 14, 0.3),
    _f('kiwi', 'Kiwi', 42, 0.8, 10, 0.4, size: 1, unit: 'pieza'),
    _f('durazno', 'Durazno', 59, 1.4, 14, 0.4, size: 1, unit: 'pieza'),

    // ── Verduras ───────────────────────────────────────────────────────
    _f('brocoli', 'Brócoli (cocido)', 35, 2.4, 7.2, 0.4),
    _f('espinaca', 'Espinaca (cruda)', 23, 2.9, 3.6, 0.4),
    _f('lechuga', 'Lechuga', 15, 1.4, 2.9, 0.2),
    _f('jitomate', 'Jitomate', 18, 0.9, 3.9, 0.2),
    _f('zanahoria', 'Zanahoria', 41, 0.9, 10, 0.2),
    _f('calabacita', 'Calabacita', 17, 1.2, 3.1, 0.3),
    _f('pepino', 'Pepino', 15, 0.7, 3.6, 0.1),
    _f('nopales', 'Nopales (cocidos)', 15, 1.4, 3.3, 0.1),
    _f('chayote', 'Chayote (cocido)', 24, 0.6, 5.1, 0.5),
    _f('ejotes', 'Ejotes (cocidos)', 35, 1.9, 7.9, 0.3),
    _f('champinones', 'Champiñones', 22, 3.1, 3.3, 0.3),
    _f('pimiento', 'Pimiento morrón', 31, 1, 6, 0.3),
    _f('cebolla', 'Cebolla', 40, 1.1, 9.3, 0.1),
    _f('aguacate', 'Aguacate', 160, 2, 8.5, 15),

    // ── Grasas y frutos secos ──────────────────────────────────────────
    _f('almendras', 'Almendras', 579, 21, 22, 50),
    _f('nueces', 'Nueces', 654, 15, 14, 65),
    _f('cacahuates', 'Cacahuates', 567, 26, 16, 49),
    _f('crema_cacahuate', 'Crema de cacahuate', 588, 25, 20, 50),
    _f('aceite_oliva', 'Aceite de oliva', 119, 0, 0, 13.5, size: 15, unit: 'ml'),
    _f('mantequilla', 'Mantequilla', 102, 0.1, 0, 11.5, size: 14, unit: 'g'),
    _f('chia', 'Semillas de chía', 486, 17, 42, 31),
    _f('linaza', 'Linaza', 534, 18, 29, 42),

    // ── Suplementos y bebidas ──────────────────────────────────────────
    _f('proteina_whey', 'Proteína whey (1 scoop)', 120, 24, 3, 1.5, size: 30, unit: 'g'),
    _f('caseina', 'Caseína (1 scoop)', 110, 24, 3, 0.5, size: 30, unit: 'g'),
    _f('creatina', 'Creatina monohidratada', 0, 0, 0, 0, size: 5, unit: 'g'),
    _f('cafe_negro', 'Café negro', 2, 0.3, 0, 0, size: 240, unit: 'ml'),
    _f('jugo_naranja', 'Jugo de naranja', 45, 0.7, 10, 0.2, unit: 'ml'),
    _f('refresco', 'Refresco de cola', 42, 0, 10.6, 0, unit: 'ml'),
    _f('bebida_deportiva', 'Bebida deportiva', 26, 0, 6.5, 0, unit: 'ml'),

    // ── Platillos comunes ──────────────────────────────────────────────
    _f('tacos_pollo', 'Taco de pollo (1 pieza)', 180, 12, 18, 7, size: 1, unit: 'pieza'),
    _f('quesadilla', 'Quesadilla (1 pieza)', 240, 10, 22, 13, size: 1, unit: 'pieza'),
    _f('tamal', 'Tamal (1 pieza)', 285, 6, 32, 15, size: 1, unit: 'pieza'),
    _f('sandwich_pavo', 'Sándwich de pavo', 290, 18, 35, 9, size: 1, unit: 'pieza'),
    _f('ensalada_pollo', 'Ensalada con pollo', 320, 30, 12, 17, size: 1, unit: 'porción'),
    _f('caldo_pollo', 'Caldo de pollo con verduras', 150, 15, 12, 4, size: 1, unit: 'plato'),
    _f('ceviche_pescado', 'Ceviche de pescado', 130, 18, 9, 2, size: 1, unit: 'porción'),
  ];
}
