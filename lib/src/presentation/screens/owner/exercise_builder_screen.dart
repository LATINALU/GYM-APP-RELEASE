import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

class ExerciseBuilderScreen extends StatefulWidget {
  const ExerciseBuilderScreen({super.key});

  @override
  State<ExerciseBuilderScreen> createState() => _ExerciseBuilderScreenState();
}

class _ExerciseBuilderScreenState extends State<ExerciseBuilderScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedMuscle = 'Todos';
  final List<String> _muscleGroups = [
    'Todos', 'Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 
    'Piernas', 'Glúteos', 'Abdomen', 'Cardio'
  ];

  @override
  Widget build(BuildContext context) {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Column(
        children: [
          _buildHeader(),
          _buildMuscleFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('exercises')
                  .where('gymId', isEqualTo: gymId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var exercises = snapshot.data!.docs;
                if (_selectedMuscle != 'Todos') {
                  exercises = exercises.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['muscleGroup'] == _selectedMuscle;
                  }).toList();
                }

                if (exercises.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final data = exercises[index].data() as Map<String, dynamic>;
                    return _buildExerciseCard(exercises[index].id, data);
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
          onPressed: _showAddExerciseDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.quantumBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 24),
          label: const Text(
            'NUEVO EJERCICIO',
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
                  'BIBLIOTECA DE EJERCICIOS',
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: -1,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea y gestiona ejercicios personalizados con mapas musculares',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _muscleGroups.length,
        itemBuilder: (context, index) {
          final muscle = _muscleGroups[index];
          final isSelected = muscle == _selectedMuscle;
          return GestureDetector(
            onTap: () => setState(() => _selectedMuscle = muscle),
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
                muscle,
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

  Widget _buildExerciseCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Sin nombre';
    final muscleGroup = data['muscleGroup'] ?? 'General';
    final imageUrl = data['muscleMapUrl'] as String?;
    final difficulty = data['difficulty'] ?? 'Intermedio';

    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: _getMuscleColor(muscleGroup).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Center(
                      child: Icon(
                        _getMuscleIcon(muscleGroup),
                        size: 48,
                        color: _getMuscleColor(muscleGroup),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_getMuscleIcon(muscleGroup), size: 12, color: _getMuscleColor(muscleGroup)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          muscleGroup,
                          style: TextStyle(color: _getMuscleColor(muscleGroup), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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
          Icon(Icons.fitness_center_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay ejercicios', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Crea tu primer ejercicio personalizado', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle) {
      case 'Pecho': return const Color(0xFFFF6B6B);
      case 'Espalda': return const Color(0xFF4ECDC4);
      case 'Hombros': return const Color(0xFFFFE66D);
      case 'Bíceps': return const Color(0xFF95E1D3);
      case 'Tríceps': return const Color(0xFFF38181);
      case 'Piernas': return const Color(0xFFAA96DA);
      case 'Glúteos': return const Color(0xFFFCBAD3);
      case 'Abdomen': return const Color(0xFF6BCF7F);
      case 'Cardio': return const Color(0xFF4D96FF);
      default: return QuantumColors.quantumBlue;
    }
  }

  IconData _getMuscleIcon(String muscle) {
    switch (muscle) {
      case 'Pecho': return Icons.accessibility_new;
      case 'Espalda': return Icons.accessibility;
      case 'Hombros': return Icons.airline_seat_recline_extra;
      case 'Bíceps': return Icons.fitness_center;
      case 'Tríceps': return Icons.fitness_center;
      case 'Piernas': return Icons.directions_run;
      case 'Glúteos': return Icons.airline_seat_legroom_normal;
      case 'Abdomen': return Icons.self_improvement;
      case 'Cardio': return Icons.favorite;
      default: return Icons.fitness_center;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Principiante': return QuantumColors.success;
      case 'Intermedio': return QuantumColors.accent;
      case 'Avanzado': return Colors.redAccent;
      default: return QuantumColors.quantumBlue;
    }
  }

  void _showAddExerciseDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    String selectedMuscle = 'Pecho';
    String selectedDifficulty = 'Intermedio';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('Nuevo Ejercicio', style: TextStyle(color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del ejercicio',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.fitness_center, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Grupo muscular',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.accessibility_new, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _muscleGroups.skip(1).map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setDialogState(() => selectedMuscle = v ?? 'Pecho'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
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
                    items: ['Principiante', 'Intermedio', 'Avanzado']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedDifficulty = v ?? 'Intermedio'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL de imagen del mapa muscular (opcional)',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.image, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      hintText: 'https://ejemplo.com/imagen.png',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Descripción / Instrucciones',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.description, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                await _addExercise(nameCtrl.text, selectedMuscle, selectedDifficulty, descCtrl.text, imageUrlCtrl.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.quantumBlue),
              child: const Text('Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise(String name, String muscle, String difficulty, String description, String imageUrl) async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      final data = {
        'gymId': gymId,
        'name': name,
        'muscleGroup': muscle,
        'difficulty': difficulty,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': AuthStateNotifier.instance.profile?.displayName,
      };
      
      if (imageUrl.trim().isNotEmpty) {
        data['muscleMapUrl'] = imageUrl.trim();
      }
      
      await _firestore.collection('exercises').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Ejercicio creado'), backgroundColor: QuantumColors.success),
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
