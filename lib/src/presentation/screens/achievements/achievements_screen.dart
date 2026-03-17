import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/app_bloc.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final currentStreak = state is AppLoaded ? state.currentStreak : 0;
        final longestStreak = state is AppLoaded ? state.longestStreak : 0;
        final totalWorkouts = state is AppLoaded ? state.totalWorkouts : 0;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: CustomScrollView(
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
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        const Color(0xFF12121A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen real',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Progreso',
                                style: TextStyle(
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
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '🏆',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: const LinearProgressIndicator(
                          value: 0,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sin XP conectado',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            'Gamificación pendiente',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniStat('🔥', '$currentStreak', 'Racha'),
                          _miniStat('🏋️', '$totalWorkouts', 'Entrenos'),
                          _miniStat('🏆', '0', 'Logros'),
                          _miniStat('📈', '$longestStreak', 'Mejor Racha'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white24,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aún no hay logros sincronizados',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tus logros aparecerán aquí cuando la gamificación real esté conectada a tu perfil.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
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
