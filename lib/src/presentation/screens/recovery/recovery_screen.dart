import 'package:flutter/material.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/services/recovery_service.dart';
import '../../../infrastructure/config/di.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _svc = getIt<RecoveryService>();
  Map<String, dynamic> _r = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = AuthStateNotifier.instance.profile?.uid;
    _r = uid != null ? await _svc.getReadiness(uid) : {};
    if (mounted) setState(() => _loading = false);
  }

  Color _scoreColor(double s) =>
      s >= 80 ? const Color(0xFF4ECDC4) : s >= 60 ? const Color(0xFFFFE66D) : s >= 40 ? const Color(0xFFFF9F43) : const Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF0A0A0F), body: Center(child: CircularProgressIndicator()));
    final score = (_r['score'] as num?)?.toDouble() ?? 0;
    final clr = _scoreColor(score);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(slivers: [
        const SliverAppBar(expandedHeight: 80, backgroundColor: Color(0xFF0A0A0F), pinned: true,
          flexibleSpace: FlexibleSpaceBar(title: Text('Recuperación', style: TextStyle(fontWeight: FontWeight.w700)))),
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [clr.withValues(alpha: 0.15), const Color(0xFF12121A)]),
            borderRadius: BorderRadius.circular(28), border: Border.all(color: clr.withValues(alpha: 0.25))),
          child: Column(children: [
            SizedBox(height: 160, width: 160, child: Stack(alignment: Alignment.center, children: [
              SizedBox(height: 160, width: 160, child: CircularProgressIndicator(
                value: (score / 100).clamp(0, 1), strokeWidth: 14, backgroundColor: Colors.white10, color: clr, strokeCap: StrokeCap.round)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${score.toInt()}', style: TextStyle(color: clr, fontSize: 48, fontWeight: FontWeight.w900)),
                Text(_r['status'] ?? '', style: TextStyle(color: clr.withValues(alpha: 0.8), fontSize: 14)),
              ]),
            ])),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_r['shouldRest'] == true ? Icons.cancel : Icons.check_circle, color: clr, size: 20),
              const SizedBox(width: 8),
              Text(_r['shouldRest'] == true ? 'DESCANSO' : 'LISTO', style: TextStyle(color: clr, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ]),
          ]),
        )),
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFFFFE66D), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(_r['recommendation']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14))),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Wrap(spacing: 12, runSpacing: 12, children: [
          _tile('Sueño', '${_r['sleepHours'] ?? 0}h', Icons.bedtime, const Color(0xFF6C63FF)),
          _tile('Hidratación', '${_r['hydration'] ?? 0}L', Icons.water_drop, const Color(0xFF4ECDC4)),
          _tile('Estrés', '${_r['stress'] ?? 0}/10', Icons.psychology, const Color(0xFFFF6B6B)),
          _tile('Energía', '${_r['energy'] ?? 0}/10', Icons.bolt, const Color(0xFFFFE66D)),
          _tile('Prom. 7d', '${(_r['avgWeekScore'] ?? 0).toStringAsFixed(0)}%', Icons.analytics, const Color(0xFF95E1D3)),
          _tile('Intensidad', _r['shouldTrainHeavy'] == true ? 'Alta ✓' : 'Baja', Icons.fitness_center, const Color(0xFFAA96DA)),
        ]))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: _checkIn, icon: const Icon(Icons.add_circle_outline),
            label: const Text('Check-In Hoy', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ECDC4), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))))),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ]),
    );
  }

  Widget _tile(String l, String v, IconData ic, Color c) => Container(
    width: (MediaQuery.of(context).size.width - 52) / 2, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.12))),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(ic, color: c, size: 18)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(l, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    ]),
  );

  void _checkIn() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E), isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Check-In', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('¿Cómo te sientes hoy?', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, children: ['😴 Agotado', '😐 Normal', '💪 Energético', '🔥 Imparable'].map((e) =>
            ActionChip(label: Text(e), backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              labelStyle: const TextStyle(color: Colors.white), onPressed: () {
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrado ✓'), backgroundColor: Color(0xFF4ECDC4)));
              })).toList()),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
