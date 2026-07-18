import 'package:flutter/material.dart';
import '../src/presentation/theme/quantum_colors.dart';
import 'demo_data.dart';
import 'widgets.dart';

/// Panel demo del Empleado: check-ins del día, escáner simulado y miembros.
class DemoStaffScreen extends StatefulWidget {
  final DemoUser user;

  const DemoStaffScreen({super.key, required this.user});

  @override
  State<DemoStaffScreen> createState() => _DemoStaffScreenState();
}

class _DemoStaffScreenState extends State<DemoStaffScreen> {
  final List<Map<String, String>> _checkIns = [...todayCheckIns];
  int _nextMockMember = 0;

  static const _walkIns = [
    'Camila Torres',
    'Federico Gil',
    'Julieta Ponce',
    'Bruno Acosta',
  ];

  void _simulateScan() {
    final name = _walkIns[_nextMockMember % _walkIns.length];
    _nextMockMember++;
    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _checkIns.insert(0, {'name': name, 'time': time, 'plan': 'Mensual'});
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.voidGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: QuantumColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: QuantumColors.success, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('¡Check-in exitoso!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('$name · Membresía activa',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar',
                style: TextStyle(color: QuantumColors.quantumBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: demoAppBar(context,
          title: 'PANEL DE STAFF', userName: widget.user.name),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: QuantumColors.quantumBlue,
        foregroundColor: Colors.black,
        onPressed: _simulateScan,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Escanear QR',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: DemoKpiCard(
                  label: 'Check-ins hoy',
                  value: '${_checkIns.length + 62}',
                  icon: Icons.login_rounded,
                  color: QuantumColors.matrixCyan,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: DemoKpiCard(
                  label: 'En el gym ahora',
                  value: '23',
                  icon: Icons.directions_run_rounded,
                  color: QuantumColors.holoPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('ÚLTIMOS CHECK-INS'),
          const SizedBox(height: 12),
          ..._checkIns.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DemoCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            QuantumColors.quantumBlue.withValues(alpha: 0.12),
                        child: Text(
                          c['name']![0],
                          style: const TextStyle(
                              color: QuantumColors.quantumBlue,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('Plan ${c['plan']}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(c['time']!,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 24),
          const DemoSectionTitle('MIEMBROS'),
          const SizedBox(height: 12),
          ...gymMembers.map((m) {
            final active = m['status'] == 'Activo';
            final color =
                active ? QuantumColors.success : QuantumColors.error;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DemoCard(
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.verified_user_rounded
                          : Icons.gpp_bad_rounded,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          Text('Vence: ${m['until']}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m['status']!,
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
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
