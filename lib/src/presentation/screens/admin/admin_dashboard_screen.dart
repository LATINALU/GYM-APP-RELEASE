import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Dashboard Global del Super Admin
/// Muestra métricas de toda la plataforma: gimnasios, usuarios, ingresos
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;

  // Placeholder state
  final int _totalGyms = 24;
  final int _totalOwners = 28;
  final int _totalUsers = 3842;
  final int _activeToday = 1247;
  final double _monthlyRevenue = 485600.0;
  final double _growthRate = 12.5;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.backgroundStart.withValues(alpha: 0.5),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildUnavailableState(),
                ],
              ),
            ),
    );
  }

  Widget _buildUnavailableState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.white38,
            size: 56,
          ),
          SizedBox(height: 16),
          Text(
            'Métricas globales no disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'El dashboard global de super admin aún no está sincronizado con datos reales de la plataforma.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANEL SUPER ADMIN',
              style: QuantumTypography.h1.copyWith(
                fontSize: 36,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vista global de la plataforma GYM-APP',
              style: QuantumTypography.bodyLarge.copyWith(color: Colors.white38),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFFFF6B35), size: 18),
              SizedBox(width: 8),
              Text('Super Admin', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    return Row(
      children: [
        Expanded(child: _buildKPICard('Gimnasios Activos', '$_totalGyms', Icons.fitness_center_rounded, const Color(0xFFFF6B35), '+3 este mes')),
        const SizedBox(width: 20),
        Expanded(child: _buildKPICard('Dueños Registrados', '$_totalOwners', Icons.business_rounded, const Color(0xFF6366F1), '+5 este mes')),
        const SizedBox(width: 20),
        Expanded(child: _buildKPICard('Usuarios Totales', '$_totalUsers', Icons.people_alt_rounded, const Color(0xFF00E0FF), '+${_growthRate}%')),
        const SizedBox(width: 20),
        Expanded(child: _buildKPICard('Activos Hoy', '$_activeToday', Icons.trending_up_rounded, const Color(0xFF10B981), '32.4% del total')),
        const SizedBox(width: 20),
        Expanded(child: _buildKPICard('Ingresos Mes', '\$${(_monthlyRevenue / 1000).toStringAsFixed(1)}K', Icons.account_balance_wallet_rounded, const Color(0xFFF59E0B), '+8.2% vs anterior')),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: QuantumTypography.h1.copyWith(fontSize: 28, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRecentGymsTable() {
    final gyms = [
      {'name': 'Iron Temple GYM', 'owner': 'Carlos Mendoza', 'members': 342, 'status': 'Activo', 'plan': 'Premium'},
      {'name': 'FitZone Pro', 'owner': 'Ana García', 'members': 189, 'status': 'Activo', 'plan': 'Básico'},
      {'name': 'PowerHouse', 'owner': 'Roberto Díaz', 'members': 567, 'status': 'Activo', 'plan': 'Enterprise'},
      {'name': 'Flex Academy', 'owner': 'Laura Torres', 'members': 98, 'status': 'Prueba', 'plan': 'Trial'},
      {'name': 'Titan Fitness', 'owner': 'Miguel Ángel', 'members': 421, 'status': 'Activo', 'plan': 'Premium'},
      {'name': 'CrossFit Arena', 'owner': 'Patricia Ruiz', 'members': 234, 'status': 'Suspendido', 'plan': 'Básico'},
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gimnasios Recientes', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFFF6B35)),
                label: const Text('Ver todos', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Gimnasio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Dueño', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Miembros', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Plan', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Estado', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Table Rows
          ...gyms.map((gym) => _buildGymRow(gym)),
        ],
      ),
    );
  }

  Widget _buildGymRow(Map<String, dynamic> gym) {
    final statusColor = gym['status'] == 'Activo'
        ? const Color(0xFF10B981)
        : gym['status'] == 'Prueba'
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B35), size: 16),
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(gym['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(gym['owner'], style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text('${gym['members']}', style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(gym['plan'], style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(gym['status'], style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlerts() {
    final alerts = [
      {'title': 'CrossFit Arena - Pago vencido', 'time': 'Hace 2h', 'type': 'error'},
      {'title': 'Flex Academy - Periodo de prueba termina en 3 días', 'time': 'Hace 5h', 'type': 'warning'},
      {'title': 'Nuevo gimnasio registrado: Titan Fitness', 'time': 'Hace 1d', 'type': 'info'},
      {'title': 'PowerHouse alcanzó 500+ miembros', 'time': 'Hace 2d', 'type': 'success'},
      {'title': 'Actualización de sistema disponible v2.1', 'time': 'Hace 3d', 'type': 'info'},
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alertas del Sistema', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${alerts.length}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...alerts.map((alert) => _buildAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, String> alert) {
    final color = alert['type'] == 'error'
        ? Colors.redAccent
        : alert['type'] == 'warning'
            ? const Color(0xFFF59E0B)
            : alert['type'] == 'success'
                ? const Color(0xFF10B981)
                : const Color(0xFF6366F1);

    final icon = alert['type'] == 'error'
        ? Icons.error_outline_rounded
        : alert['type'] == 'warning'
            ? Icons.warning_amber_rounded
            : alert['type'] == 'success'
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['title']!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(alert['time']!, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformActivity() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actividad de la Plataforma (Últimos 7 días)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildActivityStat('Registros Nuevos', '147', const Color(0xFF10B981))),
              Expanded(child: _buildActivityStat('Check-ins', '8,432', const Color(0xFF6366F1))),
              Expanded(child: _buildActivityStat('Rutinas Creadas', '89', const Color(0xFF00E0FF))),
              Expanded(child: _buildActivityStat('Pagos Procesados', '312', const Color(0xFFF59E0B))),
              Expanded(child: _buildActivityStat('Tickets Soporte', '23', Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: QuantumTypography.h2.copyWith(color: color, fontSize: 28)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
