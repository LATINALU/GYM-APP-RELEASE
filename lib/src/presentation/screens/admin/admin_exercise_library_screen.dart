import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/mappers/exercise_mapper.dart';
import '../../theme/quantum_colors.dart';

/// Biblioteca Global de Ejercicios - Super Admin
/// Admin crea ejercicios con imágenes que todos los Owners pueden usar
class AdminExerciseLibraryScreen extends StatefulWidget {
  const AdminExerciseLibraryScreen({super.key});

  @override
  State<AdminExerciseLibraryScreen> createState() => _AdminExerciseLibraryScreenState();
}

class _AdminExerciseLibraryScreenState extends State<AdminExerciseLibraryScreen> {
  String _filterMuscle = 'Todos';
  final _searchController = TextEditingController();
  bool _showCreateForm = false;
  final List<Exercise> _exercises = [];
  bool _isLoadingExercises = true;
  bool _isSavingExercise = false;
  String? _loadError;

  // Form controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  MovementPattern _selectedPattern = MovementPattern.horizontalPush;
  ExerciseType _selectedType = ExerciseType.compound;
  ExerciseDifficulty _selectedDifficulty = ExerciseDifficulty.intermediate;
  final List<EquipmentType> _selectedEquipment = [EquipmentType.barbell];
  MuscleGroup _selectedPrimaryMuscle = MuscleGroup.chest;

  List<Exercise> get _filteredExercises {
    var filtered = _exercises;
    if (_filterMuscle != 'Todos') {
      filtered = filtered.where((e) => e.primaryMuscle.displayName == _filterMuscle).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.description.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingExercises = true;
      _loadError = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('exercises')
              .where('isActive', isEqualTo: true)
              .get();

      final exercises =
          snapshot.docs
              .map((doc) => ExerciseMapper.fromFirestore(doc.data(), doc.id))
              .where((exercise) => exercise.scope == ExerciseScope.global)
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      setState(() {
        _exercises
          ..clear()
          ..addAll(exercises);
        _isLoadingExercises = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar los ejercicios globales.';
        _isLoadingExercises = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: _showCreateForm ? _buildCreateForm() : _buildLibraryView(),
    );
  }

  Widget _buildLibraryView() {
    if (_isLoadingExercises) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExercises,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          _buildExerciseGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIBLIOTECA DE EJERCICIOS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Ejercicios globales disponibles para todos los gimnasios', style: TextStyle(color: Colors.white38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showCreateForm = true),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Crear Ejercicio'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard('Total Ejercicios', '${_exercises.length}', Icons.fitness_center_rounded, const Color(0xFFFF6B35)),
        const SizedBox(width: 16),
        _buildStatCard('Con Imagen', '${_exercises.where((e) => e.imageUrl != null).length}', Icons.image_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _buildStatCard('Compuestos', '${_exercises.where((e) => e.exerciseType == ExerciseType.compound).length}', Icons.hub_rounded, const Color(0xFF6366F1)),
        const SizedBox(width: 16),
        _buildStatCard('Aislamiento', '${_exercises.where((e) => e.exerciseType == ExerciseType.isolation).length}', Icons.adjust_rounded, const Color(0xFF00E0FF)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: QuantumColors.surface(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 22)),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final muscles = ['Todos', ...MuscleGroup.values.take(14).map((m) => m.displayName)];
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar ejercicio...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
              filled: true,
              fillColor: QuantumColors.surface(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: muscles.take(8).map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m),
                  selected: _filterMuscle == m,
                  onSelected: (_) => setState(() => _filterMuscle = m),
                  selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                  backgroundColor: QuantumColors.surface(),
                  labelStyle: TextStyle(color: _filterMuscle == m ? const Color(0xFFFF6B35) : Colors.white38, fontSize: 11),
                  side: BorderSide(color: _filterMuscle == m ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseGrid() {
    final exercises = _filteredExercises;
    if (exercises.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: Colors.white12, size: 64),
              SizedBox(height: 16),
              Text('No se encontraron ejercicios', style: TextStyle(color: Colors.white24)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) => _buildExerciseCard(exercises[index]),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: exercise.imageUrl != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_rounded, color: const Color(0xFFFF6B35).withValues(alpha: 0.5), size: 40),
                        const SizedBox(height: 4),
                        const Text('Imagen cargada', style: TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: Colors.white12, size: 40),
                        SizedBox(height: 4),
                        Text('Sin imagen', style: TextStyle(color: Colors.white12, fontSize: 10)),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(exercise.description, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(exercise.primaryMuscle.displayName, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(exercise.difficulty.displayName, style: const TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showExerciseDetail(exercise),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white60,
                            side: const BorderSide(color: Colors.white10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Editar', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: IconButton(
                          onPressed: () => _confirmDeleteExercise(context, exercise),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          tooltip: 'Eliminar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(exercise.name, style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 22)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Descripción', exercise.description),
              if (exercise.instructions != null) _detailRow('Instrucciones', exercise.instructions!),
              _detailRow('Patrón', exercise.movementPattern.displayName),
              _detailRow('Tipo', exercise.exerciseType.displayName),
              _detailRow('Dificultad', exercise.difficulty.displayName),
              _detailRow('Músculo Principal', exercise.primaryMuscle.displayName),
              _detailRow('Equipamiento', exercise.equipment.map((e) => e.displayName).join(', ')),
              _detailRow('Alcance', exercise.scope.displayName),
              _detailRow('Imagen', exercise.imageUrl ?? 'Sin imagen'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE EXERCISE FORM
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showCreateForm = false),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60),
              ),
              const SizedBox(width: 12),
              Text('CREAR EJERCICIO GLOBAL', style: QuantumTypography.h1.copyWith(fontSize: 28, letterSpacing: -1, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Text('Este ejercicio estará disponible para todos los gimnasios de la plataforma', style: TextStyle(color: Colors.white38)),
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Basic info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 16),
                    _buildFormField('Nombre del Ejercicio', _nameController, 'Ej: Press de Banca Inclinado'),
                    const SizedBox(height: 16),
                    _buildFormField('Descripción', _descController, 'Descripción breve del ejercicio', maxLines: 3),
                    const SizedBox(height: 16),
                    _buildFormField('Instrucciones', _instructionsController, 'Pasos detallados para ejecutar el ejercicio', maxLines: 5),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Imagen del Ejercicio'),
                    const SizedBox(height: 16),
                    _buildImageUploadArea(),
                    const SizedBox(height: 16),
                    _buildFormField('URL de Imagen (alternativa)', _imageUrlController, 'https://...'),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right column: Classification
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Clasificación'),
                    const SizedBox(height: 16),
                    _buildDropdown<MovementPattern>(
                      'Patrón de Movimiento',
                      _selectedPattern,
                      MovementPattern.values,
                      (v) => v.displayName,
                      (v) => setState(() => _selectedPattern = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<ExerciseType>(
                      'Tipo de Ejercicio',
                      _selectedType,
                      ExerciseType.values,
                      (v) => v.displayName,
                      (v) => setState(() => _selectedType = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<ExerciseDifficulty>(
                      'Dificultad',
                      _selectedDifficulty,
                      ExerciseDifficulty.values,
                      (v) => v.displayName,
                      (v) => setState(() => _selectedDifficulty = v),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<MuscleGroup>(
                      'Músculo Principal',
                      _selectedPrimaryMuscle,
                      MuscleGroup.values.where((m) => m != MuscleGroup.fullBody).toList(),
                      (v) => v.displayName,
                      (v) => setState(() => _selectedPrimaryMuscle = v),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Equipamiento'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EquipmentType.values.map((eq) => FilterChip(
                        label: Text(eq.displayName),
                        selected: _selectedEquipment.contains(eq),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(eq);
                            } else {
                              _selectedEquipment.remove(eq);
                            }
                          });
                        },
                        selectedColor: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        backgroundColor: QuantumColors.surface(),
                        labelStyle: TextStyle(
                          color: _selectedEquipment.contains(eq) ? const Color(0xFFFF6B35) : Colors.white38,
                          fontSize: 11,
                        ),
                        side: BorderSide(
                          color: _selectedEquipment.contains(eq) ? const Color(0xFFFF6B35).withValues(alpha: 0.3) : Colors.white10,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showCreateForm = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isSavingExercise ? null : _createExercise,
                icon: Icon(
                  _isSavingExercise ? Icons.hourglass_top_rounded : Icons.check_rounded,
                  size: 18,
                ),
                label: Text(
                  _isSavingExercise ? 'Guardando...' : 'Crear Ejercicio Global',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16));
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.16), fontSize: 13),
            filled: true,
            fillColor: QuantumColors.surface(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, String Function(T) displayName, ValueChanged<T> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: QuantumColors.surface(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: QuantumColors.surface(),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(displayName(item), style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadArea() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La carga de imagen aún no está disponible en esta pantalla'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: QuantumColors.surface(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_rounded, color: const Color(0xFFFF6B35).withValues(alpha: 0.5), size: 40),
              const SizedBox(height: 12),
              const Text('Arrastra una imagen o haz clic para subir', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 4),
              Text('PNG, JPG hasta 5MB', style: TextStyle(color: Colors.white.withValues(alpha: 0.16), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createExercise() async {
    if (_nameController.text.trim().isEmpty || _isSavingExercise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del ejercicio es requerido'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final profile = AuthStateNotifier.instance.profile;
    final newExercise = Exercise.create(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? 'Sin descripción' : _descController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      movementPattern: _selectedPattern,
      exerciseType: _selectedType,
      difficulty: _selectedDifficulty,
      equipment: _selectedEquipment,
      heatmap: MuscleHeatmap({_selectedPrimaryMuscle.name: 0.9}),
      scope: ExerciseScope.global,
      createdBy: profile?.uid != null ? UserId(profile!.uid) : null,
    );

    setState(() => _isSavingExercise = true);

    try {
      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(newExercise.id.value)
          .set(ExerciseMapper.toFirestore(newExercise));

      if (!mounted) return;

      setState(() {
        _exercises.add(newExercise);
        _exercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isSavingExercise = false;
        _showCreateForm = false;
        _nameController.clear();
        _descController.clear();
        _instructionsController.clear();
        _imageUrlController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ejercicio "${newExercise.name}" creado exitosamente'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSavingExercise = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear el ejercicio global'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _confirmDeleteExercise(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar "${exercise.name}"?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'El ejercicio se marcará como inactivo. No se eliminará permanentemente.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('exercises')
                    .doc(exercise.id.value)
                    .update({'isActive': false});
                if (mounted) {
                  _loadExercises();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('${exercise.name} eliminado'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
