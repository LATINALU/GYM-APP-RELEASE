import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../common/widgets/widgets.dart';
import '../../routines/routines.dart';
import '../../../infrastructure/config/di.dart';
import '../../../domain/ports/input/manage_routine_usecase_port.dart';

/// Owner Dashboard Page with navigation
class OwnerDashboardPage extends StatefulWidget {
  final VoidCallback onLogout;
  final String? userId;

  const OwnerDashboardPage({
    super.key, 
    required this.onLogout,
    this.userId,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1F2937),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _DashboardHome(
          onLogout: widget.onLogout,
          onNavigateToRoutines: () => setState(() => _currentIndex = 2),
        );
      case 1:
        return const _PlaceholderPage(
          title: 'Gestión de Usuarios',
          icon: Icons.people,
        );
      case 2:
        return BlocProvider(
          create: (_) => RoutineBloc(
            manageRoutineUseCase: getIt<ManageRoutineUseCasePort>(),
          ),
          child: RoutineManagementPage(
            userId: widget.userId ?? 'owner-1',
            onBack: () => setState(() => _currentIndex = 0),
          ),
        );
      case 3:
        return const _PlaceholderPage(
          title: 'Reportes',
          icon: Icons.bar_chart,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DashboardHome extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onNavigateToRoutines;

  const _DashboardHome({
    required this.onLogout,
    required this.onNavigateToRoutines,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Bienvenido, Admin!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aquí está el resumen de tu gimnasio',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: const [
                StatCard(title: 'Clientes', value: '0', icon: Icons.people, color: Color(0xFF6366F1)),
                StatCard(title: 'Empleados', value: '0', icon: Icons.badge, color: Color(0xFF10B981)),
                StatCard(title: 'Rutinas', value: '0', icon: Icons.fitness_center, color: Color(0xFFF59E0B)),
                StatCard(title: 'Check-ins Hoy', value: '0', icon: Icons.login, color: Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Acciones Rápidas'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add,
                    title: 'Agregar Empleado',
                    color: const Color(0xFF10B981),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.fitness_center,
                    title: 'Gestionar Rutinas',
                    color: const Color(0xFF6366F1),
                    onTap: onNavigateToRoutines,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Registrar Cliente',
                    color: const Color(0xFFF59E0B),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Escanear QR',
                    color: const Color(0xFFEC4899),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Actividad Reciente'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const EmptyStateWidget(
                icon: Icons.timeline,
                title: 'Sin actividad reciente',
                subtitle: 'La actividad del gimnasio aparecerá aquí',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
