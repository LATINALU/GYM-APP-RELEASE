import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../widgets/exercise/muscle_heatmap_view.dart';
import '../../../domain/entities/exercise.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildMuscleActivity(),
              const SizedBox(height: 32),
              _buildTrainingVolume(),
              const SizedBox(height: 32),
              _buildFrequencyStats(),
              const SizedBox(height: 120), // Padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALÍTICA CÚANTICA',
          style: QuantumTypography.label.copyWith(
            color: QuantumColors.quantumBlue,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'RENDIMIENTO',
          style: QuantumTypography.h2.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMuscleActivity() {
    return QuantumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.troubleshoot_rounded, color: QuantumColors.quantumBlue, size: 20),
              const SizedBox(width: 12),
              Text('ACTIVACIÓN MUSCULAR', style: QuantumTypography.label.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: MuscleHeatmapView(
                  size: 150,
                  heatmap: MuscleHeatmap({
                    'pectorals': 0.8,
                    'triceps': 0.6,
                    'quads': 0.4,
                    'abs': 0.3,
                  }),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMuscleStatRow('Pectorales', 0.8, QuantumColors.matrixCyan),
                    _buildMuscleStatRow('Tríceps', 0.6, QuantumColors.quantumBlue),
                    _buildMuscleStatRow('Cuádriceps', 0.4, Colors.purpleAccent),
                    _buildMuscleStatRow('Core', 0.3, Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleStatRow(String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: QuantumTypography.caption.copyWith(color: Colors.white70)),
              Text('${(value * 100).toInt()}%', style: QuantumTypography.data.copyWith(color: color, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingVolume() {
    return const Row(
      children: [
        Expanded(
          child: DataMatrixCard(
            title: 'VOLUMEN TOTAL',
            value: '12.4',
            unit: 'TONS',
            icon: Icons.fitness_center_rounded,
            accentColor: QuantumColors.quantumBlue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: DataMatrixCard(
            title: 'REPETICIONES',
            value: '842',
            unit: 'REPS',
            icon: Icons.repeat_one_rounded,
            accentColor: QuantumColors.matrixCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyStats() {
    return QuantumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_view_week_rounded, color: QuantumColors.quantumBlue, size: 20),
              const SizedBox(width: 12),
              Text('FRECUENCIA SEMANAL', style: QuantumTypography.label.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('L', 0.8),
                _buildBar('M', 0.6),
                _buildBar('M', 0.9),
                _buildBar('J', 0.0),
                _buildBar('V', 0.7),
                _buildBar('S', 0.4),
                _buildBar('D', 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: 20,
          height: 80 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                QuantumColors.quantumBlue.withValues(alpha: 0.2),
                QuantumColors.quantumBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              if (height > 0)
                BoxShadow(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: QuantumTypography.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
