import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

class ProgramBuilderScreen extends StatefulWidget {
  const ProgramBuilderScreen({super.key});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedType = 'Todos';
  final List<String> _programTypes = ['Todos', 'Hipertrofia', 'Fuerza', 'Pérdida de Peso', 'Resistencia', 'Funcional'];

  @override
  Widget build(BuildContext context) {
    final gymId = AuthStateNotifier.instance.profile?.gymId?.value;

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Column(
        children: [
          _buildHeader(),
          _buildTypeFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('training_programs')
                  .where('gymId', isEqualTo: gymId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var programs = snapshot.data!.docs;
                if (_selectedType != 'Todos') {
                  programs = programs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['type'] == _selectedType;
                  }).toList();
                }

                if (programs.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final data = programs[index].data() as Map<String, dynamic>;
                    return _buildProgramCard(programs[index].id, data);
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
          onPressed: _showAddProgramDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: QuantumColors.quantumBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 24),
          label: const Text(
            'CREAR PROGRAMA',
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
                  'ESTUDIO DE PROGRAMAS',
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: -1,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Diseña programas de entrenamiento completos con múltiples rutinas',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _programTypes.length,
        itemBuilder: (context, index) {
          final type = _programTypes[index];
          final isSelected = type == _selectedType;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
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
                type,
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

  Widget _buildProgramCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Sin nombre';
    final type = data['type'] ?? 'General';
    final duration = data['duration'] ?? 4;
    final routinesCount = (data['routines'] as List?)?.length ?? 0;
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
                color: _getTypeColor(type).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Center(
                      child: Icon(
                        _getTypeIcon(type),
                        size: 64,
                        color: _getTypeColor(type),
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
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 14, color: _getTypeColor(type)),
                    const SizedBox(width: 4),
                    Text(
                      type,
                      style: TextStyle(color: _getTypeColor(type), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '$duration semanas',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$routinesCount rutinas',
                        style: const TextStyle(
                          color: QuantumColors.quantumBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
          Icon(Icons.calendar_view_week_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay programas', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Crea tu primer programa de entrenamiento', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Hipertrofia': return const Color(0xFFFF6B6B);
      case 'Fuerza': return const Color(0xFFFFE66D);
      case 'Pérdida de Peso': return const Color(0xFF4ECDC4);
      case 'Resistencia': return const Color(0xFF95E1D3);
      case 'Funcional': return const Color(0xFFAA96DA);
      default: return QuantumColors.quantumBlue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Hipertrofia': return Icons.fitness_center;
      case 'Fuerza': return Icons.sports_kabaddi;
      case 'Pérdida de Peso': return Icons.trending_down;
      case 'Resistencia': return Icons.directions_run;
      case 'Funcional': return Icons.sports_gymnastics;
      default: return Icons.calendar_view_week;
    }
  }

  void _showAddProgramDialog() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '4');
    final descCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    String selectedType = 'Hipertrofia';
    List<Map<String, dynamic>> selectedRoutines = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('Nuevo Programa', style: TextStyle(color: Colors.white)),
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
                      labelText: 'Nombre del programa',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.calendar_view_week, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tipo de programa',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.category, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: _programTypes.skip(1).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v ?? 'Hipertrofia'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Duración (semanas)',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.calendar_today, color: QuantumColors.quantumBlue),
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
                      labelText: 'URL de imagen del programa (opcional)',
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.image, color: QuantumColors.quantumBlue),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      hintText: 'https://ejemplo.com/programa.png',
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
                        'Rutinas del programa',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await _showRoutineSelector(ctx);
                          if (selected != null) {
                            setDialogState(() => selectedRoutines.add(selected));
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, color: QuantumColors.quantumBlue),
                        label: const Text('Agregar rutina', style: TextStyle(color: QuantumColors.quantumBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: selectedRoutines.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Center(
                              child: Text(
                                'No hay rutinas agregadas',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: selectedRoutines.length,
                            itemBuilder: (context, index) {
                              final routine = selectedRoutines[index];
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
                                    const Icon(Icons.architecture, color: QuantumColors.quantumBlue, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(routine['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Text('${routine['exerciseCount']} ejercicios • ${routine['duration']} min', 
                                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                      onPressed: () => setDialogState(() => selectedRoutines.removeAt(index)),
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
                await _addProgram(
                  nameCtrl.text,
                  selectedType,
                  int.tryParse(durationCtrl.text) ?? 4,
                  descCtrl.text,
                  imageUrlCtrl.text,
                  selectedRoutines,
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

  Future<Map<String, dynamic>?> _showRoutineSelector(BuildContext parentContext) async {
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
                  const Text('Seleccionar Rutina', style: TextStyle(color: Colors.white)),
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
                  hintText: 'Buscar rutina...',
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
              stream: _firestore.collection('routines').where('gymId', isEqualTo: gymId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var routines = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final difficulty = (data['difficulty'] ?? '').toString().toLowerCase();
                  return searchQuery.isEmpty || name.contains(searchQuery) || difficulty.contains(searchQuery);
                }).toList();

                if (routines.isEmpty) {
                  return const Center(
                    child: Text('No hay rutinas disponibles', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final data = routines[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Sin nombre';
                    final difficulty = data['difficulty'] ?? 'Intermedio';
                    final exerciseCount = (data['exercises'] as List?)?.length ?? 0;
                    final duration = data['estimatedDuration'] ?? 60;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: const Icon(Icons.architecture, color: QuantumColors.quantumBlue),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('$difficulty • $exerciseCount ejercicios • $duration min', 
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.add_circle, color: QuantumColors.quantumBlue),
                        onTap: () {
                          Navigator.pop(ctx, {
                            'id': routines[index].id,
                            'name': name,
                            'difficulty': difficulty,
                            'exerciseCount': exerciseCount,
                            'duration': duration,
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

  Future<void> _addProgram(
    String name,
    String type,
    int duration,
    String description,
    String imageUrl,
    List<Map<String, dynamic>> routines,
  ) async {
    try {
      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      final data = {
        'gymId': gymId,
        'name': name,
        'type': type,
        'duration': duration,
        'description': description,
        'routines': routines.map((r) => {
          'routineId': r['id'],
          'routineName': r['name'],
          'difficulty': r['difficulty'],
          'exerciseCount': r['exerciseCount'],
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': AuthStateNotifier.instance.profile?.displayName,
      };

      if (imageUrl.trim().isNotEmpty) {
        data['imageUrl'] = imageUrl.trim();
      }

      await _firestore.collection('training_programs').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Programa creado'), backgroundColor: QuantumColors.success),
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
