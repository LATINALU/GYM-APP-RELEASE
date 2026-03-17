import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../../../core/auth/auth_state_notifier.dart';

class RoutineManagementScreen extends StatefulWidget {
  const RoutineManagementScreen({super.key});

  @override
  State<RoutineManagementScreen> createState() => _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen> {
  final List<String> _selectedExercises = [];
  String? _selectedClientId;
  String? _selectedClientName;
  final List<Map<String, String>> _exercises = [];
  String _searchQuery = '';
  bool _isLoadingExercises = true;
  String? _exerciseLoadError;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Gestionar Rutina', style: QuantumTypography.h3),
        actions: [
          TextButton(
            onPressed: _selectedExercises.isEmpty ? null : _handleAssign,
            child: Text(
              'Asignar',
              style: TextStyle(
                color: _selectedExercises.isEmpty 
                  ? Colors.white24 
                  : QuantumColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar ejercicio...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_isLoadingExercises) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exerciseLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _exerciseLoadError!,
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

    final filteredExercises = _exercises.where((exercise) {
      if (_searchQuery.isEmpty) return true;
      final name = (exercise['name'] ?? '').toLowerCase();
      final category = (exercise['category'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();

    if (filteredExercises.isEmpty) {
      return const Center(
        child: Text(
          'No hay ejercicios disponibles.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        final exerciseId = exercise['id'] ?? '';
        final isSelected = _selectedExercises.contains(exerciseId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: QuantumColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? QuantumColors.primary.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedExercises.add(exerciseId);
                } else {
                  _selectedExercises.remove(exerciseId);
                }
              });
            },
            title: Text(
              exercise['name'] ?? 'Ejercicio',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              exercise['category'] ?? 'General',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            activeColor: QuantumColors.primary,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingExercises = true;
      _exerciseLoadError = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('exercises')
              .where('isActive', isEqualTo: true)
              .get();

      final exercises =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final heatmap = Map<String, dynamic>.from(data['heatmap'] as Map? ?? {});
            final primaryMuscle =
                heatmap.entries.isNotEmpty
                    ? heatmap.entries.reduce(
                      (current, next) =>
                          (next.value as num).toDouble() > (current.value as num).toDouble()
                              ? next
                              : current,
                    ).key
                    : 'General';

            return <String, String>{
              'id': doc.id,
              'name': data['name']?.toString() ?? 'Ejercicio',
              'category': primaryMuscle,
            };
          }).toList();

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
        _exerciseLoadError = 'No se pudieron cargar los ejercicios.';
        _isLoadingExercises = false;
      });
    }
  }

  Future<void> _handleAssign() async {
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;
    
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del gimnasio')),
      );
      return;
    }

    // Paso 1: Seleccionar cliente
    await _showClientSelectionDialog(gymId);
    
    if (_selectedClientId == null) return;

    // Paso 2: Seleccionar rutina
    await _showRoutineSelectionDialog(gymId);
  }

  Future<void> _showClientSelectionDialog(String gymId) async {
    // Obtener clientes del gimnasio
    final clientsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('gymId', isEqualTo: gymId)
        .where('role.type', isEqualTo: 'client')
        .get();

    if (!mounted) return;

    if (clientsSnapshot.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: QuantumColors.cardBackground,
          title: const Text('Sin clientes', style: TextStyle(color: Colors.white)),
          content: const Text('No hay clientes en el gimnasio.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final clients = clientsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['displayName'] ?? 'Sin nombre',
        'email': data['email'] ?? '',
      };
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleccionar Cliente', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  itemBuilder: (_, i) {
                    final client = clients[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuantumColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: QuantumColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            client['name'].toString()[0].toUpperCase(),
                            style: const TextStyle(color: QuantumColors.primary),
                          ),
                        ),
                        title: Text(client['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(client['email'].toString(), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedClientId = client['id'].toString();
                            _selectedClientName = client['name'].toString();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoutineSelectionDialog(String gymId) async {
    // Obtener rutinas del gimnasio
    final routinesSnapshot = await FirebaseFirestore.instance
        .collection('routines')
        .where('gymId', isEqualTo: gymId)
        .where('isActive', isEqualTo: true)
        .get();

    if (!mounted) return;

    if (routinesSnapshot.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: QuantumColors.cardBackground,
          title: const Text('Sin rutinas disponibles', style: TextStyle(color: Colors.white)),
          content: const Text('No hay rutinas activas en el gimnasio.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final routines = routinesSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sin nombre',
        'difficulty': data['difficulty'] ?? 'intermediate',
        'focus': data['focus'] ?? 'general',
        'exerciseCount': (data['exercises'] as List?)?.length ?? 0,
      };
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asignar Rutina', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Para: $_selectedClientName', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: routines.length,
                  itemBuilder: (_, i) {
                    final routine = routines[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuantumColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: QuantumColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center, color: QuantumColors.primary, size: 20),
                        ),
                        title: Text(routine['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${routine['exerciseCount']} ejercicios · ${routine['difficulty']} · ${routine['focus']}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmAssignment(routine);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAssignment(Map<String, dynamic> routine) async {
    final startDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final endDateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Asignación', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rutina: ${routine['name']}', style: const TextStyle(color: QuantumColors.primary, fontWeight: FontWeight.bold)),
              Text('Cliente: $_selectedClientName', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: startDateCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fecha de inicio',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endDateCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fecha de fin (opcional)',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: QuantumColors.primary),
            child: const Text('Asignar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveAssignment(routine, startDateCtrl.text, endDateCtrl.text, notesCtrl.text);
    }
  }

  Future<void> _saveAssignment(
    Map<String, dynamic> routine,
    String startDate,
    String endDate,
    String notes,
  ) async {
    try {
      final auth = AuthStateNotifier.instance;
      final assignerId = auth.profile?.uid;
      final gymId = auth.profile?.gymId?.value;
      final parsedStartDate = DateTime.tryParse(startDate);
      final parsedEndDate = endDate.isNotEmpty ? DateTime.tryParse(endDate) : null;

      if (assignerId == null || _selectedClientId == null || gymId == null) {
        throw Exception('Datos incompletos');
      }
      if (parsedStartDate == null) {
        throw Exception('La fecha de inicio no es válida');
      }
      if (endDate.isNotEmpty && parsedEndDate == null) {
        throw Exception('La fecha de fin no es válida');
      }

      await FirebaseFirestore.instance.collection('assignments').add({
        'routineId': routine['id'],
        'clientId': _selectedClientId,
        'assignedById': assignerId,
        'assignedAt': DateTime.now().toIso8601String(),
        'startDate': parsedStartDate.toIso8601String(),
        'endDate': parsedEndDate?.toIso8601String(),
        'notes': notes.isNotEmpty ? notes : null,
        'status': 'active',
        'gymId': gymId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Rutina "${routine['name']}" asignada a $_selectedClientName'),
            backgroundColor: QuantumColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Reset selection
        setState(() {
          _selectedClientId = null;
          _selectedClientName = null;
          _selectedExercises.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar rutina: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
