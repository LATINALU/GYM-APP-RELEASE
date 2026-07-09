import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

class SimpleRoutineBuilderScreen extends StatefulWidget {
  const SimpleRoutineBuilderScreen({super.key});

  @override
  State<SimpleRoutineBuilderScreen> createState() => _SimpleRoutineBuilderScreenState();
}

class _SimpleRoutineBuilderScreenState extends State<SimpleRoutineBuilderScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedDifficulty = 'Todos';
  final List<String> _difficulties = ['Todos', 'Principiante', 'Intermedio', 'Avanzado'];

  @override
  Widget build(BuildContext context) {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Column(
        children: [
          _buildHeader(),
          _buildDifficultyFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('routines')
                  .where('gymId', isEqualTo: gymId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var routines = snapshot.data!.docs;
                if (_selectedDifficulty != 'Todos') {
                  routines = routines.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['difficulty'] == _selectedDifficulty;
                  }).toList();
                }

                if (routines.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final data = routines[index].data() as Map<String, dynamic>;
                    return _buildRoutineCard(routines[index].id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: ElevatedButton.icon(
          onPressed: _showAddRoutineDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.quantumBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 24),
          label: const Text(
            'NUEVA RUTINA',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: QuantumColors.quantumBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: QuantumColors.quantumBlue,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'CONSTRUCTOR',
                      style: TextStyle(
                        color: QuantumColors.quantumBlue,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'LABORATORIO DE RUTINAS',
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: -1,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diseña rutinas de entrenamiento para tus clientes',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _difficulties.length,
        itemBuilder: (context, index) {
          final difficulty = _difficulties[index];
          final isSelected = difficulty == _selectedDifficulty;
          return GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = difficulty),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Sin nombre';
    final difficulty = data['difficulty'] ?? 'Intermedio';
    final exerciseCount = (data['exercises'] as List?)?.length ?? 0;
    final duration = data['estimatedDuration'] ?? 60;
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _getDifficultyColor(difficulty).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Center(
                      child: Icon(
                        Icons.architecture_rounded,
                        size: 64,
                        color: _getDifficultyColor(difficulty),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      color: _getDifficultyColor(difficulty),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '$exerciseCount ejercicios',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '$duration min',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay rutinas', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Crea tu primera rutina de entrenamiento', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Principiante': return QuantumColors.success;
      case 'Intermedio': return QuantumColors.accent;
      case 'Avanzado': return Colors.redAccent;
      default: return QuantumColors.quantumBlue;
    }
  }

  void _showAddRoutineDialog() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    final descCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    String selectedDifficulty = 'Intermedio';
    List<Map<String, dynamic>> selectedExercises = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('Nueva Rutina', style: TextStyle(color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre de la rutina',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.architecture, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDifficulty,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Dificultad',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.trending_up, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _difficulties.skip(1).map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setDialogState(() => selectedDifficulty = v ?? 'Intermedio'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Duración estimada (minutos)',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.timer, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL de imagen de referencia (opcional)',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.image, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      hintText: 'https://ejemplo.com/rutina.png',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.description, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ejercicios de la rutina',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await _showExerciseSelector(ctx);
                          if (selected != null) {
                            setDialogState(() => selectedExercises.add(selected));
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, color: QuantumColors.quantumBlue),
                        label: const Text('Agregar ejercicio', style: TextStyle(color: QuantumColors.quantumBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: selectedExercises.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Center(
                              child: Text(
                                'No hay ejercicios agregados',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: selectedExercises.length,
                            itemBuilder: (context, index) {
                              final ex = selectedExercises[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fitness_center, color: QuantumColors.quantumBlue, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ex['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Text(ex['muscleGroup'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                      onPressed: () => setDialogState(() => selectedExercises.removeAt(index)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _addRoutine(
                  nameCtrl.text,
                  selectedDifficulty,
                  int.tryParse(durationCtrl.text) ?? 60,
                  descCtrl.text,
                  imageUrlCtrl.text,
                  selectedExercises,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.quantumBlue),
              child: const Text('Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showExerciseSelector(BuildContext parentContext) async {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
    final searchCtrl = TextEditingController();
    String searchQuery = '';

    return showDialog<Map<String, dynamic>>(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSearchState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Seleccionar Ejercicio', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: QuantumColors.quantumBlue),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (value) => setSearchState(() => searchQuery = value.toLowerCase()),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('exercises').where('gymId', isEqualTo: gymId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var exercises = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final muscle = (data['muscleGroup'] ?? '').toString().toLowerCase();
                  return searchQuery.isEmpty || name.contains(searchQuery) || muscle.contains(searchQuery);
                }).toList();

                if (exercises.isEmpty) {
                  return const Center(
                    child: Text('No hay ejercicios disponibles', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final data = exercises[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Sin nombre';
                    final muscle = data['muscleGroup'] ?? 'General';
                    final difficulty = data['difficulty'] ?? 'Intermedio';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.fitness_center, color: QuantumColors.quantumBlue),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('$muscle • $difficulty', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.add_circle, color: QuantumColors.quantumBlue),
                        onTap: () {
                          Navigator.pop(ctx, {
                            'id': exercises[index].id,
                            'name': name,
                            'muscleGroup': muscle,
                            'difficulty': difficulty,
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addRoutine(
    String name,
    String difficulty,
    int duration,
    String description,
    String imageUrl,
    List<Map<String, dynamic>> exercises,
  ) async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      final data = {
        'gymId': gymId,
        'name': name,
        'difficulty': difficulty,
        'estimatedDuration': duration,
        'description': description,
        'exercises': exercises.map((ex) => {
          'exerciseId': ex['id'],
          'exerciseName': ex['name'],
          'muscleGroup': ex['muscleGroup'],
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': AuthStateNotifier.instance.profile?.displayName,
      };

      if (imageUrl.trim().isNotEmpty) {
        data['imageUrl'] = imageUrl.trim();
      }

      await _firestore.collection('routines').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Rutina creada'), backgroundColor: QuantumColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
