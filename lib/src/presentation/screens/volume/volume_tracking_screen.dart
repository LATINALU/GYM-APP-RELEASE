import 'package:flutter/material.dart';
import '../../../application/services/volume_tracking_service.dart';
import '../../../domain/entities/muscle_volume.dart';
import '../../../infrastructure/config/di.dart';

class VolumeTrackingScreen extends StatefulWidget {
  const VolumeTrackingScreen({super.key});
  @override
  State<VolumeTrackingScreen> createState() => _VolumeTrackingScreenState();
}

class _VolumeTrackingScreenState extends State<VolumeTrackingScreen> {
  final _svc = getIt<VolumeTrackingService>();
  Map<String, dynamic> _dist = {};
  Map<String, dynamic> _comparison = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _dist = await _svc.getDistribution('current-user');
    _comparison = await _svc.compareWeeks('current-user');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator()),
      );
    final volumes = (_dist['volumes'] as Map<String, dynamic>?) ?? {};
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: _showLogSet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 80,
            backgroundColor: Color(0xFF0A0A0F),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Volumen Muscular',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ),
          // Summary cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _statCard(
                    'Volumen Total',
                    '${((_dist['totalVolume'] ?? 0) as num).toStringAsFixed(0)} kg',
                    Icons.fitness_center,
                    const Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'Sets Totales',
                    '${_dist['totalSets'] ?? 0}',
                    Icons.repeat,
                    const Color(0xFF4ECDC4),
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'Cambio',
                    _comparison['hasComparison'] == true
                        ? '${((_comparison['changePercent'] ?? 0) as num).toStringAsFixed(1)}%'
                        : 'N/A',
                    Icons.trending_up,
                    _comparison['changePercent'] != null &&
                            (_comparison['changePercent'] as num) > 0
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFFF6B6B),
                  ),
                ],
              ),
            ),
          ),
          // Undertrained warning
          if ((_dist['undertrained'] as List?)?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Color(0xFFFF6B6B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Músculos sub-entrenados: ${(_dist['undertrained'] as List).join(', ')}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Muscle breakdown
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Desglose por Músculo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              final entry = volumes.entries.elementAt(i);
              final data = entry.value as Map<String, dynamic>;
              final vol = (data['volume'] as num?)?.toDouble() ?? 0;
              final maxVol = volumes.values.fold<double>(0, (m, v) {
                final vv =
                    ((v as Map<String, dynamic>)['volume'] as num?)
                        ?.toDouble() ??
                    0;
                return vv > m ? vv : m;
              });
              final muscle = MuscleGroup.values.firstWhere(
                (e) => e.displayName == entry.key,
                orElse: () => MuscleGroup.other,
              );
              final clr = Color(
                int.parse(muscle.colorHex.replaceFirst('#', '0xFF')),
              );
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: clr.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: clr,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${data['sets']} sets · ${data['reps']} reps',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxVol > 0 ? vol / maxVol : 0,
                              backgroundColor: Colors.white10,
                              color: clr,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${vol.toStringAsFixed(0)} kg',
                          style: TextStyle(
                            color: clr,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (data['maxWeight'] != null &&
                        (data['maxWeight'] as num) > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Max: ${(data['maxWeight'] as num).toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }, childCount: volumes.length),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String val, IconData ic, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ic, color: c, size: 18),
          const SizedBox(height: 8),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  void _showLogSet() {
    MuscleGroup selected = MuscleGroup.chest;
    final repsC = TextEditingController(text: '10');
    final weightC = TextEditingController(text: '80');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, ss) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Set',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            MuscleGroup.values
                                .where((m) => m != MuscleGroup.other)
                                .map((m) {
                                  final c = Color(
                                    int.parse(
                                      m.colorHex.replaceFirst('#', '0xFF'),
                                    ),
                                  );
                                  return ChoiceChip(
                                    label: Text(m.displayName),
                                    selected: selected == m,
                                    selectedColor: c.withValues(alpha: 0.3),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    labelStyle: TextStyle(
                                      color: selected == m ? c : Colors.white54,
                                      fontSize: 12,
                                    ),
                                    onSelected: (_) => ss(() => selected = m),
                                  );
                                })
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: repsC,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Reps',
                                labelStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: weightC,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Peso (kg)',
                                labelStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _svc.logSet(
                                userId: 'current-user',
                                muscle: selected,
                                reps: int.tryParse(repsC.text) ?? 10,
                                weightKg: double.tryParse(weightC.text) ?? 0,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _load();
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se pudo registrar el set. Intenta nuevamente.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Registrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
