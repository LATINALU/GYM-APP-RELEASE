import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/quantum_colors.dart';
import '../../widgets/neon_widgets.dart';
import '../../bloc/app_bloc.dart';

class ClientAnalyticsDashboardScreen extends StatelessWidget {
  const ClientAnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── HEADER ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      QuantumColors.quantumBlue.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: QuantumColors.surface(opacity: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: QuantumColors.subtleBorder),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Analíticas',
                      style: QuantumTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: QuantumColors.quantumBlue.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: QuantumColors.quantumBlue,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Esta Semana',
                            style: TextStyle(
                              color: QuantumColors.quantumBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── CONTENT ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Weekly Frequency Chart
                  _buildWeeklyFrequencyCard(),
                  const SizedBox(height: 16),

                  // 2. Strength Growth Chart
                  _buildStrengthGrowthCard(),
                  const SizedBox(height: 16),

                  // 3. Goal + Milestone Row
                  Row(
                    children: [
                      Expanded(child: _buildGoalCardWired()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildMilestoneCardWired()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Volume Breakdown
                  _buildVolumeBreakdown(),
                  const SizedBox(height: 16),

                  // 5. Personal Records
                  _buildPersonalRecords(),

                  const SizedBox(height: 120), // Nav bar spacing
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEEKLY FREQUENCY ──────────────────────────────────────────
  Widget _buildWeeklyFrequencyCard() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        List<double> barHeights;
        int activeDays = 0;

        if (state is AppLoaded && state.weeklyFrequency.isNotEmpty) {
          final freq = state.weeklyFrequency;
          final maxCount = freq.fold<int>(0, (max, e) => e > max ? e : max);
          barHeights =
              freq.map((e) {
                if (e > 0) activeDays++;
                return maxCount > 0 ? e / maxCount : 0.0;
              }).toList();
        } else {
          barHeights = List<double>.filled(dayLabels.length, 0.0);
          activeDays = 0;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frecuencia Semanal',
                    style: QuantumTypography.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    activeDays > 0 ? '$activeDays días' : 'Sin datos',
                    style: const TextStyle(
                      color: QuantumColors.quantumBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(barHeights.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: GlowingBar(heightFactor: barHeights[i]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dayLabels[i],
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── STRENGTH GROWTH ──────────────────────────────────────────
  Widget _buildStrengthGrowthCard() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        List<double> barHeights = List<double>.filled(8, 0.0);
        String trendLabel = 'Sin datos';
        bool hasData = false;

        if (state is AppLoaded && state.personalRecords.isNotEmpty) {
          final records = state.personalRecords.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          final recentRecords =
              records.length > 8
                  ? records.sublist(records.length - 8)
                  : records;

          final maxWeight = recentRecords.fold<double>(
            0,
            (max, pr) => pr.weight > max ? pr.weight : max,
          );

          if (maxWeight > 0 && recentRecords.isNotEmpty) {
            hasData = true;
            barHeights =
                recentRecords
                    .map((pr) => (pr.weight / maxWeight).clamp(0.0, 1.0))
                    .toList();
            while (barHeights.length < 8) {
              barHeights.insert(0, 0.0);
            }

            final firstWeight = recentRecords.first.weight;
            final lastWeight = recentRecords.last.weight;
            if (firstWeight > 0) {
              final delta = ((lastWeight - firstWeight) / firstWeight) * 100;
              trendLabel =
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%';
            } else {
              trendLabel = 'Base creada';
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: QuantumColors.matrixCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Crecimiento de Fuerza',
                    style: QuantumTypography.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trendLabel,
                    style: const TextStyle(
                      color: QuantumColors.matrixCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      barHeights
                          .map(
                            (h) => GlowingBar(
                              heightFactor: h,
                              color: QuantumColors.matrixCyan,
                            ),
                          )
                          .toList(),
                ),
              ),
              if (!hasData)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Registra PRs para visualizar tu evolución de fuerza.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── MILESTONE CARD - wired to ClientBloc ────────────────────
  Widget _buildMilestoneCardWired() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        int totalWorkouts = 0;
        if (state is AppLoaded) {
          totalWorkouts = state.totalWorkouts;
        }
        // Milestones: count achievements based on total workouts
        int milestones = 0;
        if (totalWorkouts >= 1) milestones++;
        if (totalWorkouts >= 10) milestones++;
        if (totalWorkouts >= 25) milestones++;
        if (totalWorkouts >= 50) milestones++;
        if (totalWorkouts >= 100) milestones++;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                'Hitos',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$milestones',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'logros',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── VOLUME BREAKDOWN ─────────────────────────────────────────
  Widget _buildVolumeBreakdown() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        List<Map<String, dynamic>> muscles;

        if (state is AppLoaded && state.muscleVolumeMap.isNotEmpty) {
          final volumeMap = state.muscleVolumeMap;
          final maxVol = volumeMap.values.fold<double>(
            0,
            (m, v) => v > m ? v : m,
          );
          muscles =
              volumeMap.entries
                  .map(
                    (e) => {
                      'name': e.key,
                      'value': maxVol > 0 ? e.value / maxVol : 0.0,
                      'kg': _formatVolume(e.value),
                    },
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      (b['value'] as double).compareTo(a['value'] as double),
                );
        } else {
          muscles = [];
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pie_chart_outline_rounded,
                    color: QuantumColors.quantumBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Volumen por Grupo Muscular',
                    style: QuantumTypography.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (muscles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Todavía no hay volumen registrado por grupo muscular.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...muscles
                    .take(6)
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m['name'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${m['kg']} kg',
                                  style: const TextStyle(
                                    color: QuantumColors.quantumBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (m['value'] as double).clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.05,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  QuantumColors.quantumBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  String _formatVolume(double vol) {
    if (vol >= 1000) {
      return '${(vol / 1000).toStringAsFixed(1)}k';
    }
    return vol.toInt().toString();
  }

  // ─── PERSONAL RECORDS ─────────────────────────────────────────
  Widget _buildPersonalRecords() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        List<Map<String, String>> records;

        if (state is AppLoaded && state.personalRecords.isNotEmpty) {
          records =
              state.personalRecords.values.take(5).map((pr) {
                final daysAgo = DateTime.now().difference(pr.date).inDays;
                String dateLabel;
                if (daysAgo == 0) {
                  dateLabel = 'Hoy';
                } else if (daysAgo == 1) {
                  dateLabel = 'Ayer';
                } else {
                  dateLabel = '${daysAgo}d';
                }
                return {
                  'exercise': pr.exerciseName,
                  'weight': '${pr.weight.toInt()}',
                  'reps': '${pr.reps}',
                  'date': dateLabel,
                };
              }).toList();
        } else {
          records = [];
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: QuantumColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Records Personales',
                    style: QuantumTypography.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Completa sesiones para registrar PRs',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...records.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: QuantumColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: QuantumColors.warning,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['exercise']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${r['weight']} kg × ${r['reps']} reps',
                                style: const TextStyle(
                                  color: QuantumColors.matrixCyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          r['date']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── GOAL CARD - wired to ClientBloc ──────────────────────────
  Widget _buildGoalCardWired() {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        double progress = 0.0;
        if (state is AppLoaded) {
          // Goal: 5 workouts per week
          progress = (state.workoutsThisWeek / 5.0).clamp(0.0, 1.0);
        }
        final pct = (progress * 100).toInt();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                'Meta Semanal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        QuantumColors.quantumBlue,
                      ),
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: QuantumColors.quantumBlue.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
