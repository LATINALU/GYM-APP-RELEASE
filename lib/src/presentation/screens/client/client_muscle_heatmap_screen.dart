import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/quantum_colors.dart';
import '../../widgets/neon_widgets.dart';
import '../../bloc/app_bloc.dart';

class ClientMuscleHeatmapScreen extends StatefulWidget {
  const ClientMuscleHeatmapScreen({super.key});

  @override
  State<ClientMuscleHeatmapScreen> createState() =>
      _ClientMuscleHeatmapScreenState();
}

class _ClientMuscleHeatmapScreenState extends State<ClientMuscleHeatmapScreen> {
  int _selectedFilter = 0; // 0=Fuerza, 1=Cardio, 2=Flexibilidad

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final muscleIntensityMap = _muscleIntensityMap(state);
        final hasStrengthData =
            _selectedFilter == 0 &&
            muscleIntensityMap.values.any((value) => value > 0);

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        QuantumColors.holoPurple.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: QuantumColors.surface(opacity: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: QuantumColors.subtleBorder),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Mapa Muscular',
                        style: QuantumTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: QuantumColors.surface(opacity: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: QuantumColors.subtleBorder),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: QuantumColors.surface(opacity: 0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: QuantumColors.subtleBorder),
                        boxShadow: QuantumColors.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GridBackgroundPainter(
                                  spacing: 28,
                                  opacity: 0.025,
                                ),
                              ),
                            ),
                            Center(
                              child: _buildBodyHeatmap(
                                muscleIntensityMap,
                                hasStrengthData,
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: _buildFilterRow(),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: _buildLegend(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildMuscleStatsRow(
                    muscleIntensityMap,
                    hasStrengthData,
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyHeatmap(
    Map<String, double> muscleIntensityMap,
    bool hasStrengthData,
  ) {
    if (_selectedFilter != 0) {
      return _buildUnavailableHeatmap(
        'Esta vista estará disponible cuando exista tracking real para ${_selectedFilter == 1 ? 'cardio' : 'flexibilidad'}.',
      );
    }

    if (!hasStrengthData) {
      return _buildUnavailableHeatmap(
        'Entrena y registra volumen para visualizar tu activación muscular.',
      );
    }

    final shoulder = muscleIntensityMap['shoulders'] ?? 0;
    final chest = muscleIntensityMap['chest'] ?? 0;
    final core = muscleIntensityMap['core'] ?? 0;
    final arms = muscleIntensityMap['arms'] ?? 0;
    final back = muscleIntensityMap['back'] ?? 0;
    final legs = muscleIntensityMap['legs'] ?? 0;

    return SizedBox(
      width: 240,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base silhouette
          Icon(
            Icons.accessibility_new_rounded,
            size: 300,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _buildHeatmapSpot(top: 45, size: 16, intensity: back * 0.35),
          _buildHeatmapSpot(
            top: 90,
            left: 40,
            size: 22,
            intensity: shoulder,
          ),
          _buildHeatmapSpot(
            top: 90,
            right: 40,
            size: 22,
            intensity: shoulder,
          ),
          _buildHeatmapSpot(
            top: 110,
            left: 70,
            size: 28,
            intensity: chest,
          ),
          _buildHeatmapSpot(
            top: 110,
            right: 70,
            size: 28,
            intensity: chest,
          ),
          _buildHeatmapSpot(top: 155, size: 24, intensity: core),
          _buildHeatmapSpot(
            top: 140,
            left: 30,
            size: 18,
            intensity: arms,
          ),
          _buildHeatmapSpot(
            top: 140,
            right: 30,
            size: 18,
            intensity: arms,
          ),
          _buildHeatmapSpot(
            top: 180,
            left: 18,
            size: 14,
            intensity: arms * 0.6,
          ),
          _buildHeatmapSpot(
            top: 180,
            right: 18,
            size: 14,
            intensity: arms * 0.6,
          ),
          _buildHeatmapSpot(
            bottom: 100,
            left: 70,
            size: 22,
            intensity: legs,
            isElongated: true,
          ),
          _buildHeatmapSpot(
            bottom: 100,
            right: 70,
            size: 22,
            intensity: legs,
            isElongated: true,
          ),
          _buildHeatmapSpot(
            bottom: 40,
            left: 75,
            size: 14,
            intensity: legs * 0.55,
            isElongated: true,
          ),
          _buildHeatmapSpot(
            bottom: 40,
            right: 75,
            size: 14,
            intensity: legs * 0.55,
            isElongated: true,
          ),
        ],
      ),
    );
  }

  // ─── FILTER BUTTONS ──────────────────────────────────────────────
  Widget _buildFilterRow() {
    final filters = [
      {'icon': Icons.fitness_center, 'label': 'Fuerza'},
      {'icon': Icons.directions_run, 'label': 'Cardio'},
      {'icon': Icons.self_improvement, 'label': 'Flex'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(filters.length, (i) {
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
          child: NeonIconToggle(
            icon: filters[i]['icon'] as IconData,
            isActive: _selectedFilter == i,
            onTap: () => setState(() => _selectedFilter = i),
          ),
        );
      }),
    );
  }

  // ─── LEGEND ──────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QuantumColors.surface(opacity: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intensidad',
            style: TextStyle(
              color: QuantumColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _legendDot(QuantumColors.quantumBlue.withValues(alpha: 0.3), 'Baja'),
          const SizedBox(height: 6),
          _legendDot(QuantumColors.quantumBlue.withValues(alpha: 0.6), 'Media'),
          const SizedBox(height: 6),
          _legendDot(QuantumColors.quantumBlue, 'Alta'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: QuantumColors.nebulaWhite,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── MUSCLE STATS ROW ────────────────────────────────────────────
  Widget _buildMuscleStatsRow(
    Map<String, double> muscleIntensityMap,
    bool hasStrengthData,
  ) {
    if (_selectedFilter != 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuantumColors.surface(opacity: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuantumColors.subtleBorder),
        ),
        child: Text(
          'Las métricas de cardio y flexibilidad aparecerán cuando exista tracking real para esos módulos.',
          style: TextStyle(
            color: QuantumColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!hasStrengthData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuantumColors.surface(opacity: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuantumColors.subtleBorder),
        ),
        child: Text(
          'Todavía no hay suficiente volumen registrado para construir tu mapa muscular.',
          style: TextStyle(
            color: QuantumColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final sortedEntries =
        muscleIntensityMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topGroups = sortedEntries.take(4).toList();

    return Row(
      children: List.generate(topGroups.length, (index) {
        final entry = topGroups[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == topGroups.length - 1 ? 0 : 10),
            child: _buildMuscleStatCard(
              _displayGroupLabel(entry.key),
              '${(entry.value * 100).round()}%',
              entry.value,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMuscleStatCard(String label, String pct, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: QuantumColors.surface(opacity: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuantumColors.subtleBorder),
        boxShadow: QuantumColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: QuantumColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct,
            style: QuantumTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.7
                    ? QuantumColors.success
                    : QuantumColors.quantumBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableHeatmap(String message) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.surface(opacity: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuantumColors.subtleBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insights_outlined,
            color: QuantumColors.quantumBlue.withValues(alpha: 0.8),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: QuantumColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSpot({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required double intensity,
    bool isElongated = false,
  }) {
    if (intensity <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: GlowingMuscleSpot(
        size: size,
        intensity: intensity.clamp(0.0, 1.0),
        isElongated: isElongated,
      ),
    );
  }

  Map<String, double> _muscleIntensityMap(AppState state) {
    if (state is! AppLoaded || state.muscleVolumeMap.isEmpty) {
      return const {};
    }

    final raw = state.muscleVolumeMap;
    final grouped = <String, double>{
      'chest': _sumMuscles(raw, const ['pecho', 'chest', 'pectorales']),
      'back': _sumMuscles(raw, const ['espalda', 'back', 'dorsales', 'lats']),
      'shoulders': _sumMuscles(raw, const ['hombros', 'shoulders']),
      'arms': _sumMuscles(
        raw,
        const ['brazos', 'arms', 'biceps', 'bíceps', 'triceps', 'tríceps', 'antebrazos', 'forearms'],
      ),
      'core': _sumMuscles(raw, const ['core', 'abs', 'abdominales']),
      'legs': _sumMuscles(
        raw,
        const ['piernas', 'legs', 'quads', 'cuádriceps', 'cuadriceps', 'gluteos', 'glúteos', 'hamstrings', 'isquios', 'calves', 'pantorrillas'],
      ),
    };

    final maxValue = grouped.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (maxValue <= 0) {
      return grouped.map((key, value) => MapEntry(key, 0.0));
    }

    return grouped.map(
      (key, value) => MapEntry(key, (value / maxValue).clamp(0.0, 1.0)),
    );
  }

  double _sumMuscles(
    Map<String, double> raw,
    List<String> aliases,
  ) {
    var total = 0.0;
    for (final entry in raw.entries) {
      final key = entry.key.toLowerCase();
      if (aliases.any((alias) => key.contains(alias))) {
        total += entry.value;
      }
    }
    return total;
  }

  String _displayGroupLabel(String key) {
    switch (key) {
      case 'chest':
        return 'Pecho';
      case 'back':
        return 'Espalda';
      case 'shoulders':
        return 'Hombros';
      case 'arms':
        return 'Brazos';
      case 'core':
        return 'Core';
      case 'legs':
        return 'Piernas';
      default:
        return key;
    }
  }
}
