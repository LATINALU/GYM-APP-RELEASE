import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/routine_bloc.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/data/exercise_gifs.dart';
import '../../../domain/value_objects/value_objects.dart'; // Import para UserId
import 'routine_editor_page.dart';

/// Página principal de gestión de rutinas para Admin/Empleados
class RoutineManagementPage extends StatelessWidget {
  final VoidCallback? onBack;
  final String userId;

  const RoutineManagementPage({super.key, this.onBack, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        leading:
            onBack != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                )
                : null,
        title: const Text(
          'Gestión de Rutinas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final state = context.read<RoutineBloc>().state;
              if (state is! RoutinesLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Carga las rutinas antes de buscar.'),
                  ),
                );
                return;
              }

              final selected = await showSearch<WorkoutRoutine?>(
                context: context,
                delegate: _RoutineSearchDelegate(state.routines),
              );

              if (selected != null && context.mounted) {
                context.read<RoutineBloc>().add(StartEditingRoutine(selected));
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<RoutineBloc, RoutineState>(
        listener: (context, state) {
          if (state is RoutineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is RoutineSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.read<RoutineBloc>().add(LoadRoutines());
          }
        },
        builder: (context, state) {
          if (state is RoutineLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          if (state is RoutinesLoaded) {
            return _buildRoutinesList(context, state);
          }

          if (state is RoutineEditing || state is ExerciseBrowsing) {
            return RoutineEditorPage(userId: userId);
          }

          // Initial state - load routines
          context.read<RoutineBloc>().add(LoadRoutines());
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        },
      ),
      floatingActionButton: BlocBuilder<RoutineBloc, RoutineState>(
        builder: (context, state) {
          if (state is RoutinesLoaded) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.read<RoutineBloc>().add(StartCreatingRoutine());
              },
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Rutina'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRoutinesList(BuildContext context, RoutinesLoaded state) {
    if (state.routines.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Filtros
        _buildFilters(context, state),

        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.routines.length,
            itemBuilder: (context, index) {
              return _buildRoutineCard(context, state.routines[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, RoutinesLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        border: Border(bottom: BorderSide(color: Color(0xFF374151))),
      ),
      child: Row(
        children: [
          const Text('Filtrar:', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          ...DifficultyLevel.values.map((level) {
            final isSelected = state.filterDifficulty == level.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(level.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  context.read<RoutineBloc>().add(
                    FilterRoutinesByDifficulty(selected ? level : null),
                  );
                },
                selectedColor: const Color(0xFF6366F1),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                backgroundColor: const Color(0xFF374151),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, WorkoutRoutine routine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context.read<RoutineBloc>().add(StartEditingRoutine(routine));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono de dificultad
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        routine.difficulty,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDifficultyIcon(routine.difficulty),
                      color: _getDifficultyColor(routine.difficulty),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          routine.difficulty.displayName,
                          style: TextStyle(
                            color: _getDifficultyColor(routine.difficulty),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF374151),
                    onSelected: (value) {
                      _handleMenuAction(context, value, routine);
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white70),
                                SizedBox(width: 8),
                                Text(
                                  'Editar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, color: Colors.white70),
                                SizedBox(width: 8),
                                Text(
                                  'Duplicar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              if (routine.description != null &&
                  routine.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  routine.description!,
                  style: const TextStyle(color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              // Stats
              Row(
                children: [
                  _buildStatChip(
                    Icons.fitness_center,
                    '${routine.exerciseCount} ejercicios',
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(Icons.timer, routine.durationDisplay),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.category,
                    '${routine.targetedMuscles.length} músculos',
                  ),
                ],
              ),
              // Preview de ejercicios
              if (routine.hasExercises) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: routine.exercises.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final exercise = routine.exercises[index];
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF374151),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ExerciseGifs.getGifUrl(exercise.name) ??
                                ExerciseGifs.placeholder,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: Colors.white38,
                                  ),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay rutinas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primera rutina para empezar',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<RoutineBloc>().add(StartCreatingRoutine());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Crear Rutina'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    WorkoutRoutine routine,
  ) {
    switch (action) {
      case 'edit':
        context.read<RoutineBloc>().add(StartEditingRoutine(routine));
        break;
      case 'duplicate':
        _showDuplicateDialog(context, routine);
        break;
      case 'delete':
        _showDeleteDialog(context, routine);
        break;
    }
  }

  void _showDuplicateDialog(BuildContext context, WorkoutRoutine routine) {
    final controller = TextEditingController(text: '${routine.name} (copia)');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Duplicar Rutina',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre de la copia',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // ignore: use_build_context_synchronously
                  context.read<RoutineBloc>().add(
                    DuplicateRoutineRequested(
                      routine.id,
                      controller.text,
                      UserId(userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text('Duplicar'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(BuildContext context, WorkoutRoutine routine) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              'Eliminar Rutina',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '¿Estás seguro de eliminar "${routine.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // ignore: use_build_context_synchronously
                  context.read<RoutineBloc>().add(
                    DeleteRoutineRequested(routine.id, UserId(userId)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
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

class _RoutineSearchDelegate extends SearchDelegate<WorkoutRoutine?> {
  final List<WorkoutRoutine> routines;

  _RoutineSearchDelegate(this.routines);

  @override
  String get searchFieldLabel =>
      'Buscar rutina por nombre, enfoque o descripción';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final filtered =
        normalized.isEmpty
            ? routines
            : routines.where((routine) {
              final description = routine.description?.toLowerCase() ?? '';
              return routine.name.toLowerCase().contains(normalized) ||
                  routine.difficulty.displayName.toLowerCase().contains(
                    normalized,
                  ) ||
                  description.contains(normalized);
            }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron rutinas con ese criterio.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final routine = filtered[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center, color: Color(0xFF6366F1)),
          title: Text(routine.name),
          subtitle: Text(routine.difficulty.displayName),
          onTap: () => close(context, routine),
        );
      },
    );
  }
}
