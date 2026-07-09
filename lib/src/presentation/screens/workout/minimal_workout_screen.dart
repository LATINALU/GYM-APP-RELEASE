import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../bloc/app_bloc.dart';

/// Pantalla de workout minimalista futurista
class MinimalWorkoutScreen extends StatefulWidget {
  final String workoutName;
  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  const MinimalWorkoutScreen({
    super.key,
    this.workoutName = 'Chest Day',
    this.onBack,
    this.onComplete,
  });

  @override
  State<MinimalWorkoutScreen> createState() => _MinimalWorkoutScreenState();
}

class _MinimalWorkoutScreenState extends State<MinimalWorkoutScreen> {
  int _sets = 4;
  int _reps = 12;
  int _currentNavIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo
            _buildHeader(),

            // Divisor holográfico
            const HolographicDivider(),

            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contador de sets/reps
                    FadeInWidget(
                      child: MinimalistSetCounter(
                        initialSets: _sets,
                        initialReps: _reps,
                        onChanged: (sets, reps) {
                          setState(() {
                            _sets = sets;
                            _reps = reps;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Título de ejercicios
                    FadeInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'EXERCISES',
                        style: QuantumTypography.label.copyWith(
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lista de ejercicios - Cargados desde AppBloc
                    BlocBuilder<AppBloc, AppState>(
                      builder: (context, state) {
                        if (state is AppLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: QuantumColors.quantumBlue,
                              ),
                            ),
                          );
                        }

                        if (state is AppError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Error al cargar rutina: ${state.message}',
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        if (state is! AppLoaded || state.assignedPlan == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 64,
                                    color: QuantumColors.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes rutinas asignadas',
                                    style: QuantumTypography.bodySmall.copyWith(
                                      color: QuantumColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Habla con tu entrenador para que te asigne un plan',
                                    style: QuantumTypography.caption.copyWith(
                                      color: QuantumColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Convertir ejercicios de la rutina a _ExerciseData
                        final routine = state.assignedPlan!;
                        final exercises = routine.weeklySchedule.expand((day) => day.exercises).map((ex) {
                          return _ExerciseData(
                            name: ex.exerciseName,
                            sets: '${ex.targetSets}x${ex.targetReps}',
                            prescribedSets: '${ex.targetSets}x${ex.targetReps}',
                            weight: '0kg', // Se actualizará durante el entrenamiento
                            isCompleted: false,
                            trainerNotes: ex.notes ?? '',
                          );
                        }).toList();

                        if (exercises.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Esta rutina no tiene ejercicios',
                                style: QuantumTypography.bodySmall.copyWith(
                                  color: QuantumColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: List.generate(exercises.length, (index) {
                            return FadeInWidget(
                              delay: Duration(milliseconds: 150 + (index * 50)),
                              child: _ExerciseListItem(
                                data: exercises[index],
                                onTap: () {
                                  // Marcar como completado (solo visual)
                                  setState(() {});
                                },
                                onEdit: () {
                                  // Abrir editor de sets/reps
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botón de completar
                    FadeInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: QuantumButton(
                        label: 'COMPLETE WORKOUT',
                        onPressed: () => widget.onComplete?.call(),
                        width: double.infinity,
                        icon: Icons.check_circle_outline,
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Navegación inferior
      bottomNavigationBar: QuantumBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            widget.onBack?.call();
          }
        },
        items: const [
          NavigationItem(icon: Icons.home_outlined, label: 'Home'),
          NavigationItem(icon: Icons.fitness_center, label: 'Workout'),
          NavigationItem(icon: Icons.analytics_outlined, label: 'Stats'),
          NavigationItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          QuantumIconButton(
            icon: Icons.arrow_back,
            onPressed: () => widget.onBack?.call(),
            showBackground: true,
          ),
          Column(
            children: [
              Text(
                widget.workoutName.toUpperCase(),
                style: QuantumTypography.h4.copyWith(
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Workout in progress',
                style: QuantumTypography.caption.copyWith(
                  color: QuantumColors.quantumBlue,
                ),
              ),
            ],
          ),
          QuantumIconButton(
            icon: Icons.more_vert,
            onPressed: () => _showWorkoutMenu(context),
            showBackground: true,
          ),
        ],
      ),
    );
  }

  void _showWorkoutMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: QuantumColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white70),
                title: const Text('Reiniciar entrenamiento', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _sets = 4;
                    _reps = 12;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text('Cancelar entrenamiento', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onBack?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseData {
  final String name;
  final String sets;
  final String prescribedSets;
  final String weight;
  final bool isCompleted;
  final String? imageUrl = null;
  final String? trainerNotes;

  _ExerciseData({
    required this.name,
    required this.sets,
    this.prescribedSets = '3x12',
    required this.weight,
    required this.isCompleted,
    this.trainerNotes,
  });
}

class _ExerciseListItem extends StatefulWidget {
  final _ExerciseData data;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ExerciseListItem({
    required this.data,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<_ExerciseListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () => _controller.reverse(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QuantumColors.voidGray.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.data.isCompleted
                      ? QuantumColors.matrixCyan.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Imagen del ejercicio
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: QuantumColors.voidGray,
                      border: Border.all(
                        color: widget.data.isCompleted 
                            ? QuantumColors.matrixCyan.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.data.imageUrl != null
                          ? Image.network(
                              widget.data.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => Icon(Icons.fitness_center, color: QuantumColors.textSecondary),
                            )
                          : Icon(Icons.fitness_center, color: QuantumColors.textSecondary),
                    ),
                  ),

                  // Indicador de estado (CHECK)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.data.isCompleted
                          ? QuantumColors.matrixCyan
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.data.isCompleted
                            ? QuantumColors.matrixCyan
                            : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: widget.data.isCompleted
                          ? [
                              BoxShadow(
                                color: QuantumColors.matrixCyan.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: widget.data.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: QuantumColors.cosmicBlack,
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Información del ejercicio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.name,
                          style: QuantumTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: widget.data.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.data.isCompleted
                                ? QuantumColors.textSecondary
                                : QuantumColors.nebulaWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PREESCRITO: ${widget.data.prescribedSets}',
                                  style: QuantumTypography.label.copyWith(
                                    fontSize: 9,
                                    color: QuantumColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.data.sets,
                                      style: QuantumTypography.data.copyWith(
                                        fontSize: 12,
                                        color: widget.data.isCompleted ? QuantumColors.matrixCyan : QuantumColors.quantumBlue,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Text(
                                      widget.data.weight,
                                      style: QuantumTypography.bodySmall.copyWith(
                                        color: QuantumColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (widget.data.trainerNotes != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: QuantumColors.quantumBlue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: const Border(left: BorderSide(color: QuantumColors.quantumBlue, width: 2)),
                            ),
                            child: Text(
                              widget.data.trainerNotes!,
                              style: QuantumTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: QuantumColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botón de editar
                  QuantumIconButton(
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                    size: 40,
                    showBackground: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
