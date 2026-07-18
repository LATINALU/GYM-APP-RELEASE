import 'package:flutter/material.dart';
import '../src/presentation/theme/quantum_colors.dart';
import 'demo_data.dart';
import 'widgets.dart';

/// Panel demo del Dueño: KPIs, ingresos y retención con datos mock.
class DemoOwnerScreen extends StatelessWidget {
  final DemoUser user;

  const DemoOwnerScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final maxIncome = monthlyIncomeHistory
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: demoAppBar(context, title: 'PANEL DEL DUEÑO', userName: user.name),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              DemoKpiCard(
                label: 'Miembros Activos',
                value: '${ownerKpis['activeMembers']}',
                icon: Icons.people_alt_rounded,
                color: QuantumColors.matrixCyan,
              ),
              DemoKpiCard(
                label: 'Vencidos',
                value: '${ownerKpis['expiredMembers']}',
                icon: Icons.person_off_rounded,
                color: QuantumColors.error,
              ),
              DemoKpiCard(
                label: 'Ingresos del Mes',
                value:
                    '\$${(ownerKpis['monthlyIncome'] as double).toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                color: QuantumColors.quantumBlue,
              ),
              DemoKpiCard(
                label: 'Check-ins Hoy',
                value: '${ownerKpis['checkInsToday']}',
                icon: Icons.qr_code_scanner_rounded,
                color: QuantumColors.holoPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('INGRESOS · ÚLTIMOS 6 MESES'),
          const SizedBox(height: 12),
          DemoCard(
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyIncomeHistory.map((entry) {
                  final heightFactor = entry.value / maxIncome;
                  final isLast = entry == monthlyIncomeHistory.last;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FractionallySizedBox(
                              heightFactor: heightFactor * 0.85,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isLast
                                        ? [
                                            QuantumColors.quantumBlue,
                                            QuantumColors.matrixCyan,
                                          ]
                                        : [
                                            QuantumColors.quantumBlue
                                                .withValues(alpha: 0.35),
                                            QuantumColors.quantumBlue
                                                .withValues(alpha: 0.15),
                                          ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: isLast
                                  ? QuantumColors.quantumBlue
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight:
                                  isLast ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('SOCIOS EN RIESGO DE ABANDONO'),
          const SizedBox(height: 12),
          ...atRiskMembers.map((m) {
            final risk = m['risk'] as String;
            final color = risk == 'CRÍTICO'
                ? QuantumColors.error
                : risk == 'ALTO'
                    ? QuantumColors.warning
                    : Colors.orangeAccent;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DemoCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.warning_amber_rounded,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          Text('${m['daysAbsent']} días sin venir',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(risk,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const DemoSectionTitle('RESUMEN DE HOY'),
          const SizedBox(height: 12),
          DemoCard(
            child: Column(
              children: [
                _summaryRow(
                  Icons.point_of_sale_rounded,
                  'Ventas POS de hoy',
                  '\$${(ownerKpis['posToday'] as double).toStringAsFixed(0)}',
                ),
                const Divider(color: Colors.white10, height: 24),
                _summaryRow(
                  Icons.person_add_alt_1_rounded,
                  'Altas este mes',
                  '${ownerKpis['newThisMonth']} socios',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: QuantumColors.quantumBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
