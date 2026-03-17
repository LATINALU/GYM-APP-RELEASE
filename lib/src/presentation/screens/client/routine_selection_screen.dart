import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/theme.dart';
import '../../bloc/app_bloc.dart';
import '../../../domain/entities/workout_plan.dart';

class RoutineSelectionScreen extends StatelessWidget {
  const RoutineSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, appState) {
        // Get assigned plan from unified AppBloc
        WorkoutPlan? assignedPlan;
        if (appState is AppLoaded) {
          assignedPlan = appState.assignedPlan;
        }

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (assignedPlan != null)
                      _buildActiveRoutineSection(context, assignedPlan)
                    else
                      _buildNoPlanSection(context),

                    const SizedBox(height: 48),
                    _buildSectionHeader('DESCUBRIR PLANES'),
                    const SizedBox(height: 24),
                    _buildRoutineCatalog(context),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPlanSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: QuantumColors.quantumBlue.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            'SIN PLAN ACTIVO',
            style: QuantumTypography.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta con tu coach o elige un plan del catálogo para empezar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'ENTRENAMIENTO',
          style: QuantumTypography.h4.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        background: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      QuantumColors.quantumBlue.withValues(alpha: 0.1),
                      QuantumColors.cosmicBlack,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRoutineSection(BuildContext context, WorkoutPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TU PLAN ACTUAL'),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.pushNamed('clientDailyWorkout'),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: QuantumColors.quantumBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${plan.daysPerWeek} DÍAS / SEMANA',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.name.toUpperCase(),
                    style: QuantumTypography.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: QuantumTypography.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: QuantumColors.quantumBlue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CONTINUAR SESIÓN',
                        style: TextStyle(
                          color: QuantumColors.quantumBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: QuantumTypography.label.copyWith(
        letterSpacing: 2,
        color: QuantumColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRoutineCatalog(BuildContext context) {
    final catalog = [
      {
        'title': 'PPL: PUSH PULL LEGS',
        'image':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=2070',
        'diff': 'INTERMEDIO',
        'color': QuantumColors.quantumBlue,
      },
      {
        'title': 'FULL BODY TOTAL',
        'image':
            'https://images.unsplash.com/photo-1594381898411-846e7d193883?q=80&w=2070',
        'diff': 'PRINCIPIANTE',
        'color': QuantumColors.matrixCyan,
      },
      {
        'title': 'POWERLIFTING 101',
        'image':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=2070',
        'diff': 'EXPERTO',
        'color': Colors.redAccent,
      },
    ];

    return Column(
      children:
          catalog.map((item) => _buildCatalogItem(context, item)).toList(),
    );
  }

  Widget _buildCatalogItem(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 160,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(item['image'], fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (item['color'] as Color).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      item['diff'],
                      style: TextStyle(
                        color: item['color'],
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'],
                    style: QuantumTypography.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explorar estructura del plan →',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.pushNamed('clientDailyWorkout'),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
