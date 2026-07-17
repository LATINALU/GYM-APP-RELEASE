import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';
import '../../theme/gym_widgets.dart';
import '../../widgets/share_routine_qr_dialog.dart';
import 'training_forge_store.dart';

class TrainingForgeScreen extends StatefulWidget {
  const TrainingForgeScreen({super.key});

  @override
  State<TrainingForgeScreen> createState() => _TrainingForgeScreenState();
}

class _TrainingForgeScreenState extends State<TrainingForgeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _store = TrainingForgeStore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _store.addListener(_onStoreChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onStoreChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.backgroundStart.withValues(alpha: 0.5),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildForgeHeader(),
            _buildTabNavigation(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExerciseForgeTab(),
                  _buildRoutineLabTab(),
                  _buildProgramStudioTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildForgeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: const BoxDecoration(
                        color: QuantumColors.quantumBlue,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: QuantumColors.quantumBlue, blurRadius: 10, spreadRadius: 2)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('THE FORGE', style: QuantumTypography.label.copyWith(color: QuantumColors.quantumBlue, letterSpacing: 4, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('LABORATORIO DE ENTRENAMIENTO', style: QuantumTypography.h1.copyWith(fontSize: 32, letterSpacing: -1, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Crea el ADN de tu gimnasio: ejercicios, secuencias y programas maestros.', style: QuantumTypography.caption.copyWith(color: Colors.white38)),
              ],
            ),
          ),
          Row(
            children: [
              _buildHeaderStat('${_store.exerciseCount} EJERCICIOS', Icons.fitness_center_rounded),
              const SizedBox(width: 16),
              _buildHeaderStat('${_store.routineCount} RUTINAS', Icons.architecture_rounded),
              const SizedBox(width: 16),
              _buildHeaderStat('${_store.programCount} PROGRAMAS', Icons.collections_bookmark_rounded),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildHeaderStat(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: QuantumColors.quantumBlue, size: 18),
          const SizedBox(width: 12),
          Text(label, style: QuantumTypography.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [QuantumColors.quantumBlue, QuantumColors.matrixCyan]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: QuantumColors.quantumBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'EJERCICIOS'),
          Tab(text: 'RUTINAS'),
          Tab(text: 'PROGRAMAS'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: EJERCICIOS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExerciseForgeTab() {
    final exercises = _store.exercises;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BIBLIOTECA DE EJERCICIOS', style: QuantumTypography.h3),
              GymButton(
                text: 'NUEVO EJERCICIO',
                icon: Icons.add_rounded,
                onPressed: () => _showExerciseCreator(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          exercises.isEmpty
              ? _buildEmptyState('No hay ejercicios', 'Crea tu primer ejercicio para empezar a construir rutinas.')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 0.85,
                  ),
                  itemCount: exercises.length,
                  itemBuilder: (context, i) {
                    final ex = exercises[i];
                    return _buildExerciseCard(ex);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ForgeExercise ex) {
    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview or icon header
          if (ex.hasImage)
            SizedBox(
              height: 80,
              width: double.infinity,
              child: Stack(children: [
                Positioned.fill(child: Image.memory(ex.imageBytes!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: QuantumColors.quantumBlue.withValues(alpha: 0.05),
                    child: const Center(child: Icon(Icons.fitness_center_rounded, color: QuantumColors.quantumBlue, size: 24))))),
                Positioned(top: 8, right: 8, child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 16)),
                  color: const Color(0xFF1A1A2E),
                  onSelected: (v) {
                    if (v == 'edit') _showExerciseCreator(context, existing: ex);
                    if (v == 'delete') _confirmDelete('ejercicio', ex.name, () => _store.deleteExercise(ex.id));
                    if (v == 'details') _showExerciseDetails(ex);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'details', child: Text('Ver Detalles', style: TextStyle(color: Colors.white70))),
                    const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white70))),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                  ],
                )),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: QuantumColors.quantumBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.fitness_center_rounded, color: QuantumColors.quantumBlue, size: 24),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                    color: const Color(0xFF1A1A2E),
                    onSelected: (v) {
                      if (v == 'edit') _showExerciseCreator(context, existing: ex);
                      if (v == 'delete') _confirmDelete('ejercicio', ex.name, () => _store.deleteExercise(ex.id));
                      if (v == 'details') _showExerciseDetails(ex);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'details', child: Text('Ver Detalles', style: TextStyle(color: Colors.white70))),
                      const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white70))),
                      const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!ex.hasImage) const Spacer(),
                Text(ex.name, style: QuantumTypography.h3.copyWith(fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(ex.subtitle, style: QuantumTypography.caption.copyWith(fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildGymCreatorBadge(ex.gymCreator),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: GymButton(text: 'EDITAR', size: GymButtonSize.small, style: GymButtonStyle.ghost, onPressed: () => _showExerciseCreator(context, existing: ex))),
                    const SizedBox(width: 8),
                    Expanded(child: GymButton(text: 'DETALLES', size: GymButtonSize.small, onPressed: () => _showExerciseDetails(ex))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: RUTINAS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRoutineLabTab() {
    final routines = _store.routines;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LABORATORIO DE RUTINAS', style: QuantumTypography.h3),
              GymButton(
                text: 'DISEÑAR RUTINA',
                icon: Icons.auto_awesome_mosaic_rounded,
                onPressed: () => _showRoutineCreator(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          routines.isEmpty
              ? _buildEmptyState('No hay rutinas', 'Diseña tu primera rutina combinando ejercicios.')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.2,
                  ),
                  itemCount: routines.length,
                  itemBuilder: (context, i) {
                    final rt = routines[i];
                    return _buildRoutineCard(rt);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(ForgeRoutine rt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuantumColors.matrixCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: QuantumColors.matrixCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.architecture_rounded, color: QuantumColors.matrixCyan, size: 24),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                color: const Color(0xFF1A1A2E),
                onSelected: (v) {
                  if (v == 'share_qr') _shareRoutineQr(rt);
                  if (v == 'edit') _showRoutineCreator(context, existing: rt);
                  if (v == 'delete') _confirmDelete('rutina', rt.name, () => _store.deleteRoutine(rt.id));
                  if (v == 'details') _showRoutineDetails(rt);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share_qr', child: Row(children: [Icon(Icons.qr_code_rounded, color: Colors.white70), SizedBox(width: 8), Text('Compartir QR', style: TextStyle(color: Colors.white))])),
                  const PopupMenuItem(value: 'details', child: Text('Ver Detalles', style: TextStyle(color: Colors.white70))),
                  const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white70))),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(rt.name, style: QuantumTypography.h3.copyWith(fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(rt.subtitle, style: QuantumTypography.caption.copyWith(fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildGymCreatorBadge(rt.gymCreator),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GymButton(text: 'EDITAR', size: GymButtonSize.small, style: GymButtonStyle.ghost, onPressed: () => _showRoutineCreator(context, existing: rt))),
              const SizedBox(width: 8),
              Expanded(child: GymButton(text: 'DETALLES', size: GymButtonSize.small, onPressed: () => _showRoutineDetails(rt))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: PROGRAMAS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProgramStudioTab() {
    final programs = _store.programs;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ESTUDIO DE PROGRAMAS', style: QuantumTypography.h3),
              GymButton(
                text: 'CREAR PLAN MAESTRO',
                icon: Icons.dashboard_customize_rounded,
                onPressed: () => _showProgramCreator(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          programs.isEmpty
              ? _buildEmptyState('No hay programas', 'Crea tu primer programa maestro agrupando rutinas.')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.8,
                  ),
                  itemCount: programs.length,
                  itemBuilder: (context, i) {
                    final pg = programs[i];
                    return _buildProgramCard(pg);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(ForgeProgram pg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.collections_bookmark_rounded, color: Colors.orangeAccent, size: 24),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white24),
                color: const Color(0xFF1A1A2E),
                onSelected: (v) {
                  if (v == 'edit') _showProgramCreator(context, existing: pg);
                  if (v == 'delete') _confirmDelete('programa', pg.name, () => _store.deleteProgram(pg.id));
                  if (v == 'details') _showProgramDetails(pg);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'details', child: Text('Ver Detalles', style: TextStyle(color: Colors.white70))),
                  const PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white70))),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(pg.name, style: QuantumTypography.h3.copyWith(fontSize: 18, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(pg.subtitle, style: QuantumTypography.caption.copyWith(fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('${pg.weeks} SEMANAS', style: QuantumTypography.caption.copyWith(fontSize: 10, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildGymCreatorBadge(pg.gymCreator),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GymButton(text: 'EDITAR', size: GymButtonSize.small, style: GymButtonStyle.ghost, onPressed: () => _showProgramCreator(context, existing: pg))),
              const SizedBox(width: 8),
              Expanded(child: GymButton(text: 'DETALLES', size: GymButtonSize.small, onPressed: () => _showProgramDetails(pg))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGymCreatorBadge(String gymName) {
    return Row(
      children: [
        const Icon(Icons.storefront_rounded, color: Colors.white24, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(gymName, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: Colors.white.withValues(alpha: 0.08), size: 80),
            const SizedBox(height: 24),
            Text(title, style: QuantumTypography.h3.copyWith(color: Colors.white24)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white12, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════
  void _showExerciseCreator(BuildContext context, {ForgeExercise? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ExerciseCreatorDialog(existing: existing, onSave: (ex) {
        if (existing != null) { _store.updateExercise(ex); } else { _store.addExercise(ex); }
      }),
    );
  }

  void _showRoutineCreator(BuildContext context, {ForgeRoutine? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RoutineCreatorDialog(existing: existing, exercises: _store.exercises, onSave: (rt) {
        if (existing != null) { _store.updateRoutine(rt); } else { _store.addRoutine(rt); }
      }),
    );
  }

  void _showProgramCreator(BuildContext context, {ForgeProgram? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProgramCreatorDialog(existing: existing, routines: _store.routines, onSave: (pg) {
        if (existing != null) { _store.updateProgram(pg); } else { _store.addProgram(pg); }
      }),
    );
  }

  void _showExerciseDetails(ForgeExercise ex) {
    showDialog(context: context, builder: (ctx) => _ExerciseDetailDialog(exercise: ex));
  }

  void _showRoutineDetails(ForgeRoutine rt) {
    showDialog(context: context, builder: (ctx) => _RoutineDetailDialog(routine: rt, exercises: _store.exercises));
  }

  void _shareRoutineQr(ForgeRoutine rt) {
    final exercises = _store.exercises
        .where((e) => rt.exerciseIds.contains(e.id))
        .map((e) => {
              'exerciseId': e.id,
              'exerciseName': e.name,
              'muscleGroup': e.primaryMuscle,
              'sets': 3,
              'reps': '10-12',
              'restSeconds': 90,
            })
        .toList();
    ShareRoutineQrDialog.show(
      context,
      routineId: rt.id,
      routineName: rt.name,
      description: rt.description,
      difficulty: rt.difficulty,
      estimatedDuration: rt.estimatedMinutes,
      exercises: exercises,
      gymId: AuthStateNotifier.instance.profile?.gymId?.value,
      createdBy: rt.gymCreator,
    );
  }

  void _showProgramDetails(ForgeProgram pg) {
    showDialog(context: context, builder: (ctx) => _ProgramDetailDialog(program: pg, routines: _store.routines));
  }

  void _confirmDelete(String type, String name, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar $type', style: const TextStyle(color: Colors.white)),
        content: Text('¿Seguro que quieres eliminar "$name"?', style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () { onConfirm(); Navigator.pop(ctx); }, child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXERCISE CREATOR DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _ExerciseCreatorDialog extends StatefulWidget {
  final ForgeExercise? existing;
  final void Function(ForgeExercise) onSave;
  const _ExerciseCreatorDialog({this.existing, required this.onSave});

  @override
  State<_ExerciseCreatorDialog> createState() => _ExerciseCreatorDialogState();
}

class _ExerciseCreatorDialogState extends State<_ExerciseCreatorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _muscle;
  late String _difficulty;
  late String _type;
  late String _pattern;
  late List<String> _equipment;
  late String _gymCreator;

  static const _muscles = ['Pecho', 'Espalda', 'Cuádriceps', 'Isquiotibiales', 'Glúteos', 'Hombros', 'Bíceps', 'Tríceps', 'Core', 'Antebrazo', 'Trapecio', 'Pantorrillas'];
  static const _difficulties = ['Principiante', 'Intermedio', 'Avanzado'];
  static const _types = ['Compuesto', 'Aislamiento'];
  static const _patterns = ['Empuje Horizontal', 'Empuje Vertical', 'Tracción Horizontal', 'Tracción Vertical', 'Sentadilla', 'Bisagra de Cadera', 'Aislamiento', 'Cargada'];
  static const _equipmentOptions = ['Barra', 'Mancuernas', 'Cable', 'Máquina', 'Kettlebell', 'Banco', 'Rack', 'Barra de Dominadas', 'Paralelas', 'Bandas', 'Corporal'];
  static const _gyms = ['Iron Temple Gym', 'PowerHouse Fitness', 'FitZone Studio', 'CrossFit Arena', 'Elite Performance'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _muscle = e?.primaryMuscle ?? _muscles.first;
    _difficulty = e?.difficulty ?? _difficulties[1];
    _type = e?.exerciseType ?? _types.first;
    _pattern = e?.movementPattern ?? _patterns.first;
    _equipment = List.from(e?.equipment ?? []);
    _gymCreator = e?.gymCreator ?? _gyms.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40)],
        ),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEdit ? 'EDITAR EJERCICIO' : 'FORJAR EJERCICIO', style: QuantumTypography.h2),
                  Text(isEdit ? 'Modifica el patrón de movimiento.' : 'Define un nuevo patrón de movimiento maestro.', style: const TextStyle(color: Colors.white24, fontSize: 13)),
                ]),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 28),
            Flexible(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Column(children: [
                      _forgeField('NOMBRE', _nameCtrl, 'Ej: Sentadilla Búlgara'),
                      const SizedBox(height: 20),
                      _forgeField('DESCRIPCIÓN TÉCNICA', _descCtrl, 'Describe la ejecución...', maxLines: 3),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: _forgeDropdown('MÚSCULO PRIMARIO', _muscle, _muscles, (v) => setState(() => _muscle = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _forgeDropdown('DIFICULTAD', _difficulty, _difficulties, (v) => setState(() => _difficulty = v!))),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: _forgeDropdown('TIPO', _type, _types, (v) => setState(() => _type = v!))),
                        const SizedBox(width: 16),
                        Expanded(child: _forgeDropdown('PATRÓN', _pattern, _patterns, (v) => setState(() => _pattern = v!))),
                      ]),
                    ])),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: Column(children: [
                      _forgeDropdown('GYM CREADOR', _gymCreator, _gyms, (v) => setState(() => _gymCreator = v!)),
                      const SizedBox(height: 20),
                      _forgeLabel('EQUIPAMIENTO'),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: _equipmentOptions.map((eq) {
                        final sel = _equipment.contains(eq);
                        return GestureDetector(
                          onTap: () => setState(() { sel ? _equipment.remove(eq) : _equipment.add(eq); }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? QuantumColors.quantumBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? QuantumColors.quantumBlue.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Text(eq, style: TextStyle(color: sel ? QuantumColors.quantumBlue : Colors.white38, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                          ),
                        );
                      }).toList()),
                    ])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
              const SizedBox(width: 24),
              GymButton(text: isEdit ? 'GUARDAR CAMBIOS' : 'FORJAR EJERCICIO', onPressed: _save),
            ]),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final ex = ForgeExercise(
      id: widget.existing?.id ?? 'ex_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      primaryMuscle: _muscle,
      movementPattern: _pattern,
      exerciseType: _type,
      difficulty: _difficulty,
      equipment: List.from(_equipment),
      gymCreator: _gymCreator,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(ex);
    Navigator.pop(context);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ROUTINE CREATOR DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _RoutineCreatorDialog extends StatefulWidget {
  final ForgeRoutine? existing;
  final List<ForgeExercise> exercises;
  final void Function(ForgeRoutine) onSave;
  const _RoutineCreatorDialog({this.existing, required this.exercises, required this.onSave});

  @override
  State<_RoutineCreatorDialog> createState() => _RoutineCreatorDialogState();
}

class _RoutineCreatorDialogState extends State<_RoutineCreatorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minutesCtrl;
  late String _focus;
  late String _difficulty;
  late String _gymCreator;
  late List<String> _selectedExerciseIds;

  static const _focuses = ['Hipertrofia', 'Fuerza', 'Resistencia', 'Potencia', 'Definición', 'Funcional'];
  static const _difficulties = ['Principiante', 'Intermedio', 'Avanzado'];
  static const _gyms = ['Iron Temple Gym', 'PowerHouse Fitness', 'FitZone Studio', 'CrossFit Arena', 'Elite Performance'];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _minutesCtrl = TextEditingController(text: (r?.estimatedMinutes ?? 45).toString());
    _focus = r?.focus ?? _focuses.first;
    _difficulty = r?.difficulty ?? _difficulties[1];
    _gymCreator = r?.gymCreator ?? _gyms.first;
    _selectedExerciseIds = List.from(r?.exerciseIds ?? []);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _minutesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40)],
        ),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'EDITAR RUTINA' : 'DISEÑAR RUTINA', style: QuantumTypography.h2),
                Text(isEdit ? 'Modifica la secuencia de ejercicios.' : 'Combina ejercicios en una secuencia de entrenamiento.', style: const TextStyle(color: Colors.white24, fontSize: 13)),
              ]),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
            ]),
            const SizedBox(height: 24),
            Flexible(child: SingleChildScrollView(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: Column(children: [
                _forgeField('NOMBRE DE LA RUTINA', _nameCtrl, 'Ej: Push Day A'),
                const SizedBox(height: 20),
                _forgeField('DESCRIPCIÓN', _descCtrl, 'Objetivo y enfoque...', maxLines: 2),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _forgeDropdown('ENFOQUE', _focus, _focuses, (v) => setState(() => _focus = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _forgeDropdown('DIFICULTAD', _difficulty, _difficulties, (v) => setState(() => _difficulty = v!))),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _forgeField('DURACIÓN (MIN)', _minutesCtrl, '45')),
                  const SizedBox(width: 16),
                  Expanded(child: _forgeDropdown('GYM CREADOR', _gymCreator, _gyms, (v) => setState(() => _gymCreator = v!))),
                ]),
              ])),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _forgeLabel('EJERCICIOS (${_selectedExerciseIds.length} seleccionados)'),
                const SizedBox(height: 12),
                Container(
                  height: 340,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.exercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = widget.exercises[i];
                      final sel = _selectedExerciseIds.contains(ex.id);
                      return ListTile(
                        dense: true,
                        leading: Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, color: sel ? QuantumColors.matrixCyan : Colors.white24, size: 20),
                        title: Text(ex.name, style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 13)),
                        subtitle: Text(ex.primaryMuscle, style: TextStyle(color: sel ? QuantumColors.matrixCyan.withValues(alpha: 0.6) : Colors.white24, fontSize: 10)),
                        onTap: () => setState(() { sel ? _selectedExerciseIds.remove(ex.id) : _selectedExerciseIds.add(ex.id); }),
                      );
                    },
                  ),
                ),
              ])),
            ]))),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
              const SizedBox(width: 24),
              GymButton(text: isEdit ? 'GUARDAR CAMBIOS' : 'CREAR RUTINA', onPressed: _save),
            ]),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final rt = ForgeRoutine(
      id: widget.existing?.id ?? 'rt_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      exerciseIds: List.from(_selectedExerciseIds),
      focus: _focus,
      difficulty: _difficulty,
      estimatedMinutes: int.tryParse(_minutesCtrl.text) ?? 45,
      gymCreator: _gymCreator,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(rt);
    Navigator.pop(context);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRAM CREATOR DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _ProgramCreatorDialog extends StatefulWidget {
  final ForgeProgram? existing;
  final List<ForgeRoutine> routines;
  final void Function(ForgeProgram) onSave;
  const _ProgramCreatorDialog({this.existing, required this.routines, required this.onSave});

  @override
  State<_ProgramCreatorDialog> createState() => _ProgramCreatorDialogState();
}

class _ProgramCreatorDialogState extends State<_ProgramCreatorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _weeksCtrl;
  late String _focus;
  late String _difficulty;
  late String _gymCreator;
  late List<String> _selectedRoutineIds;

  static const _focuses = ['Fuerza', 'Hipertrofia', 'Definición', 'Resistencia', 'Potencia', 'Funcional'];
  static const _difficulties = ['Principiante', 'Intermedio', 'Avanzado'];
  static const _gyms = ['Iron Temple Gym', 'PowerHouse Fitness', 'FitZone Studio', 'CrossFit Arena', 'Elite Performance'];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _weeksCtrl = TextEditingController(text: (p?.weeks ?? 8).toString());
    _focus = p?.focus ?? _focuses.first;
    _difficulty = p?.difficulty ?? _difficulties[1];
    _gymCreator = p?.gymCreator ?? _gyms.first;
    _selectedRoutineIds = List.from(p?.routineIds ?? []);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _weeksCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40)],
        ),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'EDITAR PROGRAMA' : 'CREAR PLAN MAESTRO', style: QuantumTypography.h2),
                Text(isEdit ? 'Modifica el plan de entrenamiento.' : 'Agrupa rutinas en un plan periodizado.', style: const TextStyle(color: Colors.white24, fontSize: 13)),
              ]),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
            ]),
            const SizedBox(height: 24),
            Flexible(child: SingleChildScrollView(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: Column(children: [
                _forgeField('NOMBRE DEL PROGRAMA', _nameCtrl, 'Ej: PPL 12 Semanas Pro'),
                const SizedBox(height: 20),
                _forgeField('DESCRIPCIÓN', _descCtrl, 'Objetivo del programa...', maxLines: 2),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _forgeDropdown('ENFOQUE', _focus, _focuses, (v) => setState(() => _focus = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _forgeDropdown('DIFICULTAD', _difficulty, _difficulties, (v) => setState(() => _difficulty = v!))),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _forgeField('SEMANAS', _weeksCtrl, '8')),
                  const SizedBox(width: 16),
                  Expanded(child: _forgeDropdown('GYM CREADOR', _gymCreator, _gyms, (v) => setState(() => _gymCreator = v!))),
                ]),
              ])),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _forgeLabel('RUTINAS (${_selectedRoutineIds.length} seleccionadas)'),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: widget.routines.isEmpty
                      ? const Center(child: Text('Crea rutinas primero', style: TextStyle(color: Colors.white24, fontSize: 12)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.routines.length,
                          itemBuilder: (ctx, i) {
                            final rt = widget.routines[i];
                            final sel = _selectedRoutineIds.contains(rt.id);
                            return ListTile(
                              dense: true,
                              leading: Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, color: sel ? Colors.orangeAccent : Colors.white24, size: 20),
                              title: Text(rt.name, style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 13)),
                              subtitle: Text('${rt.exerciseIds.length} ejercicios • ${rt.focus}', style: TextStyle(color: sel ? Colors.orangeAccent.withValues(alpha: 0.6) : Colors.white24, fontSize: 10)),
                              onTap: () => setState(() { sel ? _selectedRoutineIds.remove(rt.id) : _selectedRoutineIds.add(rt.id); }),
                            );
                          },
                        ),
                ),
              ])),
            ]))),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
              const SizedBox(width: 24),
              GymButton(text: isEdit ? 'GUARDAR CAMBIOS' : 'CREAR PROGRAMA', onPressed: _save),
            ]),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final pg = ForgeProgram(
      id: widget.existing?.id ?? 'pg_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      routineIds: List.from(_selectedRoutineIds),
      weeks: int.tryParse(_weeksCtrl.text) ?? 8,
      focus: _focus,
      difficulty: _difficulty,
      gymCreator: _gymCreator,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(pg);
    Navigator.pop(context);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DETAIL DIALOGS
// ═════════════════════════════════════════════════════════════════════════════
class _ExerciseDetailDialog extends StatelessWidget {
  final ForgeExercise exercise;
  const _ExerciseDetailDialog({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return _DetailShell(
      title: exercise.name,
      color: QuantumColors.quantumBlue,
      icon: Icons.fitness_center_rounded,
      children: [
        _detailRow('Músculo Primario', exercise.primaryMuscle),
        if (exercise.secondaryMuscles.isNotEmpty) _detailRow('Músculos Secundarios', exercise.secondaryMuscles.join(', ')),
        _detailRow('Tipo', exercise.exerciseType),
        _detailRow('Patrón de Movimiento', exercise.movementPattern),
        _detailRow('Dificultad', exercise.difficulty),
        _detailRow('Equipamiento', exercise.equipment.isNotEmpty ? exercise.equipment.join(', ') : 'Corporal'),
        _detailRow('Gym Creador', exercise.gymCreator),
        const SizedBox(height: 16),
        if (exercise.description.isNotEmpty) ...[
          const Text('DESCRIPCIÓN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(exercise.description, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
        ],
      ],
    );
  }
}

class _RoutineDetailDialog extends StatelessWidget {
  final ForgeRoutine routine;
  final List<ForgeExercise> exercises;
  const _RoutineDetailDialog({required this.routine, required this.exercises});

  @override
  Widget build(BuildContext context) {
    final routineExercises = routine.exerciseIds
        .map((id) => exercises.where((e) => e.id == id).firstOrNull)
        .where((e) => e != null)
        .toList();
    return _DetailShell(
      title: routine.name,
      color: QuantumColors.matrixCyan,
      icon: Icons.architecture_rounded,
      children: [
        _detailRow('Enfoque', routine.focus),
        _detailRow('Dificultad', routine.difficulty),
        _detailRow('Duración', '${routine.estimatedMinutes} minutos'),
        _detailRow('Ejercicios', '${routine.exerciseIds.length}'),
        _detailRow('Gym Creador', routine.gymCreator),
        if (routine.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(routine.description, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 20),
        const Text('EJERCICIOS EN LA RUTINA', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...routineExercises.map((ex) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.fitness_center_rounded, color: QuantumColors.matrixCyan, size: 16),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex!.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(ex.primaryMuscle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
        )),
      ],
    );
  }
}

class _ProgramDetailDialog extends StatelessWidget {
  final ForgeProgram program;
  final List<ForgeRoutine> routines;
  const _ProgramDetailDialog({required this.program, required this.routines});

  @override
  Widget build(BuildContext context) {
    final programRoutines = program.routineIds
        .map((id) => routines.where((r) => r.id == id).firstOrNull)
        .where((r) => r != null)
        .toList();
    return _DetailShell(
      title: program.name,
      color: Colors.orangeAccent,
      icon: Icons.collections_bookmark_rounded,
      children: [
        _detailRow('Enfoque', program.focus),
        _detailRow('Dificultad', program.difficulty),
        _detailRow('Semanas', '${program.weeks}'),
        _detailRow('Rutinas', '${program.routineIds.length}'),
        _detailRow('Gym Creador', program.gymCreator),
        if (program.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(program.description, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 20),
        const Text('RUTINAS DEL PROGRAMA', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...programRoutines.map((rt) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.architecture_rounded, color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rt!.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${rt.exerciseIds.length} ejercicios • ${rt.estimatedMinutes} min', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
        )),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED FORM & DETAIL HELPERS
// ═════════════════════════════════════════════════════════════════════════════
Widget _forgeField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _forgeLabel(label),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.02),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
}

Widget _forgeDropdown(String label, String value, List<String> options, void Function(String?) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _forgeLabel(label),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white24),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

Widget _forgeLabel(String label) {
  return Text(label, style: QuantumTypography.label.copyWith(fontSize: 10, color: QuantumColors.quantumBlue));
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    ),
  );
}

class _DetailShell extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Widget> children;
  const _DetailShell({required this.title, required this.color, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: const Color(0xFF101018),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40)],
        ),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: QuantumTypography.h2.copyWith(fontSize: 22), maxLines: 2, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
            ]),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
