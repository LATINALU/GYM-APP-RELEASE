import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';
import '../../theme/gym_widgets.dart';
import 'training_forge_store.dart';

class ExerciseAtlasScreen extends StatefulWidget {
  const ExerciseAtlasScreen({super.key});

  @override
  State<ExerciseAtlasScreen> createState() => _ExerciseAtlasScreenState();
}

class _ExerciseAtlasScreenState extends State<ExerciseAtlasScreen> {
  final _store = TrainingForgeStore.instance;
  String _filterMuscle = 'Todos';
  String _filterImage = 'Todos';
  ForgeExercise? _selected;
  bool _isDragHovering = false;

  static const _muscleFilters = ['Todos', 'Pecho', 'Espalda', 'Cuádriceps', 'Isquiotibiales', 'Glúteos', 'Hombros', 'Bíceps', 'Tríceps', 'Core'];

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (_selected != null) {
      _selected = _store.findExercise(_selected!.id);
    }
    setState(() {});
  }

  List<ForgeExercise> get _filteredExercises {
    var list = _store.exercises;
    if (_filterMuscle != 'Todos') {
      list = list.where((e) => e.primaryMuscle == _filterMuscle).toList();
    }
    if (_filterImage == 'Con Imagen') {
      list = list.where((e) => e.hasImage).toList();
    } else if (_filterImage == 'Sin Imagen') {
      list = list.where((e) => !e.hasImage).toList();
    }
    return list;
  }

  int get _totalWithImage => _store.exercises.where((e) => e.hasImage).length;
  int get _totalWithoutImage => _store.exercises.where((e) => !e.hasImage).length;

  Future<void> _pickAndUploadImage(String exerciseId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        _store.setExerciseImage(exerciseId, file.bytes!, file.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _filteredExercises;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: Row(
        children: [
          // ══════════════ PANEL IZQUIERDO: GALERÍA ══════════════
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAtlasHeader(exercises.length),
                _buildFilters(),
                const SizedBox(height: 8),
                Expanded(
                  child: exercises.isEmpty
                      ? _buildEmptyGallery()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: exercises.length,
                          itemBuilder: (ctx, i) => _buildAtlasCard(exercises[i]),
                        ),
                ),
              ],
            ),
          ),
          VerticalDivider(color: Colors.white.withValues(alpha: 0.05), width: 1),
          // ══════════════ PANEL DERECHO: DETALLE + UPLOAD ══════════════
          Expanded(
            flex: 2,
            child: _selected == null ? _buildEmptySelection() : _buildDetailPanel(_selected!),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAtlasHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(color: QuantumColors.quantumBlue, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: QuantumColors.quantumBlue, blurRadius: 8, spreadRadius: 1)]),
          ),
          const SizedBox(width: 10),
          Text('ATLAS VISUAL', style: QuantumTypography.label.copyWith(color: QuantumColors.quantumBlue, letterSpacing: 3, fontWeight: FontWeight.w900, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text('Biblioteca de Imágenes', style: QuantumTypography.h1.copyWith(fontSize: 28, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        const Text('Sube imágenes y GIFs para cada ejercicio. Se usarán en el Training Forge.', style: TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          _buildStatChip('$count mostrados', Icons.grid_view_rounded, Colors.white38),
          const SizedBox(width: 10),
          _buildStatChip('$_totalWithImage con imagen', Icons.image_rounded, const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          _buildStatChip('$_totalWithoutImage sin imagen', Icons.image_not_supported_outlined, Colors.orangeAccent),
        ]),
      ]),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _muscleFilters.map((m) {
            final sel = _filterMuscle == m;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(m),
                selected: sel,
                onSelected: (_) => setState(() { _filterMuscle = m; _selected = null; }),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                selectedColor: QuantumColors.quantumBlue.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: sel ? QuantumColors.quantumBlue : Colors.white38, fontSize: 11),
                shape: StadiumBorder(side: BorderSide(color: sel ? QuantumColors.quantumBlue.withValues(alpha: 0.4) : Colors.transparent)),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 10),
        Row(children: ['Todos', 'Con Imagen', 'Sin Imagen'].map((f) {
          final sel = _filterImage == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(f == 'Con Imagen' ? Icons.image_rounded : f == 'Sin Imagen' ? Icons.image_not_supported_outlined : Icons.photo_library_outlined,
                  size: 13, color: sel ? Colors.black87 : Colors.white30),
                const SizedBox(width: 6),
                Text(f),
              ]),
              selected: sel,
              onSelected: (_) => setState(() { _filterImage = f; _selected = null; }),
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              selectedColor: QuantumColors.quantumBlue,
              labelStyle: TextStyle(color: sel ? Colors.black87 : Colors.white38, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal),
              shape: StadiumBorder(side: BorderSide(color: sel ? QuantumColors.quantumBlue : Colors.transparent)),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList()),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GALLERY CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAtlasCard(ForgeExercise ex) {
    final isSel = _selected?.id == ex.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = ex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.06), width: isSel ? 2 : 1),
          color: const Color(0xFF12121E),
          boxShadow: isSel ? [BoxShadow(color: QuantumColors.quantumBlue.withValues(alpha: 0.15), blurRadius: 16)] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen o placeholder
            Expanded(
              flex: 3,
              child: ex.hasImage
                  ? Stack(children: [
                      Positioned.fill(
                        child: Image.memory(ex.imageBytes!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder()),
                      ),
                      Positioned(top: 8, right: 8, child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                      )),
                    ])
                  : _imagePlaceholder(),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(ex.primaryMuscle, style: const TextStyle(color: QuantumColors.quantumBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Row(children: [
                    Icon(ex.hasImage ? Icons.image_rounded : Icons.image_not_supported_outlined,
                      size: 11, color: ex.hasImage ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.16)),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      ex.hasImage ? (ex.imageName ?? 'imagen') : 'Sin imagen',
                      style: TextStyle(color: ex.hasImage ? Colors.white30 : Colors.white12, fontSize: 9),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 4),
                    const Icon(Icons.storefront_rounded, color: Colors.white12, size: 10),
                    const SizedBox(width: 3),
                    Flexible(child: Text(ex.gymCreator, style: const TextStyle(color: Colors.white12, fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.02),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fitness_center_rounded, color: Colors.white.withValues(alpha: 0.05), size: 36),
        const SizedBox(height: 6),
        Text('SIN IMAGEN', style: TextStyle(color: Colors.white.withValues(alpha: 0.08), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ])),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyGallery() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.photo_library_outlined, color: Colors.white.withValues(alpha: 0.06), size: 72),
      const SizedBox(height: 16),
      Text('No hay ejercicios con estos filtros', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 14)),
    ]));
  }

  Widget _buildEmptySelection() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Icon(Icons.photo_camera_rounded, color: Colors.white.withValues(alpha: 0.06), size: 48),
      ),
      const SizedBox(height: 20),
      const Text('Selecciona un ejercicio', style: TextStyle(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('para subir o gestionar su imagen', style: TextStyle(color: Colors.white12, fontSize: 12)),
    ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DETAIL PANEL (right side)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDetailPanel(ForgeExercise ex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title + tags
        Text(ex.name, style: QuantumTypography.h2.copyWith(fontSize: 22)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _tag(ex.exerciseType, Icons.category_outlined),
          _tag(ex.difficulty, Icons.speed_rounded),
          _tag(ex.primaryMuscle, Icons.accessibility_new_rounded),
        ]),
        const SizedBox(height: 28),

        // ── IMAGE ZONE ────────────────────────────────────
        _buildSectionLabel('IMAGEN DEL EJERCICIO'),
        const SizedBox(height: 14),
        _buildImageUploadZone(ex),
        const SizedBox(height: 28),

        // ── EXERCISE INFO ─────────────────────────────────
        _buildSectionLabel('INFORMACIÓN TÉCNICA'),
        const SizedBox(height: 14),
        _infoRow('Músculo Primario', ex.primaryMuscle),
        if (ex.secondaryMuscles.isNotEmpty) _infoRow('Músculos Sec.', ex.secondaryMuscles.join(', ')),
        _infoRow('Patrón', ex.movementPattern),
        _infoRow('Equipamiento', ex.equipment.isNotEmpty ? ex.equipment.join(', ') : 'Peso Corporal'),
        _infoRow('Gym Creador', ex.gymCreator),

        if (ex.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionLabel('DESCRIPCIÓN'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Text(ex.description, style: const TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.6)),
          ),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE UPLOAD ZONE (drag & drop style + button)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildImageUploadZone(ForgeExercise ex) {
    if (ex.hasImage) {
      return Column(children: [
        // Preview de la imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.memory(ex.imageBytes!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder()),
                ),
              ),
              // Overlay with filename
              Positioned(bottom: 0, left: 0, right: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent]),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(19), bottomRight: Radius.circular(19)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ex.imageName ?? 'imagen', style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${(ex.imageBytes!.length / 1024).toStringAsFixed(0)} KB', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                ]),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        // Action buttons
        Row(children: [
          Expanded(child: GymButton(
            text: 'CAMBIAR IMAGEN',
            icon: Icons.swap_horiz_rounded,
            size: GymButtonSize.small,
            style: GymButtonStyle.ghost,
            onPressed: () => _pickAndUploadImage(ex.id),
          )),
          const SizedBox(width: 10),
          Expanded(child: _dangerButton('ELIMINAR', Icons.delete_outline_rounded, () {
            _store.removeExerciseImage(ex.id);
          })),
        ]),
      ]);
    }

    // No image → upload zone
    return GestureDetector(
      onTap: () => _pickAndUploadImage(ex.id),
      child: DragTarget<Uint8List>(
        onWillAcceptWithDetails: (_) { setState(() => _isDragHovering = true); return true; },
        onLeave: (_) => setState(() => _isDragHovering = false),
        onAcceptWithDetails: (details) {
          setState(() => _isDragHovering = false);
          _store.setExerciseImage(ex.id, details.data, 'dropped_image');
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _isDragHovering ? QuantumColors.quantumBlue.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.015),
              border: Border.all(
                color: _isDragHovering ? QuantumColors.quantumBlue.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
                width: _isDragHovering ? 2 : 1,
              ),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_outlined, color: QuantumColors.quantumBlue.withValues(alpha: 0.6), size: 36),
              ),
              const SizedBox(height: 16),
              Text('SUBIR IMAGEN', style: TextStyle(color: QuantumColors.quantumBlue.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Click para seleccionar o arrastra una imagen', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
              const SizedBox(height: 4),
              Text('PNG, JPG, GIF • Máx 10MB', style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 10)),
            ]),
          );
        },
      ),
    );
  }

  Widget _dangerButton(String text, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.redAccent.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String label) {
    return Text(label, style: TextStyle(color: QuantumColors.quantumBlue.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5));
  }

  Widget _tag(String text, [IconData? icon]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: QuantumColors.quantumBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, color: QuantumColors.quantumBlue.withValues(alpha: 0.7), size: 13), const SizedBox(width: 7)],
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }
}
