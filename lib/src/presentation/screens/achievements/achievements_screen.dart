import 'package:flutter/material.dart';

import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/services/gamification_service.dart';
import '../../../domain/data/achievement_catalog.dart';
import '../../../domain/entities/achievement.dart';
import '../../../infrastructure/config/di.dart';

/// Pantalla de logros del cliente.
/// Lee el perfil real de gamificación (XP, nivel, rachas) y muestra el
/// catálogo completo de logros con su progreso.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _accent = Color(0xFF6C63FF);

  bool _isLoading = true;
  GamificationProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = AuthStateNotifier.instance.userId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // getProfile ya degrada a perfil vacío ante cualquier error.
    final profile = await getIt<GamificationService>().getProfile(userId);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  /// Catálogo evaluado con las métricas actuales, conservando la fecha de
  /// desbloqueo persistida cuando existe.
  List<Achievement> _buildCatalogView(GamificationProfile profile) {
    final stats = AchievementStats(
      totalWorkouts: profile.totalWorkouts,
      currentStreak: profile.currentStreak,
      longestStreak: profile.longestStreak,
      totalXp: profile.totalXp,
    );
    final unlockedById = {
      for (final a in profile.achievements.where((a) => a.isUnlocked)) a.id: a,
    };

    return AchievementCatalog.all.map((definition) {
      final persisted = unlockedById[definition.id];
      if (persisted != null) return persisted;
      return definition.toAchievement(stats);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              color: _accent,
              onRefresh: _loadProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverAppBar(
                    expandedHeight: 80,
                    backgroundColor: Color(0xFF0A0A0F),
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Logros',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (profile == null)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Inicia sesión para ver tus logros.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(child: _buildSummaryCard(profile)),
                    SliverToBoxAdapter(child: _buildAchievementsGrid(profile)),
                  ],
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(GamificationProfile profile) {
    final unlockedCount =
        profile.achievements.where((a) => a.isUnlocked).length;
    final progress = profile.levelProgress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.2),
            const Color(0xFF12121A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel ${profile.level}',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.totalXp} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 28)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${profile.totalXp} / ${profile.xpToNextLevel} XP',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                'Nivel ${profile.level + 1}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('🔥', '${profile.currentStreak}', 'Racha'),
              _miniStat('🏋️', '${profile.totalWorkouts}', 'Entrenos'),
              _miniStat('🏆', '$unlockedCount', 'Logros'),
              _miniStat('📈', '${profile.longestStreak}', 'Mejor Racha'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(GamificationProfile profile) {
    final achievements = _buildCatalogView(profile);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Todos los logros',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...achievements.map(_buildAchievementTile),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(Achievement achievement) {
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? _accent : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? _accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.iconEmoji,
                style: TextStyle(
                  fontSize: 22,
                  color: unlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                if (!unlocked && achievement.targetValue != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      color: _accent.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.currentValue ?? 0} / ${achievement.targetValue}',
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                  color: unlocked ? _accent : Colors.white30,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ] else if (!unlocked) ...[
                const SizedBox(height: 4),
                const Icon(Icons.lock_outline_rounded,
                    color: Colors.white24, size: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String emoji, String val, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}
