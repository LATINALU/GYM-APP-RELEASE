import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/check_in_repository_port.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/config/di.dart';

/// Staff Home Screen - Main hub for gym employees/trainers
class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  List<CheckIn> _todayCheckIns = [];
  int _activeClients = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final checkInRepo = getIt<CheckInRepositoryPort>();
      final result = await checkInRepo.findToday();

      result.fold(
        (_) => null,
        (checkIns) {
          if (mounted) {
            setState(() {
              _todayCheckIns = checkIns;
              _isLoadingStats = false;
            });
          }
        },
      );

      // Load active clients count
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId;
      if (gymId != null) {
        final userRepo = getIt<UserRepositoryPort>();
        final clientsResult = await userRepo.findByRole(
          gymId: gymId,
          role: const GymRole.client(),
        );
        clientsResult.fold(
          (_) => null,
          (clients) {
            if (mounted) {
              setState(() {
                _activeClients = clients.where((c) =>
                  c.membershipStatus == MembershipStatus.approved).length;
              });
            }
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

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
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: QuantumColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, user)),
                  SliverToBoxAdapter(child: _buildQuickActions(context)),
                  SliverToBoxAdapter(child: _buildTodayStats(context)),
                  SliverToBoxAdapter(child: _buildRecentCheckIns(context)),
                ],
              ),
            ),
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
            onPressed: () => context.push('/client/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.white70,
            tooltip: 'Notificaciones',
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
            onTap: () => context.go('/staff/routine-management'),
          ),
          const SizedBox(width: 12),
          _buildActionCard(
            context,
            icon: Icons.people,
            label: 'Clientes',
            color: QuantumColors.accent,
            onTap: () => _showClientList(context),
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
              _buildStatCard('Check-ins', '${_todayCheckIns.length}', Icons.login, QuantumColors.success),
              const SizedBox(width: 12),
              _buildStatCard('Activos', '$_activeClients', Icons.people, QuantumColors.accent),
              const SizedBox(width: 12),
              _buildStatCard('En gym', '${_todayCheckIns.where((c) => c.isActive).length}', Icons.timer, QuantumColors.primary),
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
    final recent = _todayCheckIns.take(5).toList();

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
                onPressed: () => context.push('/owner/access-console'),
                child: const Text('Ver todos', style: TextStyle(color: QuantumColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: QuantumColors.primary)),
            )
          else if (recent.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: QuantumColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Center(
                child: Text('Sin check-ins hoy', style: TextStyle(color: Colors.white38)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: QuantumColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < recent.length; i++) ...[
                    _buildCheckInItem(context, recent[i]),
                    if (i < recent.length - 1)
                      const Divider(color: Colors.white10, height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 120), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildCheckInItem(BuildContext context, CheckIn checkIn) {
    final timeStr = '${checkIn.checkInTime.hour.toString().padLeft(2, '0')}:${checkIn.checkInTime.minute.toString().padLeft(2, '0')}';
    final isActive = checkIn.isActive;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: QuantumColors.primary.withValues(alpha: 0.2),
        child: Text(
          checkIn.clientId.value.isNotEmpty ? checkIn.clientId.value[0].toUpperCase() : '?',
          style: const TextStyle(color: QuantumColors.primary),
        ),
      ),
      title: Text(checkIn.clientId.value, style: const TextStyle(color: Colors.white)),
      subtitle: Text(timeStr, style: const TextStyle(color: Colors.white54)),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: QuantumColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('En gym', style: TextStyle(color: QuantumColors.success, fontSize: 11)),
            )
          : TextButton(
              onPressed: () => context.go('/staff/routine-management'),
              child: const Text('Asignar'),
            ),
    );
  }

  Future<void> _showClientList(BuildContext context) async {
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId;
    if (gymId == null) return;

    final userRepo = getIt<UserRepositoryPort>();
    final result = await userRepo.findByRole(
      gymId: gymId,
      role: const GymRole.client(),
    );

    if (!mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: QuantumColors.error),
      ),
      (clients) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: QuantumColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Clientes (${clients.length})', style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: clients.isEmpty
                ? const Text('No hay clientes registrados', style: TextStyle(color: Colors.white54))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: clients.length,
                    itemBuilder: (_, i) {
                      final c = clients[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: QuantumColors.accent.withValues(alpha: 0.2),
                          child: Text(c.name.firstName[0], style: const TextStyle(color: QuantumColors.accent)),
                        ),
                        title: Text(c.name.fullName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          c.membershipStatus == MembershipStatus.approved ? 'Activo' : 'Pendiente',
                          style: TextStyle(color: c.membershipStatus == MembershipStatus.approved ? QuantumColors.success : QuantumColors.warning, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.fitness_center, color: QuantumColors.primary, size: 20),
                          tooltip: 'Asignar rutina',
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/staff/routine-management');
                          },
                        ),
                      );
                    },
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      },
    );
  }
}
