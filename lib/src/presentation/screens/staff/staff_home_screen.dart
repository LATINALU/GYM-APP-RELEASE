import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../domain/entities/entities.dart';

/// Staff Home Screen - Main hub for gym employees/trainers
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        if (state is Authenticated) {
          user = state.user;
        }

        return Scaffold(
          backgroundColor: QuantumColors.backgroundStart,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, user)),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                SliverToBoxAdapter(child: _buildTodayStats(context)),
                SliverToBoxAdapter(child: _buildRecentCheckIns(context)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.go('/staff/qr-scanner');
            },
            backgroundColor: QuantumColors.primary,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR'),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: QuantumColors.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${user?.name.firstName ?? "Entrenador"}',
                  style: QuantumTypography.h3.copyWith(color: Colors.white),
                ),
                Text(
                  'Panel de entrenador',
                  style: QuantumTypography.bodyMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.white70,
          ),
          IconButton(
            onPressed: () async {
              await AuthStateNotifier.instance.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.power_settings_new_rounded),
            color: Colors.redAccent.withValues(alpha: 0.7),
            tooltip: 'Cerrar Sesión',
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
            icon: Icons.qr_code_scanner,
            label: 'Escanear',
            color: QuantumColors.primary,
            onTap: () {
              context.go('/staff/qr-scanner');
            },
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            context,
            icon: Icons.fitness_center,
            label: 'Asignar Rutina',
            color: QuantumColors.success,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            context,
            icon: Icons.people,
            label: 'Clientes',
            color: QuantumColors.accent,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de Hoy',
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Check-ins', '24', Icons.login, QuantumColors.success),
              const SizedBox(width: 12),
              _buildStatCard('Rutinas', '8', Icons.fitness_center, QuantumColors.primary),
              const SizedBox(width: 12),
              _buildStatCard('Activos', '15', Icons.people, QuantumColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: QuantumTypography.h2.copyWith(color: color),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCheckIns(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-ins Recientes',
                style: QuantumTypography.h3.copyWith(color: Colors.white),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todos', style: TextStyle(color: QuantumColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: QuantumColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildCheckInItem('María García', '08:30 AM', true),
                const Divider(color: Colors.white10, height: 1),
                _buildCheckInItem('Carlos López', '09:15 AM', true),
                const Divider(color: Colors.white10, height: 1),
                _buildCheckInItem('Ana Martínez', '09:45 AM', false),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildCheckInItem(String name, String time, bool hasRoutine) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: QuantumColors.primary.withValues(alpha: 0.2),
        child: Text(
          name[0],
          style: const TextStyle(color: QuantumColors.primary),
        ),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(time, style: const TextStyle(color: Colors.white54)),
      trailing: hasRoutine
          ? const Icon(Icons.check_circle, color: QuantumColors.success)
          : TextButton(
              onPressed: () {},
              child: const Text('Asignar'),
            ),
    );
  }
}
