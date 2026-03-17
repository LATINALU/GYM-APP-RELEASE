import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/services/finance_service.dart';
import '../../theme/theme.dart';
import '../../theme/gym_widgets.dart';

class FinanceSubscriptionsScreen extends StatefulWidget {
  const FinanceSubscriptionsScreen({super.key});

  @override
  State<FinanceSubscriptionsScreen> createState() =>
      _FinanceSubscriptionsScreenState();
}

class _FinanceSubscriptionsScreenState
    extends State<FinanceSubscriptionsScreen> {
  final FinanceService _financeService = FinanceService();

  String _filterStatus = 'Todos';
  bool _isLoading = true;
  String? _loadError;

  double _mrr = 0;
  double _arr = 0;
  double _delinquencyRate = 0;
  List<Map<String, double>> _monthlyRevenue = const [];
  List<Map<String, dynamic>> _payments = const [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null || gymId.trim().isEmpty) {
        throw Exception('gymId no disponible para cargar finanzas');
      }

      final mrr = await _financeService.calculateMRR(gymId: gymId);
      final arr = await _financeService.calculateARR(gymId: gymId);
      final delinquencyRate = await _financeService.getDelinquencyRate(
        gymId: gymId,
      );
      final monthlyRevenue = await _financeService.getMonthlyRevenue(
        gymId: gymId,
        months: 6,
      );
      final payments = await _financeService.getRecentPayments(
        gymId: gymId,
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _mrr = mrr;
        _arr = arr;
        _delinquencyRate = delinquencyRate;
        _monthlyRevenue = monthlyRevenue;
        _payments = payments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'No se pudieron cargar los datos financieros en este momento.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadError != null) ...[
            _buildLoadErrorBanner(),
            const SizedBox(height: 24),
          ],
          _buildHeader(),
          const SizedBox(height: 48),
          _buildKPIRow(),
          const SizedBox(height: 48),

          // Motor de Suscripciones
          _buildSubscriptionEngineStatus(),

          const SizedBox(height: 48),

          // Gráfico de ingresos mensuales
          _buildRevenueChart(),

          const SizedBox(height: 48),

          // Control de Cobros con filtros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Control de Cobros',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusFilter(),
            ],
          ),
          const SizedBox(height: 24),
          _buildPaymentsTable(),
        ],
      ),
    );
  }

  Widget _buildLoadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: _loadFinanceData,
            child: const Text('Reintentar'),
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
            const Text(
              'Finanzas & Suscripciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Automatización de cobros, facturación y control de morosidad.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        Row(
          children: [
            GymButton(
              text: 'Nuevo Cobro Manual',
              icon: Icons.add_circle_outline,
              style: GymButtonStyle.ghost,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            GymButton(
              text: 'Exportar Reporte',
              icon: Icons.file_download_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIRow() {
    final totalCollected = _payments.fold<double>(
      0,
      (sum, payment) => sum + _extractAmount(payment['amount']),
    );
    final activeCount =
        _payments
            .where(
              (payment) => _mapStatusToLabel(payment['status']) == 'Activo',
            )
            .length;
    final activeRate =
        _payments.isEmpty ? 0.0 : (activeCount / _payments.length) * 100;

    return Row(
      children: [
        _buildKPICard(
          'MRR',
          _formatCurrency(_mrr),
          'actual',
          Colors.green,
          Icons.trending_up,
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'ARR',
          _formatCurrency(_arr),
          'anual',
          Colors.blue,
          Icons.calendar_month,
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'Cobrado Este Mes',
          _formatCurrency(totalCollected),
          '${activeRate.toStringAsFixed(0)}% activo',
          Colors.purple,
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 24),
        _buildKPICard(
          'Tasa Morosidad',
          '${_delinquencyRate.toStringAsFixed(1)}%',
          _delinquencyRate <= 5 ? 'controlado' : 'alerta',
          Colors.orange,
          Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    String trend,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionEngineStatus() {
    final now = DateTime.now();

    return GymCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sync, color: Colors.green),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sincronización Automática Activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Última verificación de vencimientos: ${_formatDate(now)}',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 6),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GymButton(
            text: 'Forzar Re-escaneo',
            style: GymButtonStyle.primary,
            size: GymButtonSize.small,
            onPressed: _loadFinanceData,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenue = _monthlyRevenue;
    final monthLabels = _buildMonthLabels(revenue.length);
    final maxValue = revenue.fold<double>(0, (currentMax, item) {
      final total = (item['subscriptions'] ?? 0) + (item['pos'] ?? 0);
      return total > currentMax ? total : currentMax;
    });
    final chartMaxY = maxValue <= 0 ? 1000.0 : (maxValue * 1.25).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingresos Mensuales',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot('Suscripciones', const Color(0xFF6366F1)),
                  const SizedBox(width: 16),
                  _buildLegendDot('Ventas POS', const Color(0xFF22D3EE)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (revenue.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No hay datos de ingresos para mostrar.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= monthLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthLabels[idx],
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget:
                            (v, meta) => Text(
                              '\$${(v / 1000).toStringAsFixed(0)}K',
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 10,
                              ),
                            ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine:
                        (v) =>
                            FlLine(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(revenue.length, (index) {
                    final item = revenue[index];
                    return _makeBarGroup(
                      index,
                      item['subscriptions'] ?? 0,
                      item['pos'] ?? 0,
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double sub, double pos) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: sub + pos,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          rodStackItems: [
            BarChartRodStackItem(0, sub, const Color(0xFF6366F1)),
            BarChartRodStackItem(sub, sub + pos, const Color(0xFF22D3EE)),
          ],
          color: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterStatus,
          dropdownColor: const Color(0xFF16162A),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items:
              [
                'Todos',
                'Activo',
                'Pendiente',
                'Moroso',
                'Congelado',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _filterStatus = v ?? 'Todos'),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable() {
    final normalized = _payments.map(_normalizePayment).toList();
    final filtered =
        _filterStatus == 'Todos'
            ? normalized
            : normalized
                .where((payment) => payment['status'] == _filterStatus)
                .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _headerCell('Usuario', flex: 2),
                _headerCell('Plan'),
                _headerCell('Monto'),
                _headerCell('Próximo Cobro'),
                _headerCell('Método'),
                _headerCell('Estado'),
                _headerCell('Acciones'),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay cobros para el filtro seleccionado.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...filtered.map(
              (payment) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (payment['user'] as String).isEmpty
                                    ? '•'
                                    : (payment['user'] as String)[0]
                                        .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            payment['user'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        payment['plan'] as String,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatCurrency(payment['amount'] as double),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        payment['next'] as String,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        payment['method'] as String,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      child: StatusBadge(
                        text: payment['status'] as String,
                        type: _getStatusType(payment['status'] as String),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: Colors.white24,
                              size: 18,
                            ),
                            onPressed: () {},
                            tooltip: 'Ver Factura',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send_outlined,
                              color: Colors.white24,
                              size: 18,
                            ),
                            onPressed: () {},
                            tooltip: 'Enviar Recordatorio',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white24,
                              size: 18,
                            ),
                            onPressed: () {},
                            tooltip: 'Más Acciones',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _normalizePayment(Map<String, dynamic> raw) {
    final user = _readFirstNonEmpty(raw, const [
      'user',
      'userName',
      'memberName',
      'clientName',
    ]);
    final plan = _readFirstNonEmpty(raw, const ['plan', 'planName', 'type']);
    final method = _readFirstNonEmpty(raw, const ['method', 'paymentMethod']);

    return {
      'user': user.isEmpty ? 'Sin nombre' : user,
      'plan': plan.isEmpty ? 'N/A' : plan,
      'amount': _extractAmount(raw['amount']),
      'next': _formatNextDate(raw),
      'method': method.isEmpty ? 'N/A' : method,
      'status': _mapStatusToLabel(raw['status']),
    };
  }

  String _readFirstNonEmpty(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  List<String> _buildMonthLabels(int count) {
    const monthNames = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    if (count <= 0) return const [];

    final now = DateTime.now();
    return List.generate(count, (index) {
      final date = DateTime(now.year, now.month - (count - 1 - index));
      return monthNames[date.month - 1];
    });
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatNextDate(Map<String, dynamic> raw) {
    final date =
        _toDate(raw['nextBillingDate']) ??
        _toDate(raw['date']) ??
        _toDate(raw['createdAt']);
    if (date == null) return '—';
    return _formatDate(date);
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    try {
      final dynamicDate = (value as dynamic).toDate();
      if (dynamicDate is DateTime) return dynamicDate;
    } catch (_) {
      // Ignore non-date dynamic values
    }
    return null;
  }

  double _extractAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value
          .replaceAll(RegExp(r'[^0-9.,-]'), '')
          .replaceAll(',', '');
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _mapStatusToLabel(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'active':
      case 'activo':
        return 'Activo';
      case 'pending':
      case 'pendiente':
        return 'Pendiente';
      case 'delinquent':
      case 'moroso':
      case 'overdue':
        return 'Moroso';
      case 'frozen':
      case 'congelado':
        return 'Congelado';
      default:
        return 'Pendiente';
    }
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  StatusType _getStatusType(String status) {
    if (status == 'Activo') return StatusType.active;
    if (status == 'Pendiente') return StatusType.pending;
    if (status == 'Moroso') return StatusType.expired;
    if (status == 'Congelado') return StatusType.frozen;
    return StatusType.info;
  }
}
