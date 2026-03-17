import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../bloc/app_bloc.dart';
import '../../../domain/entities/entities.dart';
import '../screens.dart';
import '../../theme/quantum_colors.dart';
import '../../widgets/holographic_navigation_bar.dart';

/// Client Home Screen - Main hub for gym clients
class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        if (state is Authenticated) {
          user = state.user;
        }

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverToBoxAdapter(child: _buildHeader(context, user)),
                // Quick Actions
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                // Today's Routine
                SliverToBoxAdapter(child: _buildTodayRoutine(context)),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                // Stats
                SliverToBoxAdapter(child: _buildStats(context)),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 100), // Espacio para bottom nav
                ),
              ],
            ),
          ),
          extendBody: true,
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            QuantumColors.quantumBlue.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: QuantumColors.holoGradient,
              boxShadow: [
                BoxShadow(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                user?.name.firstName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${user?.name.firstName ?? "Usuario"}!',
                  style: QuantumTypography.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Es hora de entrenar 💪',
                  style: QuantumTypography.bodyMedium.copyWith(
                    color: QuantumColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Notifications
          Container(
            decoration: BoxDecoration(
              color: QuantumColors.surface(opacity: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: QuantumColors.subtleBorder),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, size: 22),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionCard(
            context,
            icon: Icons.qr_code,
            label: 'Acceso QR',
            gradient: LinearGradient(
              colors: [QuantumColors.quantumBlue, QuantumColors.deepSpaceBlue],
            ),
            onTap: () {
              context.goNamed('clientQrCheckin');
            },
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            context,
            icon: Icons.analytics_outlined,
            label: 'Historial',
            gradient: LinearGradient(
              colors: [QuantumColors.holoPurple, QuantumColors.deepSpaceBlue],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorkoutCalendarScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            context,
            icon: Icons.bolt_rounded,
            label: 'Rutinas',
            gradient: LinearGradient(
              colors: [QuantumColors.matrixCyan, QuantumColors.quantumBlue],
            ),
            onTap: () {
              context.goNamed('clientRoutine');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: QuantumColors.subtleBorder),
            boxShadow: QuantumColors.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient.scale(0.1),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: QuantumColors.nebulaWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayRoutine(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        WorkoutPlan? assignedPlan;
        WorkoutDay? todayWorkout;

        if (state is AppLoaded) {
          assignedPlan = state.assignedPlan;
          todayWorkout = state.todaysWorkout;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rutina de Hoy',
                    style: QuantumTypography.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.goNamed('clientRoutine'),
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(color: QuantumColors.quantumBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: QuantumColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: QuantumColors.subtleBorder),
                  boxShadow: QuantumColors.cardShadow,
                ),
                child:
                    assignedPlan == null || todayWorkout == null
                        ? _buildNoRoutineCard()
                        : todayWorkout.isRestDay
                        ? _buildRestDayCard(todayWorkout)
                        : _buildTodayWorkoutCard(todayWorkout, assignedPlan),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoRoutineCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sin rutina activa',
          style: QuantumTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cuando tu coach te asigne un plan, lo verás aquí.',
          style: TextStyle(
            color: QuantumColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildRestDayCard(WorkoutDay todayWorkout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          todayWorkout.name,
          style: QuantumTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          todayWorkout.description ?? 'Hoy toca recuperación.',
          style: TextStyle(
            color: QuantumColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayWorkoutCard(
    WorkoutDay todayWorkout,
    WorkoutPlan assignedPlan,
  ) {
    final exercises = todayWorkout.exercises.take(3).toList();
    final remainingExercises = todayWorkout.exercises.length - exercises.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assignedPlan.name,
          style: TextStyle(
            color: QuantumColors.quantumBlue,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          todayWorkout.name,
          style: QuantumTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${todayWorkout.exerciseCount} ejercicios · ${todayWorkout.estimatedDuration} min',
          style: TextStyle(
            color: QuantumColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == exercises.length - 1 ? 0 : 8),
            child: Column(
              children: [
                _buildExerciseItem(
                  exercise.exerciseName,
                  '${exercise.targetSets} x ${exercise.targetReps}',
                  false,
                ),
                if (index != exercises.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white.withValues(alpha: 0.05)),
                  ),
              ],
            ),
          );
        }),
        if (remainingExercises > 0) ...[
          const SizedBox(height: 12),
          Text(
            '+$remainingExercises ejercicios más',
            style: TextStyle(
              color: QuantumColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseItem(String name, String sets, bool completed) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                completed
                    ? QuantumColors.success.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  completed
                      ? QuantumColors.success.withValues(alpha: 0.3)
                      : Colors.transparent,
            ),
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.fitness_center_rounded,
            color:
                completed ? QuantumColors.success : QuantumColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: completed ? QuantumColors.textSecondary : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: QuantumColors.surface(opacity: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            sets,
            style: TextStyle(
              color: QuantumColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu Progreso',
            style: QuantumTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Asistencias',
                '12',
                'este mes',
                Icons.local_fire_department_rounded,
                QuantumColors.matrixCyan,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Racha',
                '5',
                'días seguidos',
                Icons.auto_graph_rounded,
                QuantumColors.holoPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuantumColors.subtleBorder),
          boxShadow: QuantumColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  label,
                  style: TextStyle(
                    color: QuantumColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: QuantumTypography.h2.copyWith(
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: QuantumColors.success,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: QuantumColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: QuantumBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.goNamed('clientRoutine');
          if (index == 2) context.push('/profile');
        },
        items: [
          NavigationItem(icon: Icons.home_rounded, label: 'Inicio'),
          NavigationItem(icon: Icons.bolt_rounded, label: 'Rutinas'),
          NavigationItem(icon: Icons.person_rounded, label: 'Perfil'),
        ],
      ),
    );
  }
}
