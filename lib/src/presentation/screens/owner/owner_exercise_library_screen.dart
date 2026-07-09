import 'package:flutter/material.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/adapters/firebase/firebase_exercise_repository.dart';
import '../../../infrastructure/config/di.dart';
import '../../theme/quantum_colors.dart';

/// Biblioteca de Ejercicios del Owner
/// Muestra ejercicios globales (Admin) + personalizados del gym
/// El Owner puede crear ejercicios propios con imágenes
class OwnerExerciseLibraryScreen extends StatefulWidget {
  const OwnerExerciseLibraryScreen({super.key});

  @override
  State<OwnerExerciseLibraryScreen> createState() => _OwnerExerciseLibraryScreenState();
}

class _OwnerExerciseLibraryScreenState extends State<OwnerExerciseLibraryScreen> {
  String _activeTab = 'todos';
  String _filterMuscle = 'Todos';
  final _searchController = TextEditingController();
  bool _showCreateForm = false;
  final List<Exercise> _globalExercises = [];
  final List<Exercise> _gymExercises = [];
  bool _isLoadingExercises = true;
  String? _loadError;

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  MovementPattern _selectedPattern = MovementPattern.horizontalPush;
  ExerciseType _selectedType = ExerciseType.compound;
  ExerciseDifficulty _selectedDifficulty = ExerciseDifficulty.intermediate;
  final List<EquipmentType> _selectedEquipment = [EquipmentType.barbell];
  MuscleGroup _selectedPrimaryMuscle = MuscleGroup.chest;

  List<Exercise> get _allExercises => [..._globalExercises, ..._gymExercises];

  List<Exercise> get _filteredExercises {
    List<Exercise> source;
    switch (_activeTab) {
      case 'globales':
        source = _globalExercises;
        break;
      case 'personalizados':
        source = _gymExercises;
        break;
      default:
        source = _allExercises;
    }

    if (_filterMuscle != 'Todos') {
      source = source.where((e) => e.primaryMuscle.displayName == _filterMuscle).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      source = source.where((e) => e.name.toLowerCase().contains(query) || e.description.toLowerCase().contains(query)).toList();
    }
    return source;
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _instructionsCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingExercises = true;
      _loadError = null;
    });

    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      final exerciseRepo = getIt<FirebaseExerciseRepository>();
      final result = await exerciseRepo.getAll();

      final allExercises = result.fold(
        (failure) => throw Exception(failure.message),
        (exercises) => exercises,
      );

      final globalExercises =
          allExercises.where((exercise) => exercise.scope == ExerciseScope.global).toList();
      final gymExercises =
          allExercises
              .where(
                (exercise) =>
                    exercise.scope == ExerciseScope.gym &&
                    exercise.gymId?.value == gymId,
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _globalExercises
          ..clear()
          ..addAll(globalExercises);
        _gymExercises
          ..clear()
          ..addAll(gymExercises);
        _isLoadingExercises = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar los ejercicios.';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTabs(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 24),
          _buildExerciseList(),
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
            Text('EJERCICIOS', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
            const SizedBox(height: 8),
            Text('${_globalExercises.length} globales + ${_gymExercises.length} personalizados', style: const TextStyle(color: Colors.white38)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showCreateForm = true),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Crear Ejercicio Personalizado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.matrixCyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'key': 'todos', 'label': 'Todos (${_allExercises.length})'},
      {'key': 'globales', 'label': 'Globales (${_globalExercises.length})'},
      {'key': 'personalizados', 'label': 'Personalizados (${_gymExercises.length})'},
    ];
    return Row(
      children: tabs.map((t) {
        final isActive = _activeTab == t['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _activeTab = t['key']!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? QuantumColors.matrixCyan.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? QuantumColors.matrixCyan.withValues(alpha: 0.3) : Colors.white10),
              ),
              child: Text(t['label']!, style: TextStyle(color: isActive ? QuantumColors.matrixCyan : Colors.white38, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    final muscles = ['Todos', 'Pectorales', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Cuádriceps', 'Glúteos', 'Abdominales'];
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar ejercicio...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
              filled: true,
              fillColor: QuantumColors.surface(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: muscles.map((m) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(m),
                  selected: _filterMuscle == m,
                  onSelected: (_) => setState(() => _filterMuscle = m),
                  selectedColor: QuantumColors.matrixCyan.withValues(alpha: 0.2),
                  backgroundColor: QuantumColors.surface(),
                  labelStyle: TextStyle(color: _filterMuscle == m ? QuantumColors.matrixCyan : Colors.white38, fontSize: 11),
                  side: BorderSide(color: _filterMuscle == m ? QuantumColors.matrixCyan.withValues(alpha: 0.3) : Colors.white10),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_isLoadingExercises) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
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

    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 52),
                Expanded(flex: 3, child: Text('Ejercicio', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Músculo', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Tipo', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Dificultad', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Alcance', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 80),
              ],
            ),
          ),
          ...exercises.map((e) => _buildExerciseRow(e)),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(Exercise exercise) {
    final isGlobal = exercise.scope == ExerciseScope.global;
    final scopeColor = isGlobal ? const Color(0xFFFF6B35) : QuantumColors.matrixCyan;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          // Image thumbnail
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: exercise.imageUrl != null ? scopeColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: exercise.imageUrl != null
                ? Icon(Icons.image_rounded, color: scopeColor.withValues(alpha: 0.5), size: 18)
                : const Icon(Icons.fitness_center_rounded, color: Colors.white12, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(exercise.description, style: const TextStyle(color: Colors.white30, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(exercise.primaryMuscle.displayName, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(exercise.exerciseType.displayName, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text(exercise.difficulty.displayName, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: scopeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(isGlobal ? 'Global' : 'Mi Gym', style: TextStyle(color: scopeColor, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isGlobal) ...[
                  IconButton(icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white24), onPressed: () => _showEditExerciseDialog(exercise), tooltip: 'Editar'),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent), onPressed: () => _confirmDeleteExercise(exercise), tooltip: 'Eliminar'),
                ] else
                  IconButton(icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white24), onPressed: () => _showExerciseDetail(exercise), tooltip: 'Ver detalle'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CREATE CUSTOM EXERCISE FORM
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _showCreateForm = false), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60)),
              const SizedBox(width: 12),
              Text('CREAR EJERCICIO PERSONALIZADO', style: QuantumTypography.h1.copyWith(fontSize: 28, letterSpacing: -1, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Text('Este ejercicio solo estará disponible en tu gimnasio', style: TextStyle(color: QuantumColors.matrixCyan)),
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildFormCard('Información', [
                  _buildField('Nombre', _nameCtrl, 'Ej: Sentadilla Búlgara Modificada'),
                  const SizedBox(height: 16),
                  _buildField('Descripción', _descCtrl, 'Descripción del ejercicio', maxLines: 3),
                  const SizedBox(height: 16),
                  _buildField('Instrucciones', _instructionsCtrl, 'Pasos para ejecutar', maxLines: 4),
                  const SizedBox(height: 24),
                  const Text('Imagen del Ejercicio', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildImageUpload(),
                  const SizedBox(height: 12),
                  _buildField('URL de Imagen (alternativa)', _imageUrlCtrl, 'https://...'),
                ]),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildFormCard('Clasificación', [
                  _buildDropdown<MovementPattern>('Patrón', _selectedPattern, MovementPattern.values, (v) => v.displayName, (v) => setState(() => _selectedPattern = v)),
                  const SizedBox(height: 12),
                  _buildDropdown<ExerciseType>('Tipo', _selectedType, ExerciseType.values, (v) => v.displayName, (v) => setState(() => _selectedType = v)),
                  const SizedBox(height: 12),
                  _buildDropdown<ExerciseDifficulty>('Dificultad', _selectedDifficulty, ExerciseDifficulty.values, (v) => v.displayName, (v) => setState(() => _selectedDifficulty = v)),
                  const SizedBox(height: 12),
                  _buildDropdown<MuscleGroup>('Músculo Principal', _selectedPrimaryMuscle, MuscleGroup.values.where((m) => m != MuscleGroup.fullBody).toList(), (v) => v.displayName, (v) => setState(() => _selectedPrimaryMuscle = v)),
                  const SizedBox(height: 16),
                  const Text('Equipamiento', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: EquipmentType.values.map((eq) => FilterChip(
                      label: Text(eq.displayName),
                      selected: _selectedEquipment.contains(eq),
                      onSelected: (s) => setState(() { if (s) {
                        _selectedEquipment.add(eq);
                      } else {
                        _selectedEquipment.remove(eq);
                      } }),
                      selectedColor: QuantumColors.matrixCyan.withValues(alpha: 0.2),
                      backgroundColor: QuantumColors.surface(),
                      labelStyle: TextStyle(color: _selectedEquipment.contains(eq) ? QuantumColors.matrixCyan : Colors.white38, fontSize: 10),
                      side: BorderSide(color: _selectedEquipment.contains(eq) ? QuantumColors.matrixCyan.withValues(alpha: 0.3) : Colors.white10),
                    )).toList(),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _showCreateForm = false),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white60, side: const BorderSide(color: Colors.white10), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _createGymExercise,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Crear Ejercicio'),
                style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.matrixCyan, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: QuantumColors.surface(), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.16)),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: QuantumColors.matrixCyan)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _buildDropdown<T>(String label, T value, List<T> items, String Function(T) displayName, ValueChanged<T> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
        child: DropdownButton<T>(
          value: value, isExpanded: true, dropdownColor: QuantumColors.surface(), underline: const SizedBox(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(displayName(i), style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    ]);
  }

  Widget _buildImageUpload() {
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
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QuantumColors.matrixCyan.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_upload_rounded, color: QuantumColors.matrixCyan.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            const Text('Arrastra o haz clic para subir imagen', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text('PNG, JPG hasta 5MB', style: TextStyle(color: Colors.white.withValues(alpha: 0.16), fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  Future<void> _createGymExercise() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es requerido'), backgroundColor: Colors.redAccent));
      return;
    }

    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;
    final userId = auth.profile?.uid;

    if (gymId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo resolver el gimnasio actual'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newExercise = Exercise.create(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? 'Sin descripción' : _descCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      movementPattern: _selectedPattern,
      exerciseType: _selectedType,
      difficulty: _selectedDifficulty,
      equipment: List.from(_selectedEquipment),
      heatmap: MuscleHeatmap({_selectedPrimaryMuscle.name: 0.9}),
      scope: ExerciseScope.gym,
      gymId: GymId(gymId),
      createdBy: UserId(userId),
    );

    try {
      final exerciseRepo = getIt<FirebaseExerciseRepository>();
      final createResult = await exerciseRepo.create(newExercise);
      createResult.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );

      if (!mounted) return;

      setState(() {
        _showCreateForm = false;
        _nameCtrl.clear();
        _descCtrl.clear();
        _instructionsCtrl.clear();
        _imageUrlCtrl.clear();
      });

      await _loadExercises();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ejercicio "${newExercise.name}" creado'), backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el ejercicio: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showExerciseDetail(Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(exercise.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Descripción', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 4),
            Text(exercise.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Músculo principal', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(exercise.primaryMuscle.displayName, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 12),
            const Text('Tipo', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(exercise.exerciseType.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 12),
            const Text('Dificultad', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text(exercise.difficulty.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar "${exercise.name}"?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'El ejercicio se marcará como inactivo.',
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
                final exerciseRepo = getIt<FirebaseExerciseRepository>();
                final deactivateResult = await exerciseRepo.deactivate(exercise.id);
                deactivateResult.fold(
                  (failure) => throw Exception(failure.message),
                  (_) => null,
                );
                if (mounted) {
                  _loadExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${exercise.name} eliminado'), backgroundColor: Colors.redAccent),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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

  void _showEditExerciseDialog(Exercise exercise) {
    final nameCtrl = TextEditingController(text: exercise.name);
    final descCtrl = TextEditingController(text: exercise.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar "${exercise.name}"', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción', labelStyle: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final exerciseRepo = getIt<FirebaseExerciseRepository>();
                final updated = Exercise.restore(
                  id: exercise.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  instructions: exercise.instructions,
                  imageUrl: exercise.imageUrl,
                  animationUrl: exercise.animationUrl,
                  videoUrl: exercise.videoUrl,
                  movementPattern: exercise.movementPattern,
                  exerciseType: exercise.exerciseType,
                  equipment: exercise.equipment,
                  difficulty: exercise.difficulty,
                  heatmap: exercise.heatmap,
                  recommendedRepRange: exercise.recommendedRepRange,
                  estimatedCalories: exercise.estimatedCalories,
                  scope: exercise.scope,
                  createdBy: exercise.createdBy,
                  gymId: exercise.gymId,
                  isActive: exercise.isActive,
                  createdAt: exercise.createdAt,
                  updatedAt: DateTime.now(),
                  sets: exercise.sets,
                  reps: exercise.reps,
                  restSeconds: exercise.restSeconds,
                  notes: exercise.notes,
                );
                final updateResult = await exerciseRepo.update(updated);
                updateResult.fold(
                  (failure) => throw Exception(failure.message),
                  (_) => null,
                );
                if (mounted) {
                  _loadExercises();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ejercicio actualizado'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.quantumBlue),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
