import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../application/services/admin_metrics_service.dart';
import '../../../infrastructure/config/di.dart';
import '../../theme/quantum_colors.dart';
import '../../utils/csv_exporter.dart';

/// Reportes Globales - Super Admin
/// Agregaciones reales de payments/gyms/users de toda la plataforma.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _periods = {
    'Semana': Duration(days: 7),
    'Mes': Duration(days: 30),
    'Trimestre': Duration(days: 90),
    'Año': Duration(days: 365),
  };

  final AdminMetricsService _metricsService = getIt<AdminMetricsService>();
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

  String _selectedPeriod = 'Mes';
  bool _isLoading = true;
  String? _loadError;

  List<PlatformMonthRevenue> _monthlyRevenue = [];
  List<TopGymRevenue> _topGyms = [];
  PlatformUserDistribution? _userDistribution;
  PlatformOverview? _overview;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _periodStart =>
      DateTime.now().subtract(_periods[_selectedPeriod]!);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final monthly = await _metricsService.getPlatformMonthlyRevenue();
      final topGyms =
          await _metricsService.getTopGymsByRevenue(since: _periodStart);
      final distribution = await _metricsService.getUserDistribution();
      final overview = await _metricsService.getOverview();

      if (!mounted) return;
      setState(() {
        _monthlyRevenue = monthly;
        _topGyms = topGyms;
        _userDistribution = distribution;
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar los reportes: $e';
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
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: QuantumColors.quantumBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_loadError != null)
                    _buildErrorBanner()
                  else ...[
                    _buildRevenueOverview(),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        final topGyms = _buildTopGymsTable();
                        final growth = _buildGrowthMetrics();
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: topGyms),
                              const SizedBox(width: 24),
                              Expanded(child: growth),
                            ],
                          );
                        }
                        return Column(
                          children: [topGyms, const SizedBox(height: 24), growth],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildUserMetrics(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(_loadError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadData, child: const Text('Reintentar')),
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
            Text('REPORTES GLOBALES', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Analytics y métricas de toda la plataforma', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._periods.keys.map((p) => ChoiceChip(
                  label: Text(p),
                  selected: _selectedPeriod == p,
                  onSelected: (_) {
                    setState(() => _selectedPeriod = p);
                    _loadData();
                  },
                  selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                  backgroundColor: QuantumColors.surface(),
                  labelStyle: TextStyle(color: _selectedPeriod == p ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 12),
                  side: BorderSide(color: _selectedPeriod == p ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
                )),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _topGyms.isEmpty ? null : _exportReport,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Exportar CSV'),
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

  Future<void> _exportReport() async {
    final success = await CsvExporter.export(
      headers: ['Gimnasio', 'Ingresos'],
      rows: _topGyms.map((g) => [g.name, g.revenue.toStringAsFixed(2)]).toList(),
      filename: 'reporte_${_selectedPeriod}_${DateTime.now().toIso8601String().split('T').first}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Reporte exportado correctamente' : 'No se pudo exportar'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildRevenueOverview() {
    double total = 0, subs = 0, pos = 0;
    for (final month in _monthlyRevenue) {
      total += month.total;
      subs += month.subscriptions;
      pos += month.pos;
    }
    final currentMonth =
        _monthlyRevenue.isEmpty ? null : _monthlyRevenue.last;

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
          Text('Resumen de Ingresos (últimos 6 meses)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _buildRevenueCard('Ingresos Totales', _currencyFormat.format(total), const Color(0xFF10B981)),
                _buildRevenueCard('Suscripciones', _currencyFormat.format(subs), const Color(0xFF6366F1)),
                _buildRevenueCard('Ventas POS', _currencyFormat.format(pos), const Color(0xFF00E0FF)),
                _buildRevenueCard(
                  'Mes en Curso',
                  _currencyFormat.format(currentMonth?.total ?? 0),
                  const Color(0xFFF59E0B),
                ),
              ];
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    cards[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildMonthlyBreakdown(),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    if (_monthlyRevenue.isEmpty) {
      return const Text('Sin datos de ingresos en el período.', style: TextStyle(color: Colors.white38, fontSize: 12));
    }
    final monthFormat = DateFormat('MMM yyyy', 'es');
    final maxTotal = _monthlyRevenue
        .map((m) => m.total)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: _monthlyRevenue.map((month) {
        final ratio = maxTotal <= 0 ? 0.0 : month.total / maxTotal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  monthFormat.format(month.month),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  _currencyFormat.format(month.total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGymsTable() {
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
          Text('Top Gimnasios por Ingresos ($_selectedPeriod)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          if (_topGyms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sin pagos registrados en el período seleccionado.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            )
          else
            ..._topGyms.asMap().entries.map((e) {
              final i = e.key;
              final gym = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(color: i == 0 ? const Color(0xFFF59E0B) : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(gym.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Text(_currencyFormat.format(gym.revenue), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics() {
    final overview = _overview;
    final distribution = _userDistribution;

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
          _buildMetricRow('Gimnasios Activos', '${overview?.activeGyms ?? 0} / ${overview?.totalGyms ?? 0}', const Color(0xFF10B981)),
          _buildMetricRow('Gyms Nuevos (mes)', '+${overview?.newGymsThisMonth ?? 0}', const Color(0xFFFF6B35)),
          _buildMetricRow('Usuarios Nuevos (mes)', '+${distribution?.newUsersThisMonth ?? 0}', const Color(0xFF6366F1)),
          _buildMetricRow('Accesos últimas 24h', '${overview?.accesses24h ?? 0}', const Color(0xFF00E0FF)),
          _buildMetricRow('Ingresos del Mes', _currencyFormat.format(overview?.monthRevenue ?? 0), const Color(0xFFF59E0B)),
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
    final distribution = _userDistribution;
    if (distribution == null) return const SizedBox.shrink();

    final stats = [
      ('Dueños', '${distribution.owners}', Icons.business_rounded, const Color(0xFFFF6B35)),
      ('Staff', '${distribution.staff}', Icons.badge_rounded, const Color(0xFF6366F1)),
      ('Clientes', '${distribution.clients}', Icons.people_alt_rounded, const Color(0xFF10B981)),
      ('Admins', '${distribution.admins}', Icons.verified_user_rounded, const Color(0xFF00E0FF)),
      if (distribution.unknown > 0)
        ('Sin rol', '${distribution.unknown}', Icons.person_off_rounded, Colors.white24),
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
          Text('Distribución de Usuarios (${distribution.total} totales)', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: stats
                .map((s) => Expanded(child: _buildUserStat(s.$1, s.$2, s.$3, s.$4)))
                .toList(),
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
