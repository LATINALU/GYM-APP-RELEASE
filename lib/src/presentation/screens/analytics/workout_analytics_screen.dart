import 'package:flutter/material.dart';
import '../../../application/services/workout_analysis_service.dart';

class WorkoutAnalyticsScreen extends StatefulWidget {
  const WorkoutAnalyticsScreen({super.key});
  @override
  State<WorkoutAnalyticsScreen> createState() => _WorkoutAnalyticsScreenState();
}

class _WorkoutAnalyticsScreenState extends State<WorkoutAnalyticsScreen> {
  final _svc = WorkoutAnalysisService();
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _prs = [];
  Map<String, int> _frequency = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final analytics = await _svc.getAnalytics('current-user');
      final prs = await _svc.getPersonalRecords('current-user');
      final frequency = await _svc.getFrequencyByDay('current-user');
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _prs = prs;
        _frequency = frequency;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analytics = {
          'totalWorkouts': 0,
          'totalHours': 0.0,
          'currentStreak': 0,
          'consistencyScore': 0,
          'totalVolume': 0.0,
          'avgDuration': 0.0,
          'mostTrainedMuscle': 'Sin datos',
          'leastTrainedMuscle': 'Sin datos',
          'favoriteExercise': 'Sin datos',
          'improvementRate': 0.0,
        };
        _prs = const [];
        _frequency = {
          'Lun': 0,
          'Mar': 0,
          'Mié': 0,
          'Jue': 0,
          'Vie': 0,
          'Sáb': 0,
          'Dom': 0,
        };
        _loadError = 'No se pudo cargar el análisis. Intenta nuevamente.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator()),
      );
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 80,
            backgroundColor: Color(0xFF0A0A0F),
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Análisis',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_loadError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF6B6B),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _loadError!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Stats grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _stat(
                    'Entrenamientos',
                    '${_analytics['totalWorkouts']}',
                    Icons.fitness_center,
                    const Color(0xFF6C63FF),
                  ),
                  _stat(
                    'Horas Totales',
                    '${(_analytics['totalHours'] as num?)?.toStringAsFixed(0)}',
                    Icons.timer,
                    const Color(0xFF4ECDC4),
                  ),
                  _stat(
                    'Racha Actual',
                    '${_analytics['currentStreak']} días',
                    Icons.local_fire_department,
                    const Color(0xFFFF6B6B),
                  ),
                  _stat(
                    'Consistencia',
                    '${_analytics['consistencyScore']}%',
                    Icons.verified,
                    const Color(0xFFFFE66D),
                  ),
                  _stat(
                    'Vol. Total',
                    '${((_analytics['totalVolume'] as num?) ?? 0) ~/ 1000}T',
                    Icons.bar_chart,
                    const Color(0xFF95E1D3),
                  ),
                  _stat(
                    'Prom/Sesión',
                    '${(_analytics['avgDuration'] as num?)?.toStringAsFixed(0)}min',
                    Icons.schedule,
                    const Color(0xFFAA96DA),
                  ),
                ],
              ),
            ),
          ),
          // Frequency chart
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frecuencia por Día',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children:
                          _frequency.entries.map((e) {
                            final maxV = _frequency.values.reduce(
                              (a, b) => a > b ? a : b,
                            );
                            final h =
                                maxV > 0 ? (e.value / maxV * 70 + 10) : 10.0;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${e.value}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: h,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            const Color(
                                              0xFF6C63FF,
                                            ).withValues(alpha: 0.3),
                                            const Color(0xFF6C63FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // PRs
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Records Personales 🏆',
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
              final pr = _prs[i];
              final improvement =
                  ((pr['weight'] as num) - (pr['previous'] as num));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE66D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🏋️', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr['exercise'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${pr['date']} · ${pr['reps']}RM',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(pr['weight'] as num).toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+${improvement.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }, childCount: _prs.length),
          ),
          // Insights
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _insight(
                    'Músculo más entrenado: ${_analytics['mostTrainedMuscle']}',
                    const Color(0xFF4ECDC4),
                  ),
                  _insight(
                    'Músculo menos entrenado: ${_analytics['leastTrainedMuscle']}',
                    const Color(0xFFFF6B6B),
                  ),
                  _insight(
                    'Ejercicio favorito: ${_analytics['favoriteExercise']}',
                    const Color(0xFF6C63FF),
                  ),
                  _insight(
                    'Mejora mensual: ${_analytics['improvementRate']}%',
                    const Color(0xFFFFE66D),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _stat(String l, String v, IconData ic, Color c) => Container(
    width: (MediaQuery.of(context).size.width - 42) / 2,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.withValues(alpha: 0.1)),
    ),
    child: Row(
      children: [
        Icon(ic, color: c, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              l,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _insight(String text, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    ),
  );
}
