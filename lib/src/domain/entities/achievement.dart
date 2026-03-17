/// Achievement / Gamification domain entity
/// GYM-APP feedback and motivation system
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementCategory category;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final int? targetValue;
  final int? currentValue;

  Achievement({required this.id, required this.title, required this.description,
    required this.iconEmoji, required this.category, required this.xpReward,
    this.isUnlocked = false, this.unlockedAt, this.progress = 0,
    this.targetValue, this.currentValue});

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'description': description,
    'iconEmoji': iconEmoji, 'category': category.name,
    'xpReward': xpReward, 'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'progress': progress, 'targetValue': targetValue,
    'currentValue': currentValue};

  factory Achievement.fromMap(Map<String, dynamic> m) => Achievement(
    id: m['id'] ?? '', title: m['title'] ?? '', description: m['description'] ?? '',
    iconEmoji: m['iconEmoji'] ?? '🏆',
    category: AchievementCategory.values.firstWhere((e) => e.name == m['category'], orElse: () => AchievementCategory.general),
    xpReward: m['xpReward'] ?? 0, isUnlocked: m['isUnlocked'] ?? false,
    unlockedAt: m['unlockedAt'] != null ? DateTime.tryParse(m['unlockedAt']) : null,
    progress: (m['progress'] as num?)?.toDouble() ?? 0,
    targetValue: m['targetValue'], currentValue: m['currentValue']);
}

enum AchievementCategory {
  streak, strength, volume, consistency, nutrition, recovery, social, general;

  String get displayName {
    switch (this) {
      case streak: return 'Rachas';
      case strength: return 'Fuerza';
      case volume: return 'Volumen';
      case consistency: return 'Constancia';
      case nutrition: return 'Nutrición';
      case recovery: return 'Recuperación';
      case social: return 'Social';
      case general: return 'General';
    }
  }
}

/// User's gamification profile
class GamificationProfile {
  final String userId;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final int totalAchievements;
  final List<Achievement> achievements;
  final String rank;

  GamificationProfile({required this.userId, required this.totalXp,
    required this.level, required this.currentStreak, required this.longestStreak,
    required this.totalWorkouts, required this.totalAchievements,
    required this.achievements, required this.rank});

  int get xpToNextLevel => (level + 1) * 500;
  double get levelProgress => totalXp / xpToNextLevel;
}
