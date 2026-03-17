import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Facturación & Planes - Super Admin
class AdminBillingScreen extends StatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  State<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends State<AdminBillingScreen> {
  final List<Map<String, dynamic>> _plans = [
    {'name': 'Trial', 'price': 0, 'duration': '14 días', 'gyms': 1, 'features': ['50 miembros', '1 staff', 'Dashboard básico'], 'color': const Color(0xFFF59E0B)},
    {'name': 'Básico', 'price': 999, 'duration': '/mes', 'gyms': 4, 'features': ['200 miembros', '5 staff', 'Reportes', 'POS'], 'color': const Color(0xFF6366F1)},
    {'name': 'Premium', 'price': 2499, 'duration': '/mes', 'gyms': 12, 'features': ['500 miembros', '15 staff', 'BI Dashboard', 'IA Retención', 'API'], 'color': const Color(0xFFFF6B35)},
    {'name': 'Enterprise', 'price': 4999, 'duration': '/mes', 'gyms': 8, 'features': ['Ilimitado', 'Staff ilimitado', 'Multi-sucursal', 'Soporte 24/7', 'White-label'], 'color': const Color(0xFF10B981)},
  ];

  final List<Map<String, dynamic>> _invoices = [
    {'gym': 'Iron Temple GYM', 'plan': 'Premium', 'amount': 2499, 'status': 'paid', 'date': '2025-02-01'},
    {'gym': 'PowerHouse', 'plan': 'Enterprise', 'amount': 4999, 'status': 'paid', 'date': '2025-02-01'},
    {'gym': 'FitZone Pro', 'plan': 'Básico', 'amount': 999, 'status': 'paid', 'date': '2025-02-01'},
    {'gym': 'CrossFit Arena', 'plan': 'Básico', 'amount': 999, 'status': 'overdue', 'date': '2025-01-01'},
    {'gym': 'Titan Fitness', 'plan': 'Premium', 'amount': 2499, 'status': 'paid', 'date': '2025-02-01'},
    {'gym': 'Flex Academy', 'plan': 'Trial', 'amount': 0, 'status': 'trial', 'date': '2025-01-28'},
  ];

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
            _buildPlansGrid(),
            const SizedBox(height: 40),
            _buildInvoicesTable(),
          ],
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
            Text('FACTURACIÓN & PLANES', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Gestión de planes, suscripciones y facturación', style: TextStyle(color: Colors.white38)),
          ],
        ),
        Row(
          children: [
            _buildRevenueBadge('MRR', '\$11,995', const Color(0xFF10B981)),
            const SizedBox(width: 12),
            _buildRevenueBadge('Vencido', '\$999', Colors.redAccent),
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
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlansGrid() {
    return Row(
      children: _plans.map((plan) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: plan == _plans.last ? 0 : 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: QuantumColors.surface(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (plan['color'] as Color).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(plan['name'], style: TextStyle(color: plan['color'] as Color, fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (plan['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${plan['gyms']} gyms', style: TextStyle(color: plan['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${plan['price']}', style: QuantumTypography.h1.copyWith(color: Colors.white, fontSize: 28)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(plan['duration'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(plan['features'] as List<String>).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: plan['color'] as Color, size: 14),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: plan['color'] as Color,
                    side: BorderSide(color: (plan['color'] as Color).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Editar Plan', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
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
                onPressed: () {},
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
          ..._invoices.map((inv) => _buildInvoiceRow(inv)),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Map<String, dynamic> inv) {
    final statusColor = inv['status'] == 'paid' ? const Color(0xFF10B981) : inv['status'] == 'trial' ? const Color(0xFFF59E0B) : Colors.redAccent;
    final statusLabel = inv['status'] == 'paid' ? 'Pagado' : inv['status'] == 'trial' ? 'Trial' : 'Vencido';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(inv['gym'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(child: Text(inv['plan'], style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text('\$${inv['amount']}', style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          Expanded(child: Text(inv['date'], style: const TextStyle(color: Colors.white30, fontSize: 12))),
          SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 18), onPressed: () {})),
        ],
      ),
    );
  }
}
