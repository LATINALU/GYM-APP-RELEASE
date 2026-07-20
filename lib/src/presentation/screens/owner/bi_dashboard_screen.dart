import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/services/finance_service.dart';
import '../../../infrastructure/adapters/firebase/firebase_owner_member_repository.dart';
import '../../../infrastructure/config/di.dart';
import '../../theme/theme.dart';

/// Business Intelligence del dueño — todo con datos reales del gym:
/// ingresos (payments), MRR (subscriptions), estado de membresías y
/// cohortes de retención (gyms/{id}/members).
class BiDashboardScreen extends StatefulWidget {
  const BiDashboardScreen({super.key});

  @override
  State<BiDashboardScreen> createState() => _BiDashboardScreenState();
}

class _BiDashboardScreenState extends State<BiDashboardScreen> {
  final _finance = FinanceService();

  bool _loading = true;
  String? _error;

  List<Map<String, double>> _monthlyRevenue = const [];
  double _mrr = 0;
  List<Map<String, dynamic>> _members = const [];

  String? get _gymId => AuthStateNotifier.instance.profile?.gymId?.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gymId = _gymId;
    if (gymId == null || gymId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se pudo resolver el gimnasio de tu sesión';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _finance.getMonthlyRevenue(gymId: gymId, months: 6),
        _finance.calculateMRR(gymId: gymId),
        getIt<FirebaseOwnerMemberRepository>().loadMembers(gymId),
      ]);

      if (!mounted) return;
      setState(() {
        _monthlyRevenue = results[0] as List<Map<String, double>>;
        _mrr = results[1] as double;
        _members = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las métricas: $e';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Métricas derivadas
  // ═══════════════════════════════════════════════════════════════════

  double get _membershipIncomeThisMonth =>
      _monthlyRevenue.isEmpty ? 0 : _monthlyRevenue.last['subscriptions'] ?? 0;

  double get _posIncomeThisMonth =>
      _monthlyRevenue.isEmpty ? 0 : _monthlyRevenue.last['pos'] ?? 0;

  double get _totalIncomeThisMonth =>
      _membershipIncomeThisMonth + _posIncomeThisMonth;

  double _monthTotal(Map<String, double> m) =>
      (m['subscriptions'] ?? 0) + (m['pos'] ?? 0);

  /// Variación % vs mes anterior (null si no hay base de comparación)
  double? _trendVsPreviousMonth(double Function(Map<String, double>) selector) {
    if (_monthlyRevenue.length < 2) return null;
    final current = selector(_monthlyRevenue.last);
    final previous = selector(_monthlyRevenue[_monthlyRevenue.length - 2]);
    if (previous <= 0) return null;
    return (current - previous) / previous * 100;
  }

  int get _activeMembers =>
      _members.where((m) => m['status'] == 'Activos').length;

  int get _expiredMembers =>
      _members.where((m) => m['status'] == 'Vencidos').length;

  int get _frozenMembers => _members.where((m) => m['isFrozen'] == true).length;

  int get _newThisMonth {
    final now = DateTime.now();
    return _members.where((m) {
      final reg = m['registeredAt'] as DateTime?;
      return reg != null && reg.year == now.year && reg.month == now.month;
    }).length;
  }

  /// Cohortes por mes de alta: [label, altas, activos hoy, retención %]
  List<Map<String, dynamic>> get _cohorts {
    final now = DateTime.now();
    final cohorts = <Map<String, dynamic>>[];
    for (int i = 3; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final inCohort = _members.where((m) {
        final reg = m['registeredAt'] as DateTime?;
        return reg != null &&
            reg.year == month.year &&
            reg.month == month.month;
      }).toList();
      if (inCohort.isEmpty) continue;
      final active =
          inCohort.where((m) => m['status'] == 'Activos').length;
      cohorts.add({
        'label': _monthLabel(month),
        'total': inCohort.length,
        'active': active,
        'retention': active / inCohort.length * 100,
      });
    }
    return cohorts;
  }

  static const _monthNames = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _monthLabel(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  String _monthShort(int indexFromEnd) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month - indexFromEnd, 1);
    return _monthNames[d.month - 1];
  }

  String _money(double v) => '\$${v.toStringAsFixed(0)}';

  // ═══════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: GymColors.background,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Container(
        color: GymColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Container(
      color: GymColors.background,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildSummaryGrid(),
              const SizedBox(height: 48),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRevenueChart()),
                  const SizedBox(width: 32),
                  Expanded(child: _buildMembershipChart()),
                ],
              ),
              const SizedBox(height: 48),
              _buildRetentionTable(),
            ],
          ),
        ),
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
            const Text('Business Intelligence',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ingresos, retención y crecimiento con datos reales del gym.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: GymColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: Colors.white54, size: 20),
                  SizedBox(width: 12),
                  Text('Últimos 6 meses',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    final membershipTrend =
        _trendVsPreviousMonth((m) => m['subscriptions'] ?? 0);
    final posTrend = _trendVsPreviousMonth((m) => m['pos'] ?? 0);
    final totalTrend = _trendVsPreviousMonth(_monthTotal);
    final retention = _members.isEmpty
        ? null
        : _activeMembers / _members.length * 100;

    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard(
              'Ingresos Membresías',
              _money(_membershipIncomeThisMonth),
              trend: membershipTrend,
              subtitle: 'este mes',
              color: const Color(0xFF4ECDC4),
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'Ventas Productos',
              _money(_posIncomeThisMonth),
              trend: posTrend,
              subtitle: 'este mes',
              color: const Color(0xFFFF6B6B),
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'Total Ingresos',
              _money(_totalIncomeThisMonth),
              trend: totalTrend,
              subtitle: 'este mes',
              color: Colors.green,
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'MRR',
              _money(_mrr),
              subtitle: 'suscripciones activas',
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildMetricCard(
              'Miembros Activos',
              '$_activeMembers',
              subtitle: 'de ${_members.length} totales',
              color: Colors.blue,
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'Vencidos',
              '$_expiredMembers',
              subtitle: 'requieren renovación',
              color: Colors.orange,
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'Altas del Mes',
              '$_newThisMonth',
              subtitle: 'miembros nuevos',
              color: const Color(0xFF95E1D3),
            ),
            const SizedBox(width: 24),
            _buildMetricCard(
              'Retención Global',
              retention == null ? '—' : '${retention.toStringAsFixed(0)}%',
              subtitle: 'activos / totales',
              color: Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value, {
    double? trend,
    String? subtitle,
    required Color color,
  }) {
    return Expanded(
      child: GymCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final totals = _monthlyRevenue.map(_monthTotal).toList();
    final hasData = totals.any((t) => t > 0);

    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crecimiento de Ingresos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          SizedBox(
            height: 300,
            child: !hasData
                ? _emptyState('Aún no hay pagos registrados.\n'
                    'Los ingresos aparecerán aquí al registrar cobros.')
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: Colors.white.withValues(alpha: 0.05))),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= totals.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _monthShort(totals.length - 1 - i),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < totals.length; i++)
                              FlSpot(i.toDouble(), totals[i]),
                          ],
                          isCurved: true,
                          gradient: const LinearGradient(colors: [
                            GymColors.primary,
                            Colors.purpleAccent
                          ]),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(colors: [
                                GymColors.primary.withValues(alpha: 0.2),
                                Colors.transparent
                              ])),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipChart() {
    final active = _activeMembers;
    final expired = _expiredMembers;
    final frozen = _frozenMembers;
    final total = active + expired + frozen;

    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado de Membresías',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          SizedBox(
            height: 300,
            child: total == 0
                ? _emptyState('Sin miembros registrados aún.')
                : PieChart(
                    PieChartData(
                      sectionsSpace: 8,
                      centerSpaceRadius: 60,
                      sections: [
                        if (active > 0)
                          PieChartSectionData(
                              value: active.toDouble(),
                              color: GymColors.primary,
                              radius: 20,
                              showTitle: false),
                        if (expired > 0)
                          PieChartSectionData(
                              value: expired.toDouble(),
                              color: Colors.red,
                              radius: 20,
                              showTitle: false),
                        if (frozen > 0)
                          PieChartSectionData(
                              value: frozen.toDouble(),
                              color: Colors.orange,
                              radius: 20,
                              showTitle: false),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _buildLegendItem('Activas ($active)', GymColors.primary),
          _buildLegendItem('Vencidas ($expired)', Colors.red),
          _buildLegendItem('Congeladas ($frozen)', Colors.orange),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white12, size: 48),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRetentionTable() {
    final cohorts = _cohorts;

    return GymCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Retención por Cohortes (mes de alta)',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          if (cohorts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Sin altas registradas en los últimos 4 meses. '
                'Las cohortes se calculan con la fecha de alta de cada miembro.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            )
          else
            Table(
              columnWidths: const {0: FlexColumnWidth(2)},
              children: [
                _buildTableRow(
                    ['Cohorte', 'Altas', 'Activos hoy', 'Retención'],
                    isHeader: true),
                for (final c in cohorts)
                  _buildTableRow([
                    c['label'] as String,
                    '${c['total']}',
                    '${c['active']}',
                    '${(c['retention'] as double).toStringAsFixed(0)}%',
                  ]),
              ],
            ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells
          .map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(cell,
                    style: TextStyle(
                      color: isHeader ? Colors.white : Colors.white54,
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    )),
              ))
          .toList(),
    );
  }
}
