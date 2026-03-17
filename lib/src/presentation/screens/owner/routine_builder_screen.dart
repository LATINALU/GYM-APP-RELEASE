import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/routine_planning.dart';
import '../../../infrastructure/adapters/firebase/firebase_exercise_repository.dart';
import '../../../application/services/routine_service.dart';
import '../../../../core/auth/auth_state_notifier.dart';

// ─── QUANTUM FIT DESIGN TOKENS ───────────────────────────────────────────────
const _kBg       = Color(0xFF0D0D1A);
const _kSurface  = Color(0xFF16162A);
const _kCard     = Color(0xFF1F1F3D);
const _kInput    = Color(0xFF0D0D1A);
const _kPrimary  = Color(0xFF6366F1);
const _kCyan     = Color(0xFF00E0FF);
const _kGreen    = Color(0xFF43A047);
const _kRed      = Color(0xFFE53935);
const _kTextSec  = Color(0xFF94A3B8);

// ─── HELPER MODEL: Un item del board que vincula datos con UI ────────────────
class _BoardExercise {
  final String exerciseId;
  final String name;
  final String muscleLabel;
  final String? imageUrl;
  int sets;
  String reps;
  String? rpe;
  String? weight;
  bool isConfigured;

  _BoardExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleLabel,
    this.imageUrl,
    this.sets = 3,
    this.reps = '10',
    this.isConfigured = false,
  });

  /// Convertir a RoutineStep del Dominio (para guardar en Firebase)
  RoutineStep toRoutineStep() => RoutineStep(
    exerciseId: exerciseId,
    exerciseName: name,
    imageUrl: imageUrl,
    sets: sets,
    reps: reps,
    rpe: rpe,
  );
}

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────
class RoutineBuilderScreen extends StatefulWidget {
  final String? memberId;
  const RoutineBuilderScreen({super.key, this.memberId});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final _routineService = RoutineService();
  FirebaseExerciseRepository? _exerciseRepo;

  // Columnas del Board: [0] = Biblioteca, [1..n] = Días de entrenamiento
  late List<_BoardColumn> _columns;
  bool _isLoading = true;
  bool _isSaving = false;
  late String? _selectedMemberId;

  // Datos de la biblioteca para poder re-clonar items al arrastrar
  List<_BoardExercise> _librarySource = [];

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
    try { _exerciseRepo = GetIt.I<FirebaseExerciseRepository>(); } catch (_) {}
    _initBoard();
  }

  Future<void> _initBoard() async {
    // 1. Cargar ejercicios de Firebase (o usar mocks si no hay repo)
    List<_BoardExercise> libraryItems = [];

    if (_exerciseRepo != null) {
      final result = await _exerciseRepo!.getAll();
      result.fold(
        (_) => null,
        (exercises) {
          libraryItems = exercises.map((ex) => _BoardExercise(
            exerciseId: ex.id.value,
            name: ex.name,
            muscleLabel: ex.primaryMuscle.displayName,
            imageUrl: ex.imageUrl,
          )).toList();
        },
      );
    }

    _librarySource = libraryItems;

    // 2. Construir las columnas del Kanban
    _columns = [
      _BoardColumn(title: '📚 BIBLIOTECA', subtitle: 'Arrastrar hacia los días', items: List.from(libraryItems), isLibrary: true),
      _BoardColumn(title: 'LUNES', subtitle: 'Día A', items: []),
      _BoardColumn(title: 'MARTES', subtitle: 'Día B', items: []),
      _BoardColumn(title: 'MIÉRCOLES', subtitle: 'Día C', items: []),
      _BoardColumn(title: 'JUEVES', subtitle: 'Descanso Activo', items: []),
      _BoardColumn(title: 'VIERNES', subtitle: 'Full Body', items: []),
      _BoardColumn(title: 'SÁBADO', subtitle: 'Opcional', items: []),
    ];

    setState(() => _isLoading = false);
  }

  // ─── CALCULAR VOLUMEN TOTAL PROYECTADO ───────────────────────────────────
  double _calculateTotalVolume() {
    double total = 0;
    for (final col in _columns) {
      if (col.isLibrary) continue;
      for (final item in col.items) {
        if (item.isConfigured) {
          total += _routineService.calculateVolume(item.sets, item.reps, double.tryParse(item.weight ?? '50') ?? 50);
        }
      }
    }
    return total;
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: DragAndDropLists(
              children: _buildDndLists(),
              onItemReorder: _onItemReorder,
              onListReorder: _onListReorder,

              // Tablero horizontal estilo Trello
              axis: Axis.horizontal,
              listWidth: 340,
              listDraggingWidth: 340,
              listPadding: const EdgeInsets.all(16),
              itemDragOnLongPress: false,
              listDragOnLongPress: true,

              // Decoración de cada columna
              listDecoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),

              // Indicador visual al arrastrar sobre un target
              listDragHandle: const DragHandle(child: SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final totalVolume = _calculateTotalVolume();
    final configuredCount = _columns.where((c) => !c.isLibrary).fold<int>(0, (sum, c) => sum + c.items.where((i) => i.isConfigured).length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          // Título
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Diseñador de Rutinas Pro',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildMetricChip(Icons.analytics_outlined, '${totalVolume.toStringAsFixed(0)} kg', 'Vol. Semanal'),
                  const SizedBox(width: 16),
                  _buildMetricChip(Icons.fitness_center, '$configuredCount', 'Ejercicios'),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Acciones
          _buildGhostButton('Cargar Plantilla', Icons.copy_all_rounded, () {}),
          const SizedBox(width: 12),
          _buildPrimaryButton(
            _isSaving ? 'Guardando...' : 'Guardar Rutina',
            Icons.cloud_upload_outlined,
            _isSaving ? null : _saveRoutine,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kPrimary, size: 14),
          const SizedBox(width: 8),
          Text('$value  ', style: GoogleFonts.inter(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.inter(color: _kPrimary.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGhostButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white54,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      icon: Icon(icon, size: 18),
      label: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      onPressed: onPressed,
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 4,
        shadowColor: _kPrimary.withValues(alpha: 0.4),
      ),
      icon: _isSaving
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(icon, size: 18),
      label: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
      onPressed: onPressed,
    );
  }

  // ─── BUILD DRAG AND DROP LISTS ───────────────────────────────────────────
  List<DragAndDropList> _buildDndLists() {
    return _columns.asMap().entries.map((entry) {
      final colIndex = entry.key;
      final col = entry.value;
      final dayVolume = col.isLibrary ? 0.0 : col.items.fold<double>(0, (sum, item) {
        if (!item.isConfigured) return sum;
        return sum + _routineService.calculateVolume(item.sets, item.reps, double.tryParse(item.weight ?? '50') ?? 50);
      });

      return DragAndDropList(
        // ─ Header de cada columna ─
        header: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(col.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: col.isLibrary ? _kCyan : Colors.white,
                    )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${col.items.length}',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!col.isLibrary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dayVolume > 0 ? _kGreen.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayVolume > 0 ? 'CARGA: ${dayVolume.toStringAsFixed(0)} KG' : col.subtitle,
                    style: GoogleFonts.inter(
                      color: dayVolume > 0 ? _kGreen : _kTextSec, 
                      fontSize: 10, 
                      fontWeight: dayVolume > 0 ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                )
              else
                Text(col.subtitle, style: GoogleFonts.inter(color: _kCyan.withValues(alpha: 0.5), fontSize: 11)),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.04)),
            ],
          ),
        ),

        // ─ Items (tarjetas de ejercicio) ─
        children: col.items.map((item) => DragAndDropItem(
          child: _ExerciseTile(
            item: item,
            isLibrary: col.isLibrary,
            onTap: col.isLibrary ? null : () => _showConfigDialog(colIndex, col.items.indexOf(item)),
            onDelete: col.isLibrary ? null : () {
              setState(() => col.items.remove(item));
            },
          ),
        )).toList(),

        // ─ Footer: placeholder cuando está vacío ─
        contentsWhenEmpty: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: Colors.white.withValues(alpha: 0.06), size: 40),
                const SizedBox(height: 8),
                Text(
                  col.isLibrary ? 'No hay ejercicios disponibles' : 'Soltar ejercicios aquí',
                  style: GoogleFonts.inter(color: Colors.white10, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─── DRAG & DROP LOGIC ───────────────────────────────────────────────────
  Future<void> _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    final sourceCol = _columns[oldListIndex];
    final targetCol = _columns[newListIndex];

    setState(() {
      final movedItem = sourceCol.items.removeAt(oldItemIndex);
      targetCol.items.insert(newItemIndex, movedItem);
    });

    // Si venía de la Biblioteca, re-clonar el item para que la biblioteca no se vacíe
    if (sourceCol.isLibrary) {
      final originalData = _librarySource.firstWhere(
        (s) => s.exerciseId == targetCol.items[newItemIndex].exerciseId,
        orElse: () => targetCol.items[newItemIndex],
      );
      // Restaurar clone en biblioteca
      setState(() {
        sourceCol.items.insert(oldItemIndex, _BoardExercise(
          exerciseId: originalData.exerciseId,
          name: originalData.name,
          muscleLabel: originalData.muscleLabel,
          imageUrl: originalData.imageUrl,
        ));
      });
    }

    // Auto-config modal si se movió a un día de entrenamiento (no biblioteca)
    if (!targetCol.isLibrary) {
      final configData = await _showAutoConfigDialog(
        targetCol.items[newItemIndex].name,
      );

      if (configData != null && mounted) {
        setState(() {
          final item = targetCol.items[newItemIndex];
          item.sets = int.tryParse(configData['sets'] ?? '3') ?? 3;
          item.reps = configData['reps'] ?? '12';
          item.rpe = configData['rpe'];
          item.weight = configData['weight'];
          item.isConfigured = true;
        });
      }
    }
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      final movedList = _columns.removeAt(oldListIndex);
      _columns.insert(newListIndex, movedList);
    });
  }

  // ─── AUTO-CONFIG MODAL (Futurista) ───────────────────────────────────────
  Future<Map<String, String>?> _showAutoConfigDialog(String exerciseName) async {
    final setsCtrl = TextEditingController(text: '4');
    final repsCtrl = TextEditingController(text: '12');
    final rpeCtrl = TextEditingController(text: '8');
    final weightCtrl = TextEditingController(text: '0');

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _kPrimary, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        contentPadding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
        actionsPadding: const EdgeInsets.all(24),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configurar Ejercicio',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: _kCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(exerciseName, style: GoogleFonts.inter(color: _kCyan, fontSize: 13, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _NeonInput(label: 'SERIES', controller: setsCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _NeonInput(label: 'REPS', controller: repsCtrl)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _NeonInput(label: 'RPE (1-10)', controller: rpeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _NeonInput(label: 'PESO (kg)', controller: weightCtrl)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Omitir', style: GoogleFonts.inter(color: Colors.white24)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: () => Navigator.pop(ctx, {
              'sets': setsCtrl.text,
              'reps': repsCtrl.text,
              'rpe': rpeCtrl.text,
              'weight': weightCtrl.text,
            }),
            child: Text('CONFIRMAR', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ─── RE-CONFIG EXISTING ITEM ─────────────────────────────────────────────
  Future<void> _showConfigDialog(int colIndex, int itemIndex) async {
    final item = _columns[colIndex].items[itemIndex];
    final result = await _showAutoConfigDialog(item.name);
    if (result != null && mounted) {
      setState(() {
        item.sets = int.tryParse(result['sets'] ?? '3') ?? 3;
        item.reps = result['reps'] ?? '12';
        item.rpe = result['rpe'];
        item.weight = result['weight'];
        item.isConfigured = true;
      });
    }
  }

  // ─── SAVE ROUTINE TO FIRESTORE ───────────────────────────────────────────
  Future<void> _saveRoutine() async {
    final auth = AuthStateNotifier.instance;
    if (auth.profile == null) return;

    // Map _columns to WeekDay => List<RoutineStep>
    final Map<WeekDay, List<RoutineStep>> weekPlan = {};
    final dayMapping = [
      null, // index 0 = Biblioteca (skip)
      WeekDay.monday,
      WeekDay.tuesday,
      WeekDay.wednesday,
      WeekDay.thursday,
      WeekDay.friday,
      WeekDay.saturday,
    ];

    for (int i = 1; i < _columns.length && i < dayMapping.length; i++) {
      final day = dayMapping[i]!;
      weekPlan[day] = _columns[i].items.map((item) => item.toRoutineStep()).toList();
    }

    setState(() => _isSaving = true);
    try {
      await _routineService.saveRoutine(
        memberId: _selectedMemberId!,
        staffId: auth.profile!.uid,
        weekPlan: weekPlan,
      );

      // Audit Log Inmutable
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'who': auth.profile?.displayName ?? 'Staff',
        'action': 'CREATE_ROUTINE',
        'details': 'Rutina creada para $_selectedMemberId desde Kanban Builder',
        'timestamp': FieldValue.serverTimestamp(),
        'module': 'RUTINAS',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('💾 Rutina sincronizada con la Nube correctamente',
            style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _kRed, content: Text('Error: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ─── DATA MODEL: Columna del Board ───────────────────────────────────────────
class _BoardColumn {
  final String title;
  final String subtitle;
  final List<_BoardExercise> items;
  final bool isLibrary;

  _BoardColumn({
    required this.title,
    required this.subtitle,
    required this.items,
    this.isLibrary = false,
  });
}

// ─── WIDGET: Tarjeta de Ejercicio ────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final _BoardExercise item;
  final bool isLibrary;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ExerciseTile({
    required this.item,
    required this.isLibrary,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: item.isConfigured
              ? Border.all(color: _kCyan.withValues(alpha: 0.4), width: 1.5)
              : Border.all(color: Colors.white.withValues(alpha: 0.03)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Row
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: _buildLeading(),
              title: Text(item.name,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: Text(item.muscleLabel,
                style: GoogleFonts.inter(color: _kTextSec, fontSize: 11)),
              trailing: isLibrary
                  ? Icon(Icons.drag_handle_rounded, color: Colors.white.withValues(alpha: 0.15), size: 18)
                  : (onDelete != null
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: _kRed, size: 16),
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                        )
                      : null),
            ),

            // Badges de configuración (solo si ya se configuró)
            if (item.isConfigured)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge('${item.sets} Sets', _kPrimary),
                    _Badge('${item.reps} Reps', _kPrimary),
                    if (item.rpe != null && item.rpe!.isNotEmpty)
                      _Badge('RPE ${item.rpe}', Colors.orangeAccent),
                    if (item.weight != null && item.weight!.isNotEmpty && item.weight != '0')
                      _Badge('${item.weight} kg', _kCyan),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (item.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(imageUrl: item.imageUrl!, width: 40, height: 40, fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 40, height: 40, color: Colors.white10),
          errorWidget: (_, __, ___) => _iconFallback(),
        ),
      );
    }
    return _iconFallback();
  }

  Widget _iconFallback() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: (item.isConfigured ? _kCyan : _kPrimary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        item.isConfigured ? Icons.check_circle_rounded : Icons.fitness_center_rounded,
        color: item.isConfigured ? _kCyan : _kPrimary,
        size: 18,
      ),
    );
  }
}

// ─── WIDGET: Badge ───────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

// ─── WIDGET: Input Neón ──────────────────────────────────────────────────────
class _NeonInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NeonInput({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: _kTextSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: _kInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kCyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
