import 'dart:ui';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/quantum_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/neon_widgets.dart';
import '../../bloc/app_bloc.dart';


class TrainingDashboardScreen extends StatelessWidget {
  const TrainingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AppBloc is already provided by ClientMainLayout, no need to provide again
    return const _TrainingDashboardContent();
  }
}

class _TrainingDashboardContent extends StatefulWidget {
  const _TrainingDashboardContent();

  @override
  State<_TrainingDashboardContent> createState() => _TrainingDashboardContentState();
}

class _TrainingDashboardContentState extends State<_TrainingDashboardContent> {
  late String _motivationalMessage;
  
  final List<String> _motivationalMessages = [
    'Es hora de entrenar 💪',
    'Hoy es tu día de brillar ⚡',
    'Cada rep cuenta 🔥',
    'Supera tus límites 🚀',
    'La constancia es la clave 💎',
    'Entrena como un campeón 🏆',
    'Tu mejor versión te espera ✨',
    'Hazlo por ti 💯',
    'Sin excusas, solo resultados 💪',
    'El progreso empieza hoy 🎯',
    'Eres más fuerte de lo que crees 🦾',
    'Cada día más cerca de tu meta 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _motivationalMessage = _motivationalMessages[Random().nextInt(_motivationalMessages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = (authState is Authenticated) ? authState.user : null;
        final firstName = user?.name.firstName ?? 'Atleta';

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          body: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                context.read<AppBloc>().add(RefreshAppData(userId: user.id, gymId: user.gymId));
              }
            },
            color: QuantumColors.quantumBlue,
            backgroundColor: QuantumColors.surface(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ═══════════════════════════════════════════════════════════
                // HEADER - Neon Avatar + Greeting + Notification Bell
                // ═══════════════════════════════════════════════════════════
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: 140,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            QuantumColors.quantumBlue.withValues(alpha: 0.04),
                            QuantumColors.cosmicBlack,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Ambient glow
                          Positioned(
                            top: -50,
                            right: -50,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: QuantumColors.quantumBlue.withValues(alpha: 0.04),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildNeonAvatar(firstName),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Hola, $firstName',
                                        style: QuantumTypography.h2.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _motivationalMessage,
                                        style: QuantumTypography.bodyMedium.copyWith(
                                          color: QuantumColors.quantumBlue,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Notification bell with dot
                                Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () => context.push('/client/notifications'),
                                      icon: Icon(Icons.notifications_none_rounded,
                                          color: Colors.white.withValues(alpha: 0.45), size: 26),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: QuantumColors.quantumBlue,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: QuantumColors.quantumBlue.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════════════════════
                // CONTENT
                // ═══════════════════════════════════════════════════════════
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quick Stats Row (3 neon cards)
                      _buildQuickStats(),

                      const SizedBox(height: 24),

                      // Next Session Card
                      _buildNextSessionCard(context),

                      const SizedBox(height: 24),

                      // Weekly Performance Chart
                      _buildPerformanceChart(),

                      const SizedBox(height: 28),

                      // Mi Rutina Activa
                      _buildActiveRoutineSection(context),

                      const SizedBox(height: 28),

                      // Progreso Reciente
                      _buildRecentProgressSection(context),

                      const SizedBox(height: 140),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/client/daily-workout'),
              backgroundColor: QuantumColors.quantumBlue,
              elevation: 8,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 20),
              ),
              label: const Text(
                'ENTRENAMIENTO LIBRE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).shimmer(
              duration: 2000.ms,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  // ─── HEADER AVATAR ─────────────────────────────────────────────────
  static Widget _buildNeonAvatar(String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: QuantumColors.cosmicBlack,
        shape: BoxShape.circle,
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: QuantumTypography.h3.copyWith(
            color: QuantumColors.quantumBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── QUICK STATS (3 Cards) ────────────────────────────────────────
  Widget _buildQuickStats() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        String calories = '0';
        String streak = '0';
        String volume = '0';

        if (appState is AppLoaded) {
          calories = '${appState.estimatedCalories}';
          streak = '${appState.currentStreak}';
          volume = '${appState.weeklyVolume.toInt()}';
        }

        return Row(
          children: [
            Expanded(
              child: NeonStatCard(
                icon: Icons.local_fire_department_outlined,
                title: 'Calorías',
                value: calories,
                unit: 'kcal',
                isActive: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NeonStatCard(
                icon: Icons.bolt_rounded,
                title: 'Racha',
                value: streak,
                unit: 'días',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NeonStatCard(
                icon: Icons.fitness_center_outlined,
                title: 'Volumen',
                value: volume,
                unit: 'kg',
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── NEXT SESSION ──────────────────────────────────────────────────
  Widget _buildNextSessionCard(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        if (state is! AppLoaded || state.assignedPlan == null) {
          return const SizedBox.shrink();
        }

        final plan = state.assignedPlan!;
        final todayWorkout = plan.todaysWorkout;

        if (todayWorkout == null || todayWorkout.isRestDay) {
          return _buildRestDayCard();
        }

        return NeonCard(
          hasGlow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('HOY',
                        style: QuantumTypography.label.copyWith(
                            color: QuantumColors.quantumBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.15), size: 14),
                ],
              ),
              const SizedBox(height: 14),
              Text(todayWorkout.name,
                  style: QuantumTypography.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniChip(Icons.fitness_center_rounded, '${todayWorkout.exerciseCount} Ejercicios'),
                  const SizedBox(width: 12),
                  _buildMiniChip(Icons.timer_outlined, '${todayWorkout.estimatedDuration} min'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/client/daily-workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('EMPEZAR AHORA',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildRestDayCard() {
    return NeonCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.orangeAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DÍA DE DESCANSO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Tu cuerpo necesita recuperarse', style: QuantumTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.2), size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
      ],
    );
  }

  // ─── PERFORMANCE CHART ─────────────────────────────────────────────
  Widget _buildPerformanceChart() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        // Build chart spots from real weekly frequency data
        List<FlSpot> spots;
        if (appState is AppLoaded && appState.weeklyFrequency.isNotEmpty) {
          spots = appState.weeklyFrequency.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.toDouble());
          }).toList();
        } else {
          spots = const [
            FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5),
            FlSpot(3, 5), FlSpot(4, 4.5), FlSpot(5, 6), FlSpot(6, 5.5),
          ];
        }

        return NeonCard(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rendimiento Semanal',
                    style: QuantumTypography.label.copyWith(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: QuantumColors.minimalGradient,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                QuantumColors.quantumBlue.withValues(alpha: 0.25),
                                QuantumColors.quantumBlue.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── RUTINA ACTIVA ─────────────────────────────────────────────────
  Widget _buildActiveRoutineSection(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        if (state is AppLoaded && state.assignedPlan != null) {
          final routine = state.assignedPlan!;
          final totalExercises = routine.weeklySchedule.fold<int>(
            0, (sum, day) => sum + day.exercises.length
          );
          
          return InkWell(
            onTap: () => context.push('/client/routine'),
            borderRadius: BorderRadius.circular(16),
            child: NeonCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center, color: QuantumColors.quantumBlue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: QuantumTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalExercises ejercicios • ${routine.weeklySchedule.length} días',
                          style: QuantumTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                ],
              ),
            ),
          );
        }
        
        return InkWell(
          onTap: () => context.push('/client/routine'),
          borderRadius: BorderRadius.circular(16),
          child: NeonCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center_outlined, color: Colors.white38, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sin rutina activa',
                        style: QuantumTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para explorar rutinas',
                        style: QuantumTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── PROGRESO RECIENTE ─────────────────────────────────────────────
  Widget _buildRecentProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TU PROGRESO',
              style: QuantumTypography.label.copyWith(
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/client/analytics'),
              child: Text(
                'Ver todo',
                style: QuantumTypography.bodySmall.copyWith(
                  color: QuantumColors.quantumBlue,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                context,
                icon: Icons.calendar_today,
                label: 'Frecuencia',
                value: '0',
                unit: 'días',
                color: QuantumColors.quantumBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                context,
                icon: Icons.trending_up,
                label: 'Fuerza',
                value: '+0%',
                unit: 'crecimiento',
                color: QuantumColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return InkWell(
      onTap: () => context.push('/client/analytics'),
      borderRadius: BorderRadius.circular(16),
      child: NeonCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: QuantumTypography.h3.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: QuantumTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
