import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'access_console_screen.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../infrastructure/config/di.dart';
import '../../../infrastructure/adapters/firebase/firebase_owner_member_repository.dart';

import '../../theme/quantum_colors.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isPrivate = false;
  bool _isLoading = true;

  // Real KPI data (loaded from Firestore)
  int _activeMemberships = 0;
  double _monthlyRevenue = 0;
  int _accesses24h = 0;
  double _churnRate = 0;
  final String _peakHour = '18:00h';

  @override
  void initState() {
    super.initState();
    _loadKPIs();
  }

  Future<void> _loadKPIs() async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;

      if (gymId == null || gymId.trim().isEmpty) {
        throw Exception('gymId no disponible para cargar KPIs');
      }

      final kpis = await getIt<FirebaseOwnerMemberRepository>().loadDashboardKPIs(gymId);

      if (mounted) {
        final totalMembers = kpis['totalMembers'] as int;
        final expired = kpis['expiredMembers'] as int;

        setState(() {
          _activeMemberships = kpis['activeMemberships'] as int;
          _monthlyRevenue = kpis['monthlyRevenue'] as double;
          _accesses24h = kpis['accesses24h'] as int;
          _churnRate = totalMembers > 0 ? (expired / totalMembers * 100) : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeMemberships = 0;
          _monthlyRevenue = 0;
          _accesses24h = 0;
          _churnRate = 0;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar KPIs: $e'),
            backgroundColor: QuantumColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      child: RefreshIndicator(
        color: QuantumColors.quantumBlue,
        onRefresh: _loadKPIs,
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 48),

            _buildKPIsGrid(),

            const SizedBox(height: 48),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildMainAnalytics(),
                      const SizedBox(height: 32),
                      _buildAIPredictiveSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      _buildQuickActionsHeader(),
                      const SizedBox(height: 24),
                      _buildQuickActionsColumn(context),
                      const SizedBox(height: 32),
                      _buildAccessConsoleContainer(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GYM-APP COMMAND CENTER',
              style: QuantumTypography.h1.copyWith(
                fontSize: 36,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: QuantumColors.matrixCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gaia AI Engine: Online & Monitoring',
                  style: QuantumTypography.caption.copyWith(
                    color: QuantumColors.matrixCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildTopBarActions(),
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildTopBarActions() {
    return Row(
      children: [
        IconButton(
          onPressed: () => setState(() => _isPrivate = !_isPrivate),
          icon: Icon(
            _isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: Colors.white38,
          ),
          tooltip: 'Modo Privado',
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.hub_rounded,
                color: QuantumColors.quantumBlue,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'HQ - CENTRAL HUB',
                style: QuantumTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIsGrid() {
    final revenueStr =
        _isPrivate
            ? '••••••'
            : '\$${_monthlyRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    final churnStr = '${_churnRate.toStringAsFixed(1)}%';
    return Row(
      children: [
        _buildKPICard(
          'MEMBRESÍAS ACTIVAS',
          _isLoading ? '...' : '$_activeMemberships',
          Icons.people_outline_rounded,
          QuantumColors.quantumBlue,
          '+12% este mes',
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'INGRESOS (MENSUAL)',
          _isLoading ? '...' : revenueStr,
          Icons.account_balance_wallet_rounded,
          QuantumColors.matrixCyan,
          'Proyección: \$22K',
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'ACCESOS (24H)',
          _isLoading ? '...' : '$_accesses24h',
          Icons.sensors_rounded,
          Colors.orangeAccent,
          'Pico: $_peakHour',
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'CHURN RISK (IA)',
          _isLoading ? '...' : churnStr,
          Icons.heart_broken_rounded,
          Colors.redAccent,
          _churnRate < 5 ? 'Nivel Saludable' : 'Requiere Atención',
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String footer,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: QuantumColors.surface(),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Icon(Icons.more_vert_rounded, color: Colors.white10),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: QuantumTypography.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: QuantumTypography.caption.copyWith(
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Text(
              footer,
              style: QuantumTypography.caption.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainAnalytics() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FLUJO DE TRAFICO & RENDIMIENTO',
                style: QuantumTypography.h3,
              ),
              const Spacer(),
              _buildChartFilter(),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(child: LineChart(_getTrafficChartData())),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  LineChartData _getTrafficChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine:
            (v) => FlLine(color: Colors.white.withValues(alpha: 0.03)),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) => const SizedBox(),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            const FlSpot(0, 310),
            const FlSpot(1, 420),
            const FlSpot(2, 380),
            const FlSpot(3, 500),
            const FlSpot(4, 450),
            const FlSpot(5, 520),
            const FlSpot(6, 480),
          ],
          isCurved: true,
          color: QuantumColors.quantumBlue,
          barWidth: 6,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                QuantumColors.quantumBlue.withValues(alpha: 0.2),
                QuantumColors.quantumBlue.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIPredictiveSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QuantumColors.quantumBlue.withValues(alpha: 0.1),
            QuantumColors.matrixCyan.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: QuantumColors.matrixCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: QuantumColors.matrixCyan,
              ),
              const SizedBox(width: 16),
              Text(
                'GAIA AI: INSIGHTS DE RETENCIÓN',
                style: QuantumTypography.h3,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAIInsightTile(
            '12 Miembros en riesgo de abandono detectados esta semana.',
            'ALTA PRIORIDAD',
            Colors.redAccent,
          ),
          _buildAIInsightTile(
            'El horario de 17h a 19h operará al 95% de capacidad hoy.',
            'AVISO DE GESTIÓN',
            Colors.orangeAccent,
          ),
          _buildAIInsightTile(
            'Crecimiento del 5% en suscripciones Premium proyectado.',
            'CRECIMIENTO',
            QuantumColors.matrixCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightTile(String text, String tag, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tagColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: QuantumTypography.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('ACCIONES RÁPIDAS', style: QuantumTypography.h3),
        const Icon(
          Icons.bolt_rounded,
          color: QuantumColors.matrixCyan,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildQuickActionsColumn(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(
          context,
          'Alta de Miembro',
          'Wizard de registro avanzado',
          Icons.person_add_rounded,
          () => context.go('/owner/add-member'),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          'Punto de Venta',
          'Venta interna y stock',
          Icons.shopping_cart_rounded,
          () => context.go('/owner/pos'),
          highlight: true,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          'Constructor Rutinas',
          'Diseño de entrenamientos Pro',
          Icons.architecture_rounded,
          () => context.go('/owner/routine-builder'),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          'Conciliación Caja',
          'Cierre diario de ingresos',
          Icons.account_balance_wallet_rounded,
          () => context.go('/owner/cash-close'),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                highlight
                    ? QuantumColors.quantumBlue.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  highlight
                      ? QuantumColors.quantumBlue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: highlight ? QuantumColors.quantumBlue : Colors.white24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      sub,
                      style: QuantumTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white10,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessConsoleContainer() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: const AccessConsoleScreen(),
      ),
    );
  }

  Widget _buildChartFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'ÚLTIMOS 7 DÍAS',
            style: QuantumTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
            size: 16,
          ),
        ],
      ),
    );
  }
}
