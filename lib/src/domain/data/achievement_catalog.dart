import '../entities/achievement.dart';

/// Métricas del perfil usadas para evaluar condiciones de desbloqueo.
class AchievementStats {
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final int totalXp;

  const AchievementStats({
    required this.totalWorkouts,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
  });
}

/// Definición estática de un logro: metadatos + condición de desbloqueo.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementCategory category;
  final int xpReward;
  final int target;
  final int Function(AchievementStats stats) metric;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.category,
    required this.xpReward,
    required this.target,
    required this.metric,
  });

  bool isSatisfiedBy(AchievementStats stats) => metric(stats) >= target;

  /// Convierte la definición a entidad, con el progreso actual del usuario.
  Achievement toAchievement(AchievementStats stats, {DateTime? unlockedAt}) {
    final current = metric(stats);
    final unlocked = current >= target;
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconEmoji: iconEmoji,
      category: category,
      xpReward: xpReward,
      isUnlocked: unlocked,
      unlockedAt: unlocked ? (unlockedAt ?? DateTime.now()) : null,
      progress: target == 0 ? 0 : (current / target).clamp(0.0, 1.0),
      targetValue: target,
      currentValue: current,
    );
  }
}

/// Catálogo de logros de la plataforma.
/// Se evalúa contra las métricas del doc `gamification/{userId}`.
class AchievementCatalog {
  AchievementCatalog._();

  static int _workouts(AchievementStats s) => s.totalWorkouts;
  static int _streak(AchievementStats s) => s.currentStreak;
  static int _bestStreak(AchievementStats s) => s.longestStreak;
  static int _xp(AchievementStats s) => s.totalXp;

  static const List<AchievementDefinition> all = [
    // ── Constancia ──────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'primer_entreno',
      title: 'Primer Paso',
      description: 'Completa tu primer entrenamiento',
      iconEmoji: '🎯',
      category: AchievementCategory.general,
      xpReward: 50,
      target: 1,
      metric: _workouts,
    ),
    AchievementDefinition(
      id: 'constante_5',
      title: 'En Marcha',
      description: 'Completa 5 entrenamientos',
      iconEmoji: '🏃',
      category: AchievementCategory.consistency,
      xpReward: 100,
      target: 5,
      metric: _workouts,
    ),
    AchievementDefinition(
      id: 'dedicado_25',
      title: 'Dedicación',
      description: 'Completa 25 entrenamientos',
      iconEmoji: '💪',
      category: AchievementCategory.consistency,
      xpReward: 250,
      target: 25,
      metric: _workouts,
    ),
    AchievementDefinition(
      id: 'veterano_50',
      title: 'Veterano',
      description: 'Completa 50 entrenamientos',
      iconEmoji: '🦾',
      category: AchievementCategory.consistency,
      xpReward: 500,
      target: 50,
      metric: _workouts,
    ),
    AchievementDefinition(
      id: 'imparable_100',
      title: 'Imparable',
      description: 'Completa 100 entrenamientos',
      iconEmoji: '👑',
      category: AchievementCategory.consistency,
      xpReward: 1000,
      target: 100,
      metric: _workouts,
    ),

    // ── Rachas ──────────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'racha_3',
      title: 'Calentando',
      description: 'Entrena 3 días seguidos',
      iconEmoji: '🔥',
      category: AchievementCategory.streak,
      xpReward: 75,
      target: 3,
      metric: _streak,
    ),
    AchievementDefinition(
      id: 'racha_7',
      title: 'Semana Perfecta',
      description: 'Entrena 7 días seguidos',
      iconEmoji: '⚡',
      category: AchievementCategory.streak,
      xpReward: 150,
      target: 7,
      metric: _streak,
    ),
    AchievementDefinition(
      id: 'racha_30',
      title: 'Modo Bestia',
      description: 'Entrena 30 días seguidos',
      iconEmoji: '🐉',
      category: AchievementCategory.streak,
      xpReward: 500,
      target: 30,
      metric: _streak,
    ),
    AchievementDefinition(
      id: 'mejor_racha_14',
      title: 'Quincena de Hierro',
      description: 'Alcanza una racha máxima de 14 días',
      iconEmoji: '🛡️',
      category: AchievementCategory.streak,
      xpReward: 300,
      target: 14,
      metric: _bestStreak,
    ),

    // ── Experiencia ─────────────────────────────────────────────────────
    AchievementDefinition(
      id: 'xp_1000',
      title: 'Subiendo de Nivel',
      description: 'Acumula 1,000 XP',
      iconEmoji: '⭐',
      category: AchievementCategory.general,
      xpReward: 100,
      target: 1000,
      metric: _xp,
    ),
    AchievementDefinition(
      id: 'xp_5000',
      title: 'Leyenda del Gym',
      description: 'Acumula 5,000 XP',
      iconEmoji: '🌟',
      category: AchievementCategory.general,
      xpReward: 250,
      target: 5000,
      metric: _xp,
    ),
  ];

  static AchievementDefinition? byId(String id) {
    for (final definition in all) {
      if (definition.id == id) return definition;
    }
    return null;
  }
}
