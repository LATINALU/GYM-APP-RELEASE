import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/routine_bloc.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/data/exercise_catalog.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../widgets/exercise/exercise_gif_view.dart';
import '../../../domain/ports/input/manage_routine_usecase_port.dart'; // Import necesario para RoutineExerciseInput

/// Página de edición/creación de rutinas
class RoutineEditorPage extends StatelessWidget {
  final String userId;
  
  const RoutineEditorPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineState>(
      builder: (context, state) {
        if (state is ExerciseBrowsing) {
          return _ExerciseBrowserView(
            state: state,
            onBack: () => context.read<RoutineBloc>().add(CloseExerciseBrowser()),
          );
        }
        
        if (state is RoutineEditing) {
          return _RoutineEditorView(
            state: state,
            userId: userId,
            onBack: () => context.read<RoutineBloc>().add(LoadRoutines()),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}

class _RoutineEditorView extends StatelessWidget {
  final RoutineEditing state;
  final String userId;
  final VoidCallback onBack;

  const _RoutineEditorView({
    required this.state,
    required this.userId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = state.existingRoutine != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onBack,
        ),
        title: Text(isEditing ? 'Editar Rutina' : 'Nueva Rutina'),
        actions: [
          if (state.isValid)
            TextButton.icon(
              onPressed: () {
                context.read<RoutineBloc>().add(SaveRoutine(UserId(userId)));
              },
              icon: const Icon(Icons.check, color: Color(0xFF10B981)),
              label: const Text(
                'Guardar',
                style: TextStyle(color: Color(0xFF10B981)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            _buildTextField(
              context,
              label: 'Nombre de la rutina',
              value: state.name,
              hint: 'Ej: Push Day - Pecho y Hombros',
              onChanged: (v) => context.read<RoutineBloc>().add(UpdateRoutineName(v)),
            ),
            const SizedBox(height: 16),
            
            // Descripción
            _buildTextField(
              context,
              label: 'Descripción (opcional)',
              value: state.description,
              hint: 'Describe el objetivo de esta rutina',
              maxLines: 3,
              onChanged: (v) => context.read<RoutineBloc>().add(UpdateRoutineDescription(v)),
            ),
            const SizedBox(height: 16),
            
            // Dificultad
            _buildDifficultySelector(context, state.difficulty),
            const SizedBox(height: 24),
            
            // Stats
            _buildStats(state),
            const SizedBox(height: 24),
            
            // Ejercicios
            _buildExercisesHeader(context),
            const SizedBox(height: 12),
            
            if (state.exercises.isEmpty)
              _buildEmptyExercises(context)
            else
              _buildExercisesList(context, state.exercises),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDifficultySelector(BuildContext context, DifficultyLevel current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dificultad',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: DifficultyLevel.values.map((level) {
            final isSelected = level == current;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  context.read<RoutineBloc>().add(UpdateRoutineDifficulty(level));
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? _getDifficultyColor(level).withValues(alpha: 0.2)
                        : const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? _getDifficultyColor(level)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getDifficultyIcon(level),
                        color: isSelected 
                            ? _getDifficultyColor(level)
                            : Colors.white54,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.displayName,
                        style: TextStyle(
                          color: isSelected 
                              ? _getDifficultyColor(level)
                              : Colors.white54,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStats(RoutineEditing state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '${state.exercises.length}',
            label: 'Ejercicios',
          ),
          _buildStatItem(
            icon: Icons.repeat,
            value: '${state.totalSets}',
            label: 'Series totales',
          ),
          _buildStatItem(
            icon: Icons.timer,
            value: '~${state.estimatedMinutes}',
            label: 'Minutos',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildExercisesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Ejercicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            context.read<RoutineBloc>().add(OpenExerciseBrowser());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar'),
        ),
      ],
    );
  }

  Widget _buildEmptyExercises(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF374151),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin ejercicios',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.read<RoutineBloc>().add(OpenExerciseBrowser());
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6366F1)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar ejercicio'),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context, List<RoutineExerciseInput> exercises) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      onReorderItem: (oldIndex, newIndex) {
        context.read<RoutineBloc>().add(ReorderExercises(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        return _ExerciseListItem(
          key: ValueKey(exercises[index].templateId + index.toString()),
          exercise: exercises[index],
          index: index,
          onRemove: () {
            context.read<RoutineBloc>().add(RemoveExerciseFromRoutine(index));
          },
          onUpdate: (sets, minReps, maxReps, rest) {
            context.read<RoutineBloc>().add(UpdateExerciseInRoutine(
              index: index,
              sets: sets,
              minReps: minReps,
              maxReps: maxReps,
              restSeconds: rest,
            ));
          },
        );
      },
    );
  }

  Color _getDifficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return const Color(0xFF10B981);
      case DifficultyLevel.intermediate:
        return const Color(0xFFF59E0B);
      case DifficultyLevel.advanced:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getDifficultyIcon(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return Icons.star_border;
      case DifficultyLevel.intermediate:
        return Icons.star_half;
      case DifficultyLevel.advanced:
        return Icons.star;
    }
  }
}

class _ExerciseListItem extends StatelessWidget {
  final RoutineExerciseInput exercise;
  final int index;
  final VoidCallback onRemove;
  final Function(int?, int?, int?, int?) onUpdate;

  const _ExerciseListItem({
    super.key,
    required this.exercise,
    required this.index,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final template = ExerciseCatalog.byId(exercise.templateId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            const Icon(Icons.drag_handle, color: Colors.white38),
            const SizedBox(width: 8),

            // GIF/Imagen (offline-first)
            ExerciseGifView(
              exerciseKey: exercise.templateId,
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template?.displayName ?? exercise.templateId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template?.primaryMuscle.displayName ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Sets x Reps
                  Row(
                    children: [
                      _buildCompactInput(
                        value: exercise.sets,
                        label: 'Series',
                        onChanged: (v) => onUpdate(v, null, null, null),
                      ),
                      const SizedBox(width: 8),
                      const Text('×', style: TextStyle(color: Colors.white54)),
                      const SizedBox(width: 8),
                      _buildCompactInput(
                        value: exercise.minReps,
                        label: 'Min',
                        onChanged: (v) => onUpdate(null, v, null, null),
                      ),
                      const Text('-', style: TextStyle(color: Colors.white54)),
                      _buildCompactInput(
                        value: exercise.maxReps,
                        label: 'Max',
                        onChanged: (v) => onUpdate(null, null, v, null),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactInput(
                        value: exercise.restSeconds,
                        label: 's',
                        width: 50,
                        onChanged: (v) => onUpdate(null, null, null, v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInput({
    required int value,
    required String label,
    double width = 40,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        controller: TextEditingController(text: value.toString()),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: const Color(0xFF374151),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }
}

/// Vista del explorador de ejercicios
class _ExerciseBrowserView extends StatelessWidget {
  final ExerciseBrowsing state;
  final VoidCallback onBack;

  const _ExerciseBrowserView({
    required this.state,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('Seleccionar Ejercicio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) {
                context.read<RoutineBloc>().add(SearchExercises(v));
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros por músculo
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildFilterChip(
                  context,
                  label: 'Todos',
                  isSelected: state.muscleFilter == null,
                  onTap: () => context.read<RoutineBloc>().add(
                    const FilterExercisesByMuscle(null),
                  ),
                ),
                ...MuscleGroup.values.take(10).map((muscle) => _buildFilterChip(
                  context,
                  label: muscle.displayName,
                  isSelected: state.muscleFilter == muscle,
                  onTap: () => context.read<RoutineBloc>().add(
                    FilterExercisesByMuscle(muscle),
                  ),
                )),
              ],
            ),
          ),
          
          // Lista de ejercicios
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.filteredExercises.length,
              itemBuilder: (context, index) {
                return _ExerciseCard(
                  exercise: state.filteredExercises[index],
                  onTap: () => _showAddExerciseDialog(
                    context,
                    state.filteredExercises[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF6366F1),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
        backgroundColor: const Color(0xFF374151),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, ExerciseTemplate exercise) {
    int sets = 3;
    int minReps = 8;
    int maxReps = 12;
    int rest = 90;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  ExerciseGifView(
                    gifUrl: exercise.gifUrl,
                    exerciseKey: exercise.id,
                    thumbAsset: exercise.thumbAsset,
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          exercise.primaryMuscle.displayName,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Configuración
              Row(
                children: [
                  Expanded(
                    child: _NumberPicker(
                      label: 'Series',
                      value: sets,
                      min: 1,
                      max: 10,
                      onChanged: (v) => setState(() => sets = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NumberPicker(
                      label: 'Min Reps',
                      value: minReps,
                      min: 1,
                      max: 50,
                      onChanged: (v) => setState(() => minReps = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NumberPicker(
                      label: 'Max Reps',
                      value: maxReps,
                      min: 1,
                      max: 50,
                      onChanged: (v) => setState(() => maxReps = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _NumberPicker(
                label: 'Descanso (segundos)',
                value: rest,
                min: 30,
                max: 300,
                step: 15,
                onChanged: (v) => setState(() => rest = v),
              ),
              const SizedBox(height: 24),
              
              // Botón agregar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<RoutineBloc>().add(AddExerciseToRoutine(
                      exercise: exercise,
                      sets: sets,
                      minReps: minReps,
                      maxReps: maxReps,
                      restSeconds: rest,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Agregar a la Rutina',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

class _ExerciseCard extends StatelessWidget {
  final ExerciseTemplate exercise;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail estático (rápido en grillas, disponible offline)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: ExerciseGifView(
                    gifUrl: exercise.gifUrl,
                    exerciseKey: exercise.id,
                    thumbAsset: exercise.thumbAsset,
                    animated: false,
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise.primaryMuscle.displayName,
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        exercise.isCompound ? Icons.merge_type : Icons.adjust,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white54),
                onPressed: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white54),
                onPressed: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
