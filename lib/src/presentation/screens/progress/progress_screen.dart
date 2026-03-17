/// Progress Screen - Track weight, measurements, and PRs
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../../bloc/app_bloc.dart';
import '../../../domain/entities/user_fitness_profile.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserFitnessProfile _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profile = const UserFitnessProfile(
      id: '',
      name: '',
      gender: Gender.other,
      height: 1,
      currentWeight: 0,
      level: ExperienceLevel.beginner,
      primaryGoal: FitnessGoal.maintain,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final totalWorkouts = state is AppLoaded ? state.totalWorkouts : 0;
        final currentStreak = state is AppLoaded ? state.currentStreak : 0;
        final longestStreak = state is AppLoaded ? state.longestStreak : 0;
        final personalRecords = state is AppLoaded ? state.personalRecords.length : 0;

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Mi Progreso',
              style: QuantumTypography.h1.copyWith(color: Colors.white),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      QuantumColors.quantumBlue.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: QuantumColors.quantumBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.insights_outlined, color: QuantumColors.quantumBlue, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Seguimiento detallado no disponible',
                      style: QuantumTypography.h3.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'El detalle de peso, medidas, fotos y evolución aún no está conectado a datos reales en esta pantalla.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressMetricCard(
                      'Entrenos',
                      '$totalWorkouts',
                      Icons.fitness_center,
                      QuantumColors.quantumBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressMetricCard(
                      'Racha actual',
                      '$currentStreak',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressMetricCard(
                      'Racha máxima',
                      '$longestStreak',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressMetricCard(
                      'PRs',
                      '$personalRecords',
                      Icons.stars,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: QuantumColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.white38, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Sin datos históricos para mostrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando esta vista se conecte al backend, aquí verás tu evolución corporal y tus récords reales.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleFabPress() {
    switch (_tabController.index) {
      case 0:
        _addWeight();
        break;
      case 1:
        _addMeasurements();
        break;
      case 2:
        _addPR();
        break;
    }
  }

  void _addWeight() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddWeightSheet(
        currentWeight: _profile.currentWeight,
        onSave: (weight) {
          setState(() {
            final newEntry = WeightEntry(date: DateTime.now(), weight: weight);
            _profile = _profile.copyWith(
              currentWeight: weight,
              weightHistory: [..._profile.weightHistory, newEntry],
            );
          });
        },
      ),
    );
  }

  void _addMeasurements() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Añadir medidas')),
    );
  }

  void _addPR() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Registrar nuevo PR')),
    );
  }

  void _addProgressPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Añadir foto de progreso')),
    );
  }
}

class _WeightTab extends StatelessWidget {
  final UserFitnessProfile profile;
  final VoidCallback onAddWeight;

  const _WeightTab({required this.profile, required this.onAddWeight});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Weight Card
          _CurrentWeightCard(profile: profile, onTap: onAddWeight),
          const SizedBox(height: 24),
          
          // Weight Chart
          if (profile.weightHistory.isNotEmpty) ...[
            Text(
              'Historial de Peso',
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _WeightChart(entries: profile.weightHistory, targetWeight: profile.targetWeight),
            const SizedBox(height: 24),
          ],
          
          // Weight History List
          Text(
            'Registros Recientes',
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...profile.weightHistory.reversed.take(10).map((entry) => _WeightEntryTile(entry: entry)),
          
          if (profile.weightHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'Sin registros de peso',
                      style: QuantumTypography.body.copyWith(color: Colors.white38),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: onAddWeight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QuantumColors.quantumBlue,
                      ),
                      child: const Text('Añadir Peso'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrentWeightCard extends StatelessWidget {
  final UserFitnessProfile profile;
  final VoidCallback onTap;

  const _CurrentWeightCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final weightChange = profile.weightChange ?? 0;
    final isGaining = weightChange > 0;
    final changeColor = profile.primaryGoal == FitnessGoal.buildMuscle
        ? (isGaining ? QuantumColors.success : Colors.orange)
        : (isGaining ? Colors.orange : QuantumColors.success);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              QuantumColors.quantumBlue.withValues(alpha: 0.2),
              QuantumColors.quantumBlue.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PESO ACTUAL',
                    style: TextStyle(
                      color: QuantumColors.quantumBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${profile.currentWeight}',
                        style: QuantumTypography.data.copyWith(
                          color: Colors.white,
                          fontSize: 48,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          'kg',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (weightChange != 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGaining ? Icons.arrow_upward : Icons.arrow_downward,
                            color: changeColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${weightChange.abs().toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'OBJETIVO',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.targetWeight ?? '--'} kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'BMI',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.bmi.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? targetWeight;

  const _WeightChart({required this.entries, this.targetWeight});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox();

    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minWeight = entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minWeight,
          maxY: maxWeight,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: targetWeight != null
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetWeight!,
                      color: QuantumColors.success.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => 'OBJETIVO',
                        style: const TextStyle(
                          color: QuantumColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: QuantumColors.quantumBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: QuantumColors.quantumBlue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    QuantumColors.quantumBlue.withValues(alpha: 0.3),
                    QuantumColors.quantumBlue.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = entries[spot.spotIndex];
                  return LineTooltipItem(
                    '${entry.weight} kg\n${_formatDate(entry.date)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _WeightEntryTile extends StatelessWidget {
  final WeightEntry entry;

  const _WeightEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${entry.date.day}',
                style: QuantumTypography.data.copyWith(
                  color: QuantumColors.quantumBlue,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weight} kg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatFullDate(entry.date),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (entry.notes != null)
            const Icon(Icons.note, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _MeasurementsTab extends StatelessWidget {
  final UserFitnessProfile profile;

  const _MeasurementsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Sin medidas registradas',
            style: QuantumTypography.h3.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registra tus medidas corporales para\nver tu progreso a lo largo del tiempo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Añadir Medidas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuantumColors.quantumBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalRecordsTab extends StatelessWidget {
  final UserFitnessProfile profile;

  const _PersonalRecordsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    final records = profile.personalRecords.values.toList();
    
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Sin PRs registrados',
              style: QuantumTypography.h3.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus récords personales aparecerán aquí',
              style: TextStyle(color: Colors.white24),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final pr = records[index];
        return _PRCard(record: pr);
      },
    );
  }
}

class _PRCard extends StatelessWidget {
  final PersonalRecord record;

  const _PRCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.weight} kg × ${record.reps} reps',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Est. 1RM: ${record.estimated1RM.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(record.date),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddWeightSheet extends StatefulWidget {
  final double currentWeight;
  final Function(double) onSave;

  const _AddWeightSheet({
    required this.currentWeight,
    required this.onSave,
  });

  @override
  State<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<_AddWeightSheet> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentWeight.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: QuantumColors.cosmicBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Registrar Peso',
              style: QuantumTypography.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Peso actual: ${widget.currentWeight} kg',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            
            // Weight Input
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final val = double.tryParse(_controller.text) ?? 0;
                    if (val > 0.1) {
                      _controller.text = (val - 0.1).toStringAsFixed(1);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 32),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: QuantumTypography.data.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffix: Text(
                        'kg',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null) {
                        return 'Ingrese un peso válido';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final val = double.tryParse(_controller.text) ?? 0;
                    _controller.text = (val + 0.1).toStringAsFixed(1);
                  },
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final weight = double.parse(_controller.text);
                    widget.onSave(weight);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Peso registrado: $weight kg'),
                        backgroundColor: QuantumColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.quantumBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GUARDAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
