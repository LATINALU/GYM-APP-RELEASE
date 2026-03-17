import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../bloc/app_bloc.dart';
import '../../theme/theme.dart';
import '../../widgets/neon_widgets.dart';
import '../../../domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F12),
            body: Center(child: CircularProgressIndicator(color: QuantumColors.quantumBlue)),
          );
        }

        final user = state.user;

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildMainInfo(user),
                      const SizedBox(height: 28),
                      _buildStreakAndStats(),
                      const SizedBox(height: 20),
                      _buildMetricRow(user),
                      if (user.fitnessGoal != null) ...[
                        const SizedBox(height: 24),
                        _buildFitnessGoalSection(user),
                      ],
                      const SizedBox(height: 24),
                      _buildBodyMetricsCard(user),
                      const SizedBox(height: 24),
                      _buildGymSyncSection(context, user),
                      const SizedBox(height: 28),
                      _buildAccountSettings(context),
                      const SizedBox(height: 48),
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

  // ─── SLIVER APP BAR with Grid BG + Neon Avatar ─────────────────
  Widget _buildSliverAppBar(BuildContext context, User user) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: QuantumColors.cosmicBlack,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white.withValues(alpha: 0.5), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.5), size: 22),
          onPressed: () => context.push('/settings'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cyberpunk grid background
            CustomPaint(
              painter: GridBackgroundPainter(spacing: 36, opacity: 0.03),
            ),
            // Top gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    QuantumColors.quantumBlue.withValues(alpha: 0.03),
                    QuantumColors.cosmicBlack.withValues(alpha: 0.4),
                    QuantumColors.cosmicBlack,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Ambient glow behind avatar
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: QuantumColors.quantumBlue.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            // Neon avatar
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: NeonGlowAvatar(
                  initial: user.initials.isNotEmpty ? user.initials[0] : 'U',
                  radius: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NAME + EMAIL + ROLE BADGE ─────────────────────────────────
  Widget _buildMainInfo(User user) {
    return Column(
      children: [
        Text(
          user.displayName,
          style: QuantumTypography.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email.value,
          style: QuantumTypography.body.copyWith(color: Colors.white.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 14),
        // Role badge (neon style, NO "premium" text)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Text(
            user.role.displayName.toUpperCase(),
            style: QuantumTypography.label.copyWith(
              color: QuantumColors.quantumBlue,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ─── STREAK & WORKOUT STATS (from ClientBloc) ─────────────────
  Widget _buildStreakAndStats() {
    return Builder(
      builder: (context) {
        int streak = 0;
        int totalWorkouts = 0;
        int longestStreak = 0;
        int workoutsThisWeek = 0;

        // AppBloc may not be available if ProfileScreen is outside the shell
        try {
          final state = context.read<AppBloc>().state;
          if (state is AppLoaded) {
            streak = state.currentStreak;
            totalWorkouts = state.totalWorkouts;
            longestStreak = state.longestStreak;
            workoutsThisWeek = state.workoutsThisWeek;
          }
        } catch (_) {
          // AppBloc not available - show zeros
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatChip(
                Icons.local_fire_department_rounded,
                '$streak',
                'Racha',
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatChip(
                Icons.fitness_center_rounded,
                '$totalWorkouts',
                'Total',
                QuantumColors.quantumBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatChip(
                Icons.emoji_events_rounded,
                '$longestStreak',
                'Mejor',
                QuantumColors.matrixCyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatChip(
                Icons.calendar_today_rounded,
                '$workoutsThisWeek',
                'Semana',
                Colors.pinkAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: QuantumTypography.h4.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 9)),
        ],
      ),
    );
  }

  // ─── METRIC ROW (Weight, Height, BMI) ──────────────────────────
  Widget _buildMetricRow(User user) {
    return NeonCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricItem(
            user.weight?.toStringAsFixed(1) ?? '--',
            'kg',
            'Peso',
          ),
          _buildVerticalDivider(),
          _buildMetricItem(
            user.height?.toStringAsFixed(0) ?? '--',
            'cm',
            'Altura',
          ),
          _buildVerticalDivider(),
          _buildMetricItem(
            user.bmi?.toStringAsFixed(1) ?? '--',
            'IMC',
            'Salud',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String unit, String label) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: QuantumTypography.h3.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextSpan(
                text: ' $unit',
                style: QuantumTypography.label.copyWith(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: QuantumTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.25))),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ─── FITNESS GOAL ──────────────────────────────────────────────
  Widget _buildFitnessGoalSection(User user) {
    return NeonCard(
      hasGlow: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: QuantumColors.matrixCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.track_changes_rounded,
                color: QuantumColors.matrixCyan, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OBJETIVO ACTUAL',
                  style: QuantumTypography.label.copyWith(
                    color: QuantumColors.matrixCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.fitnessGoal ?? 'Sin objetivo definido',
                  style: QuantumTypography.body.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.15), size: 20),
        ],
      ),
    );
  }

  // ─── BODY METRICS CARD ─────────────────────────────────────────
  Widget _buildBodyMetricsCard(User user) {
    return NeonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  color: QuantumColors.quantumBlue, size: 18),
              const SizedBox(width: 10),
              Text(
                'Métricas Corporales',
                style: QuantumTypography.label.copyWith(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBodyMetricTile(
                    'Peso', '${user.weight?.toStringAsFixed(1) ?? "--"} kg',
                    Icons.scale_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBodyMetricTile(
                    'Grasa Corp.', '--%',
                    Icons.water_drop_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBodyMetricTile(
                    'Altura', '${user.height?.toStringAsFixed(0) ?? "--"} cm',
                    Icons.height_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBodyMetricTile(
                    'IMC', user.bmi?.toStringAsFixed(1) ?? '--',
                    Icons.favorite_border_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, color: QuantumColors.quantumBlue.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── GYM SYNC SECTION ─────────────────────────────────────────
  Widget _buildGymSyncSection(BuildContext context, User user) {
    final status = user.membershipStatus;
    final isPending = status == MembershipStatus.pending;

    return NeonCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_outlined,
                  color: QuantumColors.matrixCyan, size: 20),
              const SizedBox(width: 12),
              Text('Mi Gimnasio',
                  style: QuantumTypography.h4.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isPending ? 'Sincronización en proceso...' : 'Estás vinculado a:',
            style: QuantumTypography.label.copyWith(
                color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 4),
          Text(user.gymId.value,
              style: QuantumTypography.body.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 18),
          _buildStatusBadge(user),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(User user) {
    final status = user.membershipStatus;
    Color color;
    String text;
    String? subtext;
    IconData icon;

    switch (status) {
      case MembershipStatus.approved:
        if (!user.isSubscriptionActive) {
          color = Colors.orangeAccent;
          text = 'MEMBRESÍA EXPIRADA';
          subtext = 'Contacta con secretaría para renovar';
          icon = Icons.warning_amber_rounded;
        } else {
          color = QuantumColors.matrixCyan;
          text = 'ACCESO TOTAL CONFERIDO';
          final days = user.daysRemaining;
          subtext = days != null
              ? 'Quedan $days días de suscripción'
              : 'Suscripción activa';
          icon = Icons.verified_rounded;
        }
        break;
      case MembershipStatus.pending:
        color = Colors.amberAccent;
        text = 'ESPERANDO VALIDACIÓN';
        subtext = 'Tu solicitud está siendo revisada';
        icon = Icons.hourglass_top_rounded;
        break;
      case MembershipStatus.rejected:
        color = Colors.redAccent;
        text = 'ACCESO DENEGADO';
        subtext = 'Tu vinculación no ha sido aprobada';
        icon = Icons.block_flipped;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: QuantumTypography.label.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
                Text(
                  subtext,
                  style: QuantumTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACCOUNT SETTINGS ─────────────────────────────────────────
  Widget _buildAccountSettings(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          _buildActionTile(
              Icons.person_outline_rounded, 'Editar Datos Personales', () {
            context.push('/profile/edit');
          }),
          Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
          _buildActionTile(
              Icons.notifications_active_outlined, 'Notificaciones', () {
            context.push('/settings/notifications');
          }),
          Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
          _buildActionTile(Icons.security_rounded, 'Privacidad y Seguridad',
              () {
            context.push('/settings');
          }),
          Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
          _buildActionTile(Icons.logout_rounded, 'Cerrar Sesión', () {
            context.read<AuthBloc>().add(LogoutRequested());
          }, color: Colors.redAccent.withValues(alpha: 0.8)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.5), size: 20),
      title: Text(title,
          style: QuantumTypography.body.copyWith(
              color: color ?? Colors.white.withValues(alpha: 0.6), fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.white.withValues(alpha: 0.08), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      dense: true,
    );
  }
}
