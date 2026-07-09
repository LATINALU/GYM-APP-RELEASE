/// Active Workout Screen - Real-time workout logging
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_plan.dart';
import '../../../domain/entities/gym_exercise.dart';
import '../../bloc/app_bloc.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutDay? plannedWorkout;
  final String? workoutName;

  const ActiveWorkoutScreen({
    super.key,
    this.plannedWorkout,
    this.workoutName,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with TickerProviderStateMixin {
  late WorkoutSession _session;
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  int _currentExerciseIndex = 0;
  
  // Rest timer
  bool _isResting = false;
  int _restSeconds = 0;
  int _restTarget = 90;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _startTimer();
  }

  void _initializeSession() {
    final name = widget.workoutName ?? 
                 widget.plannedWorkout?.name ?? 
                 'Entrenamiento Rápido';
    
    _session = WorkoutSession.start(
      name: name,
      description: widget.plannedWorkout?.description,
    );

    // Convert planned exercises to logs if available
    if (widget.plannedWorkout != null) {
      final logs = widget.plannedWorkout!.exercises.asMap().entries.map((entry) {
        return ExerciseLog(
          id: 'log-${entry.key}',
          exerciseId: entry.value.exerciseId,
          exerciseName: entry.value.exerciseName,
          muscleGroup: entry.value.muscleGroup,
          order: entry.key,
          sets: [],
        );
      }).toList();
      
      _session = _session.copyWith(exercises: logs);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  void _startRestTimer() {
    _isResting = true;
    _restSeconds = 0;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds++;
        if (_restSeconds >= _restTarget) {
          _stopRestTimer();
          HapticFeedback.heavyImpact();
          _showRestCompleteNotification();
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
  }

  void _showRestCompleteNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.white),
            SizedBox(width: 12),
            Text('¡Descanso terminado! Siguiente serie'),
          ],
        ),
        backgroundColor: QuantumColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _addExercise() async {
    final result = await showModalBottomSheet<GymExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerSheet(),
    );

    if (result != null) {
      setState(() {
        final newLog = ExerciseLog(
          id: 'log-${_session.exercises.length}',
          exerciseId: result.id,
          exerciseName: result.name,
          muscleGroup: result.primaryMuscle.displayName,
          order: _session.exercises.length,
          sets: [],
        );
        _session = _session.copyWith(
          exercises: [..._session.exercises, newLog],
        );
      });
    }
  }

  void _logSet(int exerciseIndex, int reps, double weight) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      final exercise = _session.exercises[exerciseIndex];
      final newSet = ExerciseSet(
        setNumber: exercise.sets.length + 1,
        reps: reps,
        weight: weight,
        timestamp: DateTime.now(),
      );
      
      final updatedSets = [...exercise.sets, newSet];
      final updatedExercise = exercise.copyWith(sets: updatedSets);
      
      final updatedExercises = List<ExerciseLog>.from(_session.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;
      
      _session = _session.copyWith(exercises: updatedExercises);
    });

    // Start rest timer automatically
    _startRestTimer();
  }

  void _removeLastSet(int exerciseIndex) {
    final exercise = _session.exercises[exerciseIndex];
    if (exercise.sets.isEmpty) return;

    setState(() {
      final updatedSets = [...exercise.sets]..removeLast();
      final updatedExercise = exercise.copyWith(sets: updatedSets);
      
      final updatedExercises = List<ExerciseLog>.from(_session.exercises);
      updatedExercises[exerciseIndex] = updatedExercise;
      
      _session = _session.copyWith(exercises: updatedExercises);
    });
  }

  void _finishWorkout() async {
    _timer.cancel();
    _restTimer?.cancel();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _FinishWorkoutDialog(
        session: _session.copyWith(
          status: WorkoutStatus.completed,
          endTime: DateTime.now(),
        ),
      ),
    );

    if (confirmed == true) {
      await _saveWorkoutSession();
    }
  }

  Future<void> _saveWorkoutSession() async {
    try {
      final auth = AuthStateNotifier.instance;
      final userId = auth.profile?.uid;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Calcular volumen total
      final totalVolume = _session.exercises.fold<double>(0, (acc, ex) {
        return acc + ex.sets.fold<double>(0, (s, set) {
          return s + (set.weight * set.reps);
        });
      });

      // Calcular duración
      final duration = DateTime.now().difference(_session.startTime ?? DateTime.now()).inSeconds;

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('workout_sessions').add({
        'userId': userId,
        'routineId': 'manual',
        'date': DateTime.now().toIso8601String(),
        'duration': duration,
        'isCompleted': true,
        'exercises': _session.exercises.map((ex) => {
          'exerciseId': ex.exerciseId,
          'name': ex.exerciseName,
          'sets': ex.sets.map((set) => {
            'setNumber': set.setNumber,
            'reps': set.reps,
            'weight': set.weight,
            'rpe': 0,
            'completed': true,
          }).toList(),
        }).toList(),
        'totalVolume': totalVolume,
        'caloriesBurned': (totalVolume * 0.18).round(),
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar AppBloc
      final completedSession = _session.copyWith(
        status: WorkoutStatus.completed,
        endTime: DateTime.now(),
      );
      
      if (mounted) {
        context.read<AppBloc>().add(WorkoutCompleted(completedSession));
        
        Navigator.of(context).pop(completedSession);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Entrenamiento guardado exitosamente'),
            backgroundColor: QuantumColors.matrixCyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _discardWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        title: const Text('¿Descartar entrenamiento?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Perderás todo el progreso de esta sesión.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _timer.cancel();
      _restTimer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QuantumColors.quantumBlue.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _discardWorkout,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _session.name,
              style: QuantumTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.timer, color: QuantumColors.quantumBlue, size: 14),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_elapsed),
                  style: QuantumTypography.data.copyWith(
                    color: QuantumColors.quantumBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isPaused 
                ? QuantumColors.success.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: _isPaused ? QuantumColors.success : Colors.white,
              ),
              onPressed: () => setState(() => _isPaused = !_isPaused),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest Timer Banner
          if (_isResting)
            _buildRestTimerBanner(),

          // Stats Summary
          _buildStatsSummary(),

          // Exercise List
          Expanded(
            child: _session.exercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _session.exercises.length,
                    itemBuilder: (context, index) => _ExerciseCard(
                      exercise: _session.exercises[index],
                      isActive: index == _currentExerciseIndex,
                      onTap: () => setState(() => _currentExerciseIndex = index),
                      onLogSet: (reps, weight) => _logSet(index, reps, weight),
                      onRemoveLastSet: () => _removeLastSet(index),
                    ),
                  ),
          ),

          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildRestTimerBanner() {
    final progress = _restSeconds / _restTarget;
    final remaining = _restTarget - _restSeconds;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: QuantumColors.quantumBlue,
                ),
              ),
              Text(
                '${remaining}s',
                style: QuantumTypography.data.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESCANSO',
                  style: QuantumTypography.label.copyWith(
                    color: QuantumColors.quantumBlue,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RestTimeButton(
                      label: '60s',
                      isSelected: _restTarget == 60,
                      onTap: () => setState(() => _restTarget = 60),
                    ),
                    const SizedBox(width: 8),
                    _RestTimeButton(
                      label: '90s',
                      isSelected: _restTarget == 90,
                      onTap: () => setState(() => _restTarget = 90),
                    ),
                    const SizedBox(width: 8),
                    _RestTimeButton(
                      label: '120s',
                      isSelected: _restTarget == 120,
                      onTap: () => setState(() => _restTarget = 120),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white70),
            onPressed: _stopRestTimer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QuantumColors.quantumBlue.withValues(alpha: 0.08),
            QuantumColors.quantumBlue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Ejercicios',
            value: '${_session.exerciseCount}',
            icon: Icons.fitness_center,
            color: QuantumColors.quantumBlue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            label: 'Series',
            value: '${_session.totalSets}',
            icon: Icons.repeat,
            color: QuantumColors.matrixCyan,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            label: 'Volumen',
            value: '${(_session.totalVolume / 1000).toStringAsFixed(1)}t',
            icon: Icons.scale,
            color: QuantumColors.success,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatItem(
            label: 'Reps',
            value: '${_session.totalReps}',
            icon: Icons.numbers,
            color: QuantumColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  QuantumColors.quantumBlue.withValues(alpha: 0.2),
                  QuantumColors.quantumBlue.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 80,
              color: QuantumColors.quantumBlue.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin ejercicios',
            style: QuantumTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Agrega ejercicios para empezar',
            style: QuantumTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: QuantumColors.quantumBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Modo libre: Registra lo que desees',
                  style: QuantumTypography.bodySmall.copyWith(
                    color: QuantumColors.quantumBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('AÑADIR EJERCICIO'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _session.exercises.isEmpty ? null : _finishWorkout,
                icon: const Icon(Icons.check_circle),
                label: const Text('FINALIZAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuantumColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: QuantumTypography.data.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: QuantumTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _RestTimeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RestTimeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? QuantumColors.quantumBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? QuantumColors.quantumBlue : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final ExerciseLog exercise;
  final bool isActive;
  final VoidCallback onTap;
  final Function(int reps, double weight) onLogSet;
  final VoidCallback onRemoveLastSet;

  const _ExerciseCard({
    required this.exercise,
    required this.isActive,
    required this.onTap,
    required this.onLogSet,
    required this.onRemoveLastSet,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    // Pre-fill with last set data if available
    if (widget.exercise.sets.isNotEmpty) {
      final lastSet = widget.exercise.sets.last;
      _repsController.text = lastSet.reps.toString();
      _weightController.text = lastSet.weight.toString();
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _quickLog() {
    final reps = int.tryParse(_repsController.text) ?? 10;
    final weight = double.tryParse(_weightController.text) ?? 0;
    widget.onLogSet(reps, weight);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? QuantumColors.quantumBlue.withValues(alpha: 0.1)
              : QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isActive 
                ? QuantumColors.quantumBlue 
                : Colors.white.withValues(alpha: 0.05),
            width: widget.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.exercise.muscleGroup.toUpperCase(),
                    style: const TextStyle(
                      color: QuantumColors.quantumBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.exercise.workingSetsCount} series',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Exercise Name
            Text(
              widget.exercise.exerciseName,
              style: QuantumTypography.h4.copyWith(color: Colors.white),
            ),
            
            // Sets List
            if (widget.exercise.sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.exercise.sets.map((set) => _SetChip(set: set)).toList(),
              ),
            ],

            // Quick Log Input (when active)
            if (widget.isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Reps Input
                  Expanded(
                    child: _QuickInputField(
                      controller: _repsController,
                      label: 'REPS',
                      onDecrement: () {
                        final val = int.tryParse(_repsController.text) ?? 0;
                        if (val > 1) _repsController.text = (val - 1).toString();
                      },
                      onIncrement: () {
                        final val = int.tryParse(_repsController.text) ?? 0;
                        _repsController.text = (val + 1).toString();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Weight Input
                  Expanded(
                    child: _QuickInputField(
                      controller: _weightController,
                      label: 'KG',
                      step: 2.5,
                      onDecrement: () {
                        final val = double.tryParse(_weightController.text) ?? 0;
                        if (val >= 2.5) _weightController.text = (val - 2.5).toString();
                      },
                      onIncrement: () {
                        final val = double.tryParse(_weightController.text) ?? 0;
                        _weightController.text = (val + 2.5).toString();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Log Button
                  ElevatedButton(
                    onPressed: _quickLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuantumColors.quantumBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.check),
                  ),
                ],
              ),
              
              // Undo last set
              if (widget.exercise.sets.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onRemoveLastSet,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Deshacer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  final ExerciseSet set;

  const _SetChip({required this.set});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: set.isWarmup 
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: set.isFailure
            ? Border.all(color: QuantumColors.success)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (set.isWarmup)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.whatshot, size: 12, color: Colors.orange),
            ),
          Text(
            '${set.weight}kg × ${set.reps}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (set.isFailure)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.star, size: 12, color: QuantumColors.success),
            ),
        ],
      ),
    );
  }
}

class _QuickInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final double step;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuickInputField({
    required this.controller,
    required this.label,
    this.step = 1,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.remove, color: Colors.white54, size: 18),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;

  List<GymExercise> get _filteredExercises {
    var exercises = ExerciseLibrary.all;
    
    if (_selectedMuscle != null) {
      exercises = ExerciseLibrary.getByMuscle(_selectedMuscle!);
    }
    
    if (_searchQuery.isNotEmpty) {
      exercises = exercises.where((e) => 
        e.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: QuantumColors.cosmicBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Seleccionar Ejercicio',
                  style: QuantumTypography.h3.copyWith(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Muscle Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  isSelected: _selectedMuscle == null,
                  onTap: () => setState(() => _selectedMuscle = null),
                ),
                ...MuscleGroup.values.map((m) => _FilterChip(
                  label: m.displayName,
                  isSelected: _selectedMuscle == m,
                  onTap: () => setState(() => _selectedMuscle = m),
                )),
              ],
            ),
          ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return ListTile(
                  onTap: () => Navigator.pop(context, exercise),
                  leading: CircleAvatar(
                    backgroundColor: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                    child: Text(
                      exercise.primaryMuscle.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    exercise.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${exercise.primaryMuscle.displayName} • ${exercise.equipment.displayName}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    color: QuantumColors.quantumBlue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? QuantumColors.quantumBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? QuantumColors.quantumBlue : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FinishWorkoutDialog extends StatefulWidget {
  final WorkoutSession session;

  const _FinishWorkoutDialog({required this.session});

  @override
  State<_FinishWorkoutDialog> createState() => _FinishWorkoutDialogState();
}

class _FinishWorkoutDialogState extends State<_FinishWorkoutDialog> {
  int _rating = 4;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QuantumColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.emoji_events, color: QuantumColors.success),
          SizedBox(width: 12),
          Text('¡Entrenamiento Completado!', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Duración',
                  value: '${widget.session.duration?.inMinutes ?? 0}m',
                ),
                _SummaryItem(
                  label: 'Ejercicios',
                  value: '${widget.session.exerciseCount}',
                ),
                _SummaryItem(
                  label: 'Volumen',
                  value: '${(widget.session.totalVolume / 1000).toStringAsFixed(1)}t',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Rating
          const Text(
            '¿Cómo fue tu entrenamiento?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected ? Colors.amber : Colors.white30,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.success,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: QuantumTypography.data.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
