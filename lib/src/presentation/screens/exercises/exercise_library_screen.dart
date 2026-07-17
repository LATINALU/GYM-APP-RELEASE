/// Exercise Library Screen - Browse and search all exercises
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../theme/theme.dart';
import '../../../domain/data/dataset_exercise_catalog.dart';
import '../../../domain/entities/gym_exercise.dart';
import '../../../domain/ports/output/exercise_media_port.dart';
import '../../widgets/exercise/exercise_gif_view.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _searchQuery = '';
  MuscleGroup? _selectedMuscle;
  Equipment? _selectedEquipment;
  ExerciseDifficulty? _selectedDifficulty;

  List<GymExercise> get _filteredExercises {
    var exercises = ExerciseLibrary.all;
    
    if (_selectedMuscle != null) {
      exercises = exercises.where((e) => 
        e.primaryMuscle == _selectedMuscle || e.secondaryMuscles.contains(_selectedMuscle)
      ).toList();
    }
    
    if (_selectedEquipment != null) {
      exercises = exercises.where((e) => e.equipment == _selectedEquipment).toList();
    }
    
    if (_selectedDifficulty != null) {
      exercises = exercises.where((e) => e.difficulty == _selectedDifficulty).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      exercises = exercises.where((e) => 
        e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.primaryMuscle.displayName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ejercicios',
          style: QuantumTypography.h1.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white70),
            tooltip: 'Descargar biblioteca para uso sin internet',
            onPressed: _downloadFullLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: QuantumColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Active Filters
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedMuscle != null)
                      _FilterChip(
                        label: _selectedMuscle!.displayName,
                        onRemove: () => setState(() => _selectedMuscle = null),
                      ),
                    if (_selectedEquipment != null)
                      _FilterChip(
                        label: _selectedEquipment!.displayName,
                        onRemove: () => setState(() => _selectedEquipment = null),
                      ),
                    if (_selectedDifficulty != null)
                      _FilterChip(
                        label: _selectedDifficulty!.displayName,
                        onRemove: () => setState(() => _selectedDifficulty = null),
                      ),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpiar', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ),

          // Muscle Group Quick Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickFilterChip(
                  label: 'Todos',
                  isSelected: _selectedMuscle == null,
                  onTap: () => setState(() => _selectedMuscle = null),
                ),
                ...MuscleGroup.values.take(6).map((m) => _QuickFilterChip(
                  label: m.displayName,
                  emoji: m.icon,
                  isSelected: _selectedMuscle == m,
                  onTap: () => setState(() => _selectedMuscle = m),
                )),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredExercises.length} ejercicios',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                const Text(
                  'Por músculo',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // Exercise List
          Expanded(
            child: _filteredExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return _ExerciseListTile(
                        exercise: exercise,
                        onTap: () => _showExerciseDetails(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters => 
      _selectedMuscle != null || 
      _selectedEquipment != null || 
      _selectedDifficulty != null;

  void _clearFilters() {
    setState(() {
      _selectedMuscle = null;
      _selectedEquipment = null;
      _selectedDifficulty = null;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No se encontraron ejercicios',
            style: QuantumTypography.h3.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFullLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        title: const Text('Descargar biblioteca completa',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se descargarán los GIFs de los 1,324 ejercicios (~130 MB) para que '
          'toda la biblioteca funcione sin internet. Se recomienda usar WiFi.\n\n'
          'Nota: los ejercicios de tus rutinas se descargan automáticamente; '
          'esto es opcional para tener el catálogo completo offline.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: QuantumColors.quantumBlue),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final media = GetIt.I<ExerciseMediaPort>();
    final urls = DatasetExerciseCatalog.exercises
        .map((e) => e.gifUrl)
        .whereType<String>();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        title: const Text('Descargando ejercicios…',
            style: TextStyle(color: Colors.white)),
        content: StreamBuilder<double>(
          stream: media.downloadFullLibrary(urls),
          builder: (ctx, snapshot) {
            final progress = snapshot.data ?? 0.0;
            if (snapshot.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: QuantumColors.quantumBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FiltersSheet(
        selectedMuscle: _selectedMuscle,
        selectedEquipment: _selectedEquipment,
        selectedDifficulty: _selectedDifficulty,
        onApply: (muscle, equipment, difficulty) {
          setState(() {
            _selectedMuscle = muscle;
            _selectedEquipment = equipment;
            _selectedDifficulty = difficulty;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showExerciseDetails(GymExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExerciseDetailsSheet(exercise: exercise),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final GymExercise exercise;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuantumColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Thumbnail del ejercicio (offline, empaquetado en assets)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExerciseGifView(
                gifUrl: exercise.gifUrl,
                exerciseKey: exercise.id,
                animated: false,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        exercise.primaryMuscle.displayName,
                        style: const TextStyle(color: QuantumColors.quantumBlue, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        exercise.equipment.displayName,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.difficulty.displayName,
                          style: TextStyle(
                            color: _getDifficultyColor(exercise.difficulty),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (exercise.isCompound) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COMPUESTO',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return Colors.green;
      case ExerciseDifficulty.intermediate:
        return Colors.orange;
      case ExerciseDifficulty.advanced:
        return Colors.red;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: QuantumColors.quantumBlue, fontSize: 12),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: QuantumColors.quantumBlue),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? QuantumColors.quantumBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? QuantumColors.quantumBlue : Colors.white30,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final MuscleGroup? selectedMuscle;
  final Equipment? selectedEquipment;
  final ExerciseDifficulty? selectedDifficulty;
  final Function(MuscleGroup?, Equipment?, ExerciseDifficulty?) onApply;

  const _FiltersSheet({
    this.selectedMuscle,
    this.selectedEquipment,
    this.selectedDifficulty,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late MuscleGroup? _muscle;
  late Equipment? _equipment;
  late ExerciseDifficulty? _difficulty;

  @override
  void initState() {
    super.initState();
    _muscle = widget.selectedMuscle;
    _equipment = widget.selectedEquipment;
    _difficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: QuantumColors.cosmicBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
            'Filtros',
            style: QuantumTypography.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Muscle Group
          const Text('Grupo Muscular', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MuscleGroup.values.map((m) => _SelectableChip(
              label: '${m.icon} ${m.displayName}',
              isSelected: _muscle == m,
              onTap: () => setState(() => _muscle = _muscle == m ? null : m),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Equipment
          const Text('Equipamiento', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Equipment.values.take(6).map((e) => _SelectableChip(
              label: e.displayName,
              isSelected: _equipment == e,
              onTap: () => setState(() => _equipment = _equipment == e ? null : e),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Difficulty
          const Text('Dificultad', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          Row(
            children: ExerciseDifficulty.values.map((d) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _difficulty = _difficulty == d ? null : d),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _difficulty == d 
                        ? _getDifficultyColor(d).withValues(alpha: 0.2) 
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _difficulty == d 
                          ? _getDifficultyColor(d) 
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d.displayName,
                      style: TextStyle(
                        color: _difficulty == d ? _getDifficultyColor(d) : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
          
          const Spacer(),
          
          // Apply Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _muscle = null;
                      _equipment = null;
                      _difficulty = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('LIMPIAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_muscle, _equipment, _difficulty),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumColors.quantumBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('APLICAR FILTROS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return Colors.green;
      case ExerciseDifficulty.intermediate:
        return Colors.orange;
      case ExerciseDifficulty.advanced:
        return Colors.red;
    }
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ExerciseDetailsSheet extends StatelessWidget {
  final GymExercise exercise;

  const _ExerciseDetailsSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: QuantumColors.cosmicBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GIF animado del ejercicio (local si está descargado)
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExerciseGifView(
                        gifUrl: exercise.gifUrl,
                        exerciseKey: exercise.id,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: QuantumTypography.h2.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.primaryMuscle.displayName,
                              style: const TextStyle(color: QuantumColors.quantumBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        label: exercise.equipment.displayName,
                        icon: Icons.fitness_center,
                      ),
                      _Tag(
                        label: exercise.difficulty.displayName,
                        color: _getDifficultyColor(exercise.difficulty),
                      ),
                      _Tag(
                        label: exercise.pattern.displayName,
                      ),
                      if (exercise.isCompound)
                        const _Tag(label: 'Compuesto', color: Colors.amber),
                      if (exercise.requiresSpotter)
                        const _Tag(label: 'Requiere Spotter', color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Descripción',
                    style: QuantumTypography.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.description,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Secondary Muscles
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    Text(
                      'Músculos Secundarios',
                      style: QuantumTypography.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.secondaryMuscles.map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${m.icon} ${m.displayName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Instructions
                  if (exercise.instructions.isNotEmpty) ...[
                    Text(
                      'Instrucciones',
                      style: QuantumTypography.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ...exercise.instructions.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: const TextStyle(
                                  color: QuantumColors.quantumBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(color: Colors.white70, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Tips
                  if (exercise.tips.isNotEmpty) ...[
                    Text(
                      'Consejos',
                      style: QuantumTypography.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ...exercise.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Common Mistakes
                  if (exercise.commonMistakes.isNotEmpty) ...[
                    Text(
                      'Errores Comunes',
                      style: QuantumTypography.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ...exercise.commonMistakes.map((mistake) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mistake,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  
                  // Variations
                  if (exercise.variations.isNotEmpty) ...[
                    Text(
                      'Variaciones',
                      style: QuantumTypography.h4.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.variations.map((v) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          v,
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return Colors.green;
      case ExerciseDifficulty.intermediate:
        return Colors.orange;
      case ExerciseDifficulty.advanced:
        return Colors.red;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _Tag({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? Colors.white60),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
