import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/data/achievement_catalog.dart';
import '../../domain/entities/achievement.dart';

/// Gamification Application Service
/// Manages XP, levels, achievements, and streaks
class GamificationService {
  final FirebaseFirestore _firestore;
  GamificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user's gamification profile
  Future<GamificationProfile> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('gamification').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? const <String, dynamic>{};
        final achievementsRaw = data['achievements'];
        final achievements =
            achievementsRaw is List
                ? achievementsRaw
                    .whereType<Map>()
                    .map((item) {
                      try {
                        return Achievement.fromMap(
                          item.cast<String, dynamic>(),
                        );
                      } catch (_) {
                        return null;
                      }
                    })
                    .whereType<Achievement>()
                    .toList()
                : <Achievement>[];

        final totalXp = _asInt(data['totalXp']);
        final level =
            _asInt(data['level']) == 0
                ? _calculateLevel(totalXp)
                : _asInt(data['level']);
        final unlockedCount =
            achievements.where((achievement) => achievement.isUnlocked).length;
        return GamificationProfile(
          userId: userId,
          totalXp: totalXp,
          level: level,
          currentStreak: _asInt(data['currentStreak']),
          longestStreak: _asInt(data['longestStreak']),
          totalWorkouts: _asInt(data['totalWorkouts']),
          totalAchievements:
              _asInt(data['totalAchievements']) == 0
                  ? unlockedCount
                  : _asInt(data['totalAchievements']),
          achievements: achievements,
          rank: _readString(data['rank'], fallback: 'Sin rango'),
        );
      }
      return _emptyProfile(userId);
    } catch (e) {
      return _emptyProfile(userId);
    }
  }

  /// Award XP to user
  Future<void> awardXp(String userId, int xp, String reason) async {
    try {
      // set + merge: funciona también para usuarios sin perfil todavía.
      await _firestore.collection('gamification').doc(userId).set({
        'totalXp': FieldValue.increment(xp),
        'xpHistory': FieldValue.arrayUnion([
          {
            'amount': xp,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('No se pudo otorgar XP: $e');
    }
  }

  /// Evalúa el catálogo contra las métricas del perfil y desbloquea los
  /// logros nuevos (persiste + otorga su XP). Devuelve los recién ganados.
  Future<List<Achievement>> checkAchievements(String userId) async {
    try {
      final profile = await getProfile(userId);
      final stats = AchievementStats(
        totalWorkouts: profile.totalWorkouts,
        currentStreak: profile.currentStreak,
        longestStreak: profile.longestStreak,
        totalXp: profile.totalXp,
      );

      final alreadyUnlocked =
          profile.achievements
              .where((a) => a.isUnlocked)
              .map((a) => a.id)
              .toSet();

      final newlyUnlocked = <Achievement>[];
      for (final definition in AchievementCatalog.all) {
        if (alreadyUnlocked.contains(definition.id)) continue;
        if (definition.isSatisfiedBy(stats)) {
          newlyUnlocked.add(definition.toAchievement(stats));
        }
      }

      if (newlyUnlocked.isEmpty) return const [];

      final xpFromAchievements =
          newlyUnlocked.fold<int>(0, (total, a) => total + a.xpReward);

      await _firestore.collection('gamification').doc(userId).set({
        'achievements': FieldValue.arrayUnion(
          newlyUnlocked.map((a) => a.toMap()).toList(),
        ),
        'totalAchievements': FieldValue.increment(newlyUnlocked.length),
        'totalXp': FieldValue.increment(xpFromAchievements),
      }, SetOptions(merge: true));

      return newlyUnlocked;
    } catch (e) {
      return const [];
    }
  }

  /// Registra un entrenamiento completado: XP base, racha, contador de
  /// workouts y evaluación de logros. Devuelve los logros recién ganados.
  Future<List<Achievement>> recordWorkoutCompletion(
    String userId, {
    int baseXp = 50,
  }) async {
    await updateStreak(userId);
    await _firestore.collection('gamification').doc(userId).set({
      'totalWorkouts': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await awardXp(userId, baseXp, 'Entrenamiento completado');
    return checkAchievements(userId);
  }

  /// Update streak
  Future<int> updateStreak(String userId) async {
    try {
      final docRef = _firestore.collection('gamification').doc(userId);
      final doc = await docRef.get();
      final data = doc.data() ?? const <String, dynamic>{};

      final lastWorkout =
          DateTime.tryParse(data['lastWorkoutDate']?.toString() ?? '');
      final today = DateTime.now();
      int streak = _asInt(data['currentStreak']);

      if (lastWorkout != null) {
        // Comparación por día calendario para no depender de la hora.
        final lastDay =
            DateTime(lastWorkout.year, lastWorkout.month, lastWorkout.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final diff = todayDay.difference(lastDay).inDays;
        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          streak = 1;
        } else if (streak == 0) {
          streak = 1;
        }
      } else {
        streak = 1;
      }

      final longest = _asInt(data['longestStreak']);
      await docRef.set({
        'currentStreak': streak,
        'lastWorkoutDate': today.toIso8601String(),
        'longestStreak': streak > longest ? streak : longest,
      }, SetOptions(merge: true));
      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snap =
          await _firestore
              .collection('gamification')
              .orderBy('totalXp', descending: true)
              .limit(limit)
              .get();
      return snap.docs.map((d) => {'userId': d.id, ...d.data()}).toList();
    } catch (e) {
      return const [];
    }
  }

  GamificationProfile _emptyProfile(String userId) {
    return GamificationProfile(
      userId: userId,
      totalXp: 0,
      level: 1,
      currentStreak: 0,
      longestStreak: 0,
      totalWorkouts: 0,
      totalAchievements: 0,
      achievements: const [],
      rank: 'Sin rango',
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _readString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  int _calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    return (totalXp / 500).floor() + 1;
  }
}
