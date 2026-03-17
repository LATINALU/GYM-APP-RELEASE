/// Workout Calendar Screen - Weekly planning and history
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../bloc/app_bloc.dart';
import '../../../domain/entities/workout_plan.dart';
import '../../../domain/entities/workout_session.dart';
import '../workout/active_workout_screen.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  late DateTime _selectedDate;
  final List<WorkoutSession> _localCompletedWorkouts = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final activePlan = state is AppLoaded ? state.assignedPlan : null;
        final completedWorkouts = [
          if (state is AppLoaded) ...state.recentSessions,
          ..._localCompletedWorkouts,
        ];

        return Scaffold(
          backgroundColor: QuantumColors.cosmicBlack,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Calendario',
              style: QuantumTypography.h1.copyWith(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.format_list_bulleted,
                  color: Colors.white70,
                ),
                onPressed: () => _showRoutineSelector(context),
                tooltip: 'Ver rutina',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildActivePlanCard(activePlan),
              _buildWeekView(activePlan, completedWorkouts),
              Expanded(
                child: _buildDayContent(activePlan, completedWorkouts),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _startQuickWorkout,
            backgroundColor: QuantumColors.quantumBlue,
            icon: const Icon(Icons.play_arrow),
            label: const Text('ENTRENAR'),
          ),
        );
      },
    );
  }

  Widget _buildActivePlanCard(WorkoutPlan? activePlan) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.quantumBlue.withValues(alpha: 0.15),
            QuantumColors.quantumBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: QuantumColors.quantumBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activePlan?.name ?? 'Sin rutina activa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      activePlan != null
                          ? '${activePlan.daysPerWeek} días/sem'
                          : 'Sin días asignados',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (activePlan != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activePlan.difficulty.displayName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activePlan.focus.displayName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    WorkoutPlan? activePlan,
    List<WorkoutSession> completedWorkouts,
  ) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final dayWorkout = _getDayWorkout(date, activePlan);
          final hasWorkout = dayWorkout != null && !dayWorkout.isRestDay;
          final isCompleted = _hasCompletedWorkout(date, completedWorkouts);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? QuantumColors.quantumBlue 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: QuantumColors.quantumBlue)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    WeekDay.values[index].shortName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasWorkout)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? QuantumColors.success 
                            : (isSelected ? Colors.white : QuantumColors.quantumBlue),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayContent(
    WorkoutPlan? activePlan,
    List<WorkoutSession> completedWorkouts,
  ) {
    final selectedWorkout = _getDayWorkout(_selectedDate, activePlan);
    final completedSession = _getCompletedSession(
      _selectedDate,
      completedWorkouts,
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Text(
            _formatDate(_selectedDate),
            style: QuantumTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Completed Workout Card
          if (completedSession != null)
            _buildCompletedWorkoutCard(completedSession),

          // Planned Workout
          if (selectedWorkout != null && completedSession == null)
            if (selectedWorkout.isRestDay)
              _buildRestDayCard()
            else
              _buildPlannedWorkoutCard(selectedWorkout),

          // No workout
          if (selectedWorkout == null && completedSession == null)
            _buildNoWorkoutCard(activePlan != null),
        ],
      ),
    );
  }

  Widget _buildPlannedWorkoutCard(WorkoutDay workout) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PLANIFICADO',
                  style: TextStyle(
                    color: QuantumColors.quantumBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '~${workout.estimatedDuration} min',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workout.name,
            style: QuantumTypography.h2.copyWith(color: Colors.white),
          ),
          if (workout.description != null) ...[
            const SizedBox(height: 4),
            Text(
              workout.description!,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 16),
          
          // Exercises Preview
          Text(
            '${workout.exercises.length} ejercicios • ${workout.totalSets} series',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workout.exercises.take(4).map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.exerciseName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            )).toList(),
          ),
          
          if (workout.exercises.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${workout.exercises.length - 4} más',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startWorkout(workout),
              icon: const Icon(Icons.play_arrow),
              label: const Text('EMPEZAR ENTRENAMIENTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuantumColors.quantumBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedWorkoutCard(WorkoutSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.success.withValues(alpha: 0.15),
            QuantumColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuantumColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: QuantumColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: QuantumColors.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETADO',
                      style: TextStyle(
                        color: QuantumColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (session.rating != null)
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < session.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.name,
            style: QuantumTypography.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(label: 'Duración', value: '${session.duration?.inMinutes ?? 0}m'),
              _StatColumn(label: 'Ejercicios', value: '${session.exerciseCount}'),
              _StatColumn(label: 'Series', value: '${session.totalSets}'),
              _StatColumn(label: 'Volumen', value: '${(session.totalVolume / 1000).toStringAsFixed(1)}t'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.self_improvement, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Día de Descanso',
            style: QuantumTypography.h3.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          const Text(
            'La recuperación es parte del entrenamiento',
            style: TextStyle(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkoutCard(bool hasAssignedPlan) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            hasAssignedPlan
                ? 'Sin entrenamiento planificado'
                : 'Sin rutina asignada',
            style: QuantumTypography.h3.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          if (!hasAssignedPlan)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Consulta tu plan asignado para ver tu calendario real.',
                style: TextStyle(color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton.icon(
            onPressed:
                hasAssignedPlan
                    ? _startQuickWorkout
                    : () => _showRoutineSelector(context),
            icon: const Icon(Icons.add),
            label: Text(hasAssignedPlan ? 'ENTRENAR AHORA' : 'VER RUTINA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: QuantumColors.quantumBlue,
            ),
          ),
        ],
      ),
    );
  }

  WorkoutDay? _getDayWorkout(DateTime date, WorkoutPlan? activePlan) {
    if (activePlan == null) {
      return null;
    }
    final dayOfWeek = WeekDay.fromDateTime(date);
    try {
      return activePlan.weeklySchedule.firstWhere(
        (d) => d.day == dayOfWeek,
      );
    } catch (_) {
      return null;
    }
  }

  bool _hasCompletedWorkout(
    DateTime date,
    List<WorkoutSession> completedWorkouts,
  ) {
    return completedWorkouts.any((w) => _isSameDay(w.date, date));
  }

  WorkoutSession? _getCompletedSession(
    DateTime date,
    List<WorkoutSession> completedWorkouts,
  ) {
    try {
      return completedWorkouts.firstWhere((w) => _isSameDay(w.date, date));
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${weekDays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  void _startWorkout(WorkoutDay workout) async {
    final result = await Navigator.push<WorkoutSession>(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(plannedWorkout: workout),
      ),
    );

    if (result != null) {
      setState(() {
        _localCompletedWorkouts.add(result);
      });
    }
  }

  void _startQuickWorkout() async {
    final result = await Navigator.push<WorkoutSession>(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveWorkoutScreen(workoutName: 'Entrenamiento Libre'),
      ),
    );

    if (result != null) {
      setState(() {
        _localCompletedWorkouts.add(result);
      });
    }
  }

  void _showRoutineSelector(BuildContext context) {
    context.pushNamed('clientRoutine');
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: QuantumTypography.data.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

