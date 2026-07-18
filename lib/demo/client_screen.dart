import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../src/presentation/theme/quantum_colors.dart';
import 'demo_data.dart';
import 'widgets.dart';

/// Panel demo del Cliente: stats, plan asignado, logros y pase QR.
class DemoClientScreen extends StatelessWidget {
  final DemoUser user;

  const DemoClientScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final exercises =
        (assignedRoutine['exercises'] as List).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: demoAppBar(context, title: 'MI ENTRENAMIENTO', userName: user.name),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: DemoKpiCard(
                  label: 'Racha de días',
                  value: '${clientStats['streakDays']} 🔥',
                  icon: Icons.local_fire_department_rounded,
                  color: QuantumColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DemoKpiCard(
                  label: 'Sesiones esta semana',
                  value: '${clientStats['workoutsThisWeek']}',
                  icon: Icons.fitness_center_rounded,
                  color: QuantumColors.matrixCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DemoKpiCard(
                  label: 'Calorías hoy',
                  value: '${clientStats['caloriesToday']}',
                  icon: Icons.bolt_rounded,
                  color: QuantumColors.holoPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DemoKpiCard(
                  label: 'Volumen semanal',
                  value: '${clientStats['volumeTons']} t',
                  icon: Icons.monitor_weight_rounded,
                  color: QuantumColors.quantumBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('MI PLAN ACTIVO'),
          const SizedBox(height: 12),
          DemoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignedRoutine['name'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            QuantumColors.quantumBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        assignedRoutine['difficulty'] as String,
                        style: const TextStyle(
                            color: QuantumColors.quantumBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${assignedRoutine['duration']} min · ${exercises.length} ejercicios',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Divider(color: Colors.white10, height: 24),
                ...exercises.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: QuantumColors.quantumBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(e['name'] as String,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ),
                          Text('${e['sets']} × ${e['reps']}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: QuantumColors.quantumBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showDemoSnack(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('COMENZAR ENTRENAMIENTO',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('MIS LOGROS'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: achievements.map((a) {
              final unlocked = a['unlocked'] as bool;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: unlocked
                      ? QuantumColors.holoPurple.withValues(alpha: 0.12)
                      : QuantumColors.voidGray,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked
                        ? QuantumColors.holoPurple.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a['icon'] as String,
                        style: TextStyle(
                            fontSize: 16,
                            color: unlocked ? null : Colors.white24)),
                    const SizedBox(width: 8),
                    Text(
                      a['title'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const DemoSectionTitle('MI PASE DE ACCESO'),
          const SizedBox(height: 12),
          DemoCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: 'QUANTUM_demo-cliente-001',
                    version: QrVersions.auto,
                    size: 180,
                    gapless: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Muestra este código en recepción para tu check-in',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDemoSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: QuantumColors.voidGray,
        content: Text(
          'Demo: el entrenamiento en vivo está disponible en la app completa',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
