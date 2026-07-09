import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../application/services/admin_metrics_service.dart';
import '../../../infrastructure/config/di.dart';
import '../../theme/quantum_colors.dart';
import '../../utils/csv_exporter.dart';

/// Facturación & Planes - Super Admin
/// Lee planes y facturas reales de Firestore (platform_plans / platform_invoices).
class AdminBillingScreen extends StatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  State<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends State<AdminBillingScreen> {
  final AdminMetricsService _metricsService = getIt<AdminMetricsService>();
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _loadError;
  List<PlatformPlan> _plans = [];
  List<PlatformInvoice> _invoices = [];
  PlatformBillingSummary? _summary;

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
      // Primera vez: siembra los planes por defecto si la colección está vacía.
      await _metricsService.ensureDefaultPlans();

      final plans = await _metricsService.getPlans();
      final invoices = await _metricsService.getRecentInvoices();
      final summary = await _metricsService.getBillingSummary(
        plans: plans,
        invoices: invoices,
      );

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _invoices = invoices;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudo cargar la facturación: $e';
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
                    const SizedBox(height: 32),
                    if (_loadError != null)
                      _buildErrorBanner()
                    else ...[
                      _buildPlansGrid(),
                      const SizedBox(height: 40),
                      _buildInvoicesTable(),
                    ],
                  ],
                ),
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
    final summary = _summary;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FACTURACIÓN & PLANES', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Gestión de planes, suscripciones y facturación', style: TextStyle(color: Colors.white38)),
          ],
        ),
        if (summary != null)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildRevenueBadge('MRR', _currencyFormat.format(summary.mrr), const Color(0xFF10B981)),
              _buildRevenueBadge('Vencido', _currencyFormat.format(summary.overdueAmount), Colors.redAccent),
            ],
          ),
      ],
    );
  }

  Widget _buildRevenueBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlansGrid() {
    if (_plans.isEmpty) {
      return const Text('No hay planes configurados.', style: TextStyle(color: Colors.white54));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 640 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 1.6 : 0.95,
          children: _plans.map(_buildPlanCard).toList(),
        );
      },
    );
  }

  Widget _buildPlanCard(PlatformPlan plan) {
    final color = Color(plan.colorValue);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.maxMembers == 0 ? 'Ilimitado' : '${plan.maxMembers} socios',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currencyFormat.format(plan.price),
                    style: QuantumTypography.h1.copyWith(color: Colors.white, fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('/mes', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: plan.features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: color, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(color: Colors.white60, fontSize: 12))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditPlanDialog(context, plan),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Editar Plan', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTable() {
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
              Text('Facturas Recientes', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: _invoices.isEmpty ? null : _exportInvoices,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white60,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aún no hay facturas emitidas. Se generarán cuando los gimnasios tengan un plan asignado.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Gimnasio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Plan', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Monto', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Estado', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Fecha', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            ..._invoices.map(_buildInvoiceRow),
          ],
        ],
      ),
    );
  }

  Future<void> _exportInvoices() async {
    final success = await CsvExporter.export(
      headers: ['Gimnasio', 'Plan', 'Monto', 'Estado', 'Fecha'],
      rows: _invoices
          .map((inv) => [
                inv.gymName,
                inv.planName,
                inv.amount,
                inv.status,
                _dateFormat.format(inv.date),
              ])
          .toList(),
      filename: 'facturas_${DateTime.now().toIso8601String().split('T').first}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Facturas exportadas correctamente' : 'No se pudo exportar'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildInvoiceRow(PlatformInvoice inv) {
    final statusColor = inv.status == 'paid'
        ? const Color(0xFF10B981)
        : inv.status == 'trial'
            ? const Color(0xFFF59E0B)
            : Colors.redAccent;
    final statusLabel = inv.status == 'paid'
        ? 'Pagado'
        : inv.status == 'trial'
            ? 'Trial'
            : 'Vencido';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(inv.gymName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(child: Text(inv.planName, style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text(_currencyFormat.format(inv.amount), style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          Expanded(child: Text(_dateFormat.format(inv.date), style: const TextStyle(color: Colors.white30, fontSize: 12))),
          SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 18), onPressed: () => _showInvoiceDetail(context, inv))),
        ],
      ),
    );
  }

  void _showEditPlanDialog(BuildContext context, PlatformPlan plan) {
    final color = Color(plan.colorValue);
    final nameCtrl = TextEditingController(text: plan.name);
    final priceCtrl = TextEditingController(text: plan.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar ${plan.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio', labelStyle: TextStyle(color: Colors.white38), prefixText: r'$ '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newName = nameCtrl.text.trim();
              final newPrice = double.tryParse(priceCtrl.text.trim());
              try {
                await _metricsService.savePlan(
                  plan.copyWith(
                    name: newName.isEmpty ? null : newName,
                    price: newPrice,
                  ),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Plan ${plan.name} actualizado'), backgroundColor: color),
                );
                await _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context, PlatformInvoice inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detalle de Factura', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Gimnasio', inv.gymName),
            _detailRow('Plan', inv.planName),
            _detailRow('Monto', _currencyFormat.format(inv.amount)),
            _detailRow('Estado', inv.status),
            _detailRow('Fecha', _dateFormat.format(inv.date)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
