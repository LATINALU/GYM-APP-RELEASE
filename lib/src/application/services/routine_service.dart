import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/routine_planning.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// FUNCIÓN 1: Calcular Carga de Entrenamiento (Volume Load)
  double calculateVolume(int sets, String reps, double weight) {
    // Parse reps safely (handle "12", "8-12", "Al fallo")
    final numericRepsString = reps.replaceAll(RegExp(r'[^0-9]'), '');
    final repsValue = int.tryParse(numericRepsString) ?? 0;
    return (sets * repsValue * weight).toDouble();
  }

  /// FUNCIÓN 2: Guardar Rutina (Estructura JSON en Firebase)
  Future<void> saveRoutine({
    required String memberId,
    required String staffId,
    required Map<WeekDay, List<RoutineStep>> weekPlan,
  }) async {
    // Validación: No permitir guardar si un día está vacío
    if (weekPlan.values.every((exercises) => exercises.isEmpty)) {
      throw Exception('Debes añadir al menos un ejercicio a la semana.');
    }

    final Map<String, dynamic> structure = {};
    weekPlan.forEach((day, steps) {
      structure[day.name] = steps.map((step) => step.toMap()).toList();
    });

    await _firestore.collection('routines').add({
      'assigned_to': memberId,
      'created_by': staffId,
      'created_at': FieldValue.serverTimestamp(),
      'structure': structure,
      'status': 'active',
      'version': 1.0,
    });
  }
}
