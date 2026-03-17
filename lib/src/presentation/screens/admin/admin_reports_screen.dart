import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Reportes Globales - Super Admin
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'Mes';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildRevenueOverview(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopGymsTable()),
                const SizedBox(width: 24),
                Expanded(child: _buildGrowthMetrics()),
              ],
            ),
            const SizedBox(height: 32),
            _buildUserMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final periods = ['Semana', 'Mes', 'Trimestre', 'Año'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REPORTES GLOBALES', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Analytics y métricas de toda la plataforma', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Row(
          children: [
            ...periods.map((p) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(p),
                selected: _selectedPeriod == p,
                onSelected: (_) => setState(() => _selectedPeriod = p),
                selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                backgroundColor: QuantumColors.surface(),
                labelStyle: TextStyle(color: _selectedPeriod == p ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 12),
                side: BorderSide(color: _selectedPeriod == p ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
              ),
            )),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Exportar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueOverview() {
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
          Text('Resumen de Ingresos', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildRevenueCard('Ingresos Totales', '\$485,600', '+12.5%', const Color(0xFF10B981))),
              const SizedBox(width: 16),
              Expanded(child: _buildRevenueCard('Suscripciones', '\$342,000', '+8.2%', const Color(0xFF6366F1))),
              const SizedBox(width: 16),
              Expanded(child: _buildRevenueCard('Servicios Extra', '\$98,400', '+22.1%', const Color(0xFF00E0FF))),
              const SizedBox(width: 16),
              Expanded(child: _buildRevenueCard('Pendiente Cobro', '\$45,200', '-3.4%', const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, String change, Color color) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isPositive ? const Color(0xFF10B981) : Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(change, style: TextStyle(color: isPositive ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              const Text(' vs periodo anterior', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopGymsTable() {
    final topGyms = [
      {'name': 'PowerHouse', 'revenue': '\$145,000', 'members': 567, 'growth': '+15%'},
      {'name': 'Titan Fitness', 'revenue': '\$98,000', 'members': 421, 'growth': '+12%'},
      {'name': 'Iron Temple', 'revenue': '\$85,000', 'members': 342, 'growth': '+8%'},
      {'name': 'FitZone Pro', 'revenue': '\$32,000', 'members': 189, 'growth': '+5%'},
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
          Text('Top Gimnasios por Ingresos', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          ...topGyms.asMap().entries.map((e) {
            final i = e.key;
            final gym = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${i + 1}', style: TextStyle(color: i == 0 ? const Color(0xFFF59E0B) : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(gym['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(gym['revenue'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(width: 16),
                  Text('${gym['members']} miembros', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(width: 16),
                  Text(gym['growth'] as String, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics() {
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
          Text('Métricas de Crecimiento', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          _buildMetricRow('Tasa de Retención', '87.3%', const Color(0xFF10B981)),
          _buildMetricRow('Churn Rate', '4.2%', Colors.redAccent),
          _buildMetricRow('NPS Score', '72', const Color(0xFF6366F1)),
          _buildMetricRow('Tiempo Promedio Sesión', '1h 23m', const Color(0xFF00E0FF)),
          _buildMetricRow('Check-ins Diarios Promedio', '1,247', const Color(0xFFF59E0B)),
          _buildMetricRow('Nuevos Registros/Semana', '147', const Color(0xFFFF6B35)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMetrics() {
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
          Text('Distribución de Usuarios', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildUserStat('Dueños', '28', Icons.business_rounded, const Color(0xFFFF6B35))),
              Expanded(child: _buildUserStat('Staff', '156', Icons.badge_rounded, const Color(0xFF6366F1))),
              Expanded(child: _buildUserStat('Clientes Activos', '3,248', Icons.people_alt_rounded, const Color(0xFF10B981))),
              Expanded(child: _buildUserStat('Clientes Inactivos', '594', Icons.person_off_rounded, Colors.white24)),
              Expanded(child: _buildUserStat('En Prueba', '98', Icons.hourglass_bottom_rounded, const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }
}
