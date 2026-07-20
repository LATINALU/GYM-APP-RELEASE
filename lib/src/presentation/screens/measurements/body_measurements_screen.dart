import 'package:flutter/material.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/services/measurement_service.dart';
import '../../../domain/entities/body_measurement.dart';
import '../../../infrastructure/config/di.dart';

/// Body Measurements Screen - inspired by wger's measurement tracking UI
/// Shows progress charts, latest measurements, and allows new entries
class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final MeasurementService _service = get<MeasurementService>();
  List<BodyMeasurement> _history = [];
  Map<String, dynamic> _progress = {};
  bool _isLoading = true;
  String _selectedCategory = 'Resumen';

  final _categories = ['Resumen', 'Peso', 'Circunferencias', 'Composición'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? get _uid => AuthStateNotifier.instance.profile?.uid;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }
      final history = await _service.getHistory(uid);
      final progress = await _service.getProgressSummary(uid);
      setState(() {
        _history = history;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: _showAddMeasurementSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              )
              : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: _buildCategoryTabs()),
                  SliverToBoxAdapter(child: _buildProgressCards()),
                  SliverToBoxAdapter(child: _buildWeightChart()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Historial de Medidas',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildHistoryList(),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      backgroundColor: const Color(0xFF0A0A0F),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Medidas Corporales',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(22),
                border: isSelected ? null : Border.all(color: Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildStatCard(
            'Peso Actual',
            '${(_progress['currentWeight'] ?? 0).toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight,
            color: const Color(0xFF6C63FF),
            subtitle:
                'Inicio: ${(_progress['startWeight'] ?? 0).toStringAsFixed(1)} kg',
          ),
          _buildStatCard(
            'Cambio Peso',
            '${(_progress['weightChange'] ?? 0).toStringAsFixed(1)} kg',
            icon: Icons.trending_down,
            color:
                (_progress['weightChange'] ?? 0) < 0
                    ? const Color(0xFF4ECDC4)
                    : const Color(0xFFFF6B6B),
            subtitle: '${_progress['trackingDays'] ?? 0} días',
          ),
          _buildStatCard(
            'BMI',
            '${(_progress['currentBmi'] ?? 0).toStringAsFixed(1)}',
            icon: Icons.speed,
            color: const Color(0xFFFFE66D),
            subtitle: _progress['bmiCategory'] ?? 'N/A',
          ),
          _buildStatCard(
            'Grasa Corporal',
            '${(_progress['bodyFatChange'] ?? 0).toStringAsFixed(1)}%',
            icon: Icons.pie_chart,
            color: const Color(0xFFFF6B6B),
            subtitle:
                'Cambio en ${_progress['totalMeasurements'] ?? 0} medidas',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value, {
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_history.isEmpty) return const SizedBox.shrink();
    // Simple visual weight trend using bars
    final weights =
        _history
            .where((m) => m.weightKg != null)
            .take(8)
            .toList()
            .reversed
            .toList();
    if (weights.isEmpty) return const SizedBox.shrink();

    final maxW = weights
        .map((m) => m.weightKg!)
        .reduce((a, b) => a > b ? a : b);
    final minW = weights
        .map((m) => m.weightKg!)
        .reduce((a, b) => a < b ? a : b);
    final range = maxW - minW;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendencia de Peso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  weights.map((m) {
                    final h =
                        range > 0
                            ? ((m.weightKg! - minW) / range * 80 + 20)
                            : 60.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              m.weightKg!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
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
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'Sin medidas registradas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final m = _history[index];
        return _buildMeasurementTile(m);
      }, childCount: _history.length),
    );
  }

  Widget _buildMeasurementTile(BodyMeasurement m) {
    final dateStr = '${m.date.day}/${m.date.month}/${m.date.year}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.straighten,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (m.weightKg != null)
                      '${m.weightKg!.toStringAsFixed(1)}kg',
                    if (m.bodyFatPercentage != null)
                      '${m.bodyFatPercentage!.toStringAsFixed(1)}% grasa',
                    if (m.waistCm != null)
                      'Cintura: ${m.waistCm!.toStringAsFixed(0)}cm',
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          if (m.bmi != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'BMI ${m.bmi!.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMeasurementSheet() {
    final weightController = TextEditingController();
    final fatController = TextEditingController();
    final waistController = TextEditingController();
    final chestController = TextEditingController();
    final bicepsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
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
                  'Nueva Medida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  weightController,
                  'Peso (kg)',
                  Icons.monitor_weight,
                ),
                _buildInputField(
                  fatController,
                  '% Grasa Corporal',
                  Icons.pie_chart,
                ),
                _buildInputField(
                  waistController,
                  'Cintura (cm)',
                  Icons.straighten,
                ),
                _buildInputField(
                  chestController,
                  'Pecho (cm)',
                  Icons.straighten,
                ),
                _buildInputField(
                  bicepsController,
                  'Bíceps (cm)',
                  Icons.fitness_center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final uid = _uid;
                      if (uid == null) return;
                      final measurement = BodyMeasurement.create(
                        userId: uid,
                        weightKg: double.tryParse(weightController.text),
                        bodyFatPercentage: double.tryParse(fatController.text),
                        waistCm: double.tryParse(waistController.text),
                        chestCm: double.tryParse(chestController.text),
                        bicepsRightCm: double.tryParse(bicepsController.text),
                        heightCm:
                            AuthStateNotifier.instance.profile?.height ?? 170,
                      );
                      try {
                        await _service.saveMeasurement(measurement);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo guardar la medida. Intenta nuevamente.',
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
                      'Guardar Medida',
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
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
