import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../application/services/admin_metrics_service.dart';
import '../../../infrastructure/config/di.dart';
import '../../theme/quantum_colors.dart';

/// Dashboard Global del Super Admin
/// Muestra métricas de toda la plataforma: gimnasios, usuarios, ingresos
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _loadError;
  PlatformOverview? _overview;

  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final overview = await getIt<AdminMetricsService>().getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar las métricas globales: $e';
        _isLoading = false;
      });
    }
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
          ? const Center(child: CircularProgressIndicator(color: QuantumColors.quantumBlue))
          : RefreshIndicator(
              color: QuantumColors.quantumBlue,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    if (_loadError != null)
                      _buildErrorState()
                    else
                      _buildMetricsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 56),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();

    final cards = [
      _MetricCardData(
        label: 'Gimnasios Activos',
        value: '${overview.activeGyms}',
        detail: 'de ${overview.totalGyms} registrados',
        icon: Icons.fitness_center_rounded,
        color: QuantumColors.quantumBlue,
      ),
      _MetricCardData(
        label: 'Nuevos Gyms (mes)',
        value: '+${overview.newGymsThisMonth}',
        detail: 'este mes',
        icon: Icons.add_business_rounded,
        color: const Color(0xFFFF6B35),
      ),
      _MetricCardData(
        label: 'Usuarios Totales',
        value: '${overview.totalUsers}',
        detail: 'en toda la plataforma',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF6366F1),
      ),
      _MetricCardData(
        label: 'Ingresos del Mes',
        value: _currencyFormat.format(overview.monthRevenue),
        detail: 'suscripciones + POS',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF10B981),
      ),
      _MetricCardData(
        label: 'Accesos 24h',
        value: '${overview.accesses24h}',
        detail: 'check-ins en todos los gyms',
        icon: Icons.qr_code_scanner_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 5
            : constraints.maxWidth > 700
                ? 3
                : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.35,
          children: cards.map(_buildMetricCard).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(_MetricCardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.value,
                style: QuantumTypography.h2.copyWith(
                  color: Colors.white,
                  fontSize: 26,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.detail,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
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
            color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, color: QuantumColors.quantumBlue, size: 18),
              SizedBox(width: 8),
              Text('Super Admin', style: TextStyle(color: QuantumColors.quantumBlue, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
}
