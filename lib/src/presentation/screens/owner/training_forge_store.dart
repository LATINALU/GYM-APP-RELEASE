import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_state_notifier.dart';

/// Singleton store for Training Forge data (exercises, routines, programs)
/// Persists in memory AND Firestore for the owner's gym
class TrainingForgeStore extends ChangeNotifier {
  TrainingForgeStore._();
  static final TrainingForgeStore instance = TrainingForgeStore._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<ForgeExercise> _exercises = _defaultExercises();
  final List<ForgeRoutine> _routines = _defaultRoutines();
  final List<ForgeProgram> _programs = _defaultPrograms();

  // ── EXERCISES ─────────────────────────────────────────────────────────────
  List<ForgeExercise> get exercises => List.unmodifiable(_exercises);
  int get exerciseCount => _exercises.length;

  void addExercise(ForgeExercise ex) {
    _exercises.insert(0, ex);
    notifyListeners();
  }

  void updateExercise(ForgeExercise ex) {
    final i = _exercises.indexWhere((e) => e.id == ex.id);
    if (i != -1) {
      _exercises[i] = ex;
      notifyListeners();
    }
  }

  void deleteExercise(String id) {
    _exercises.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void setExerciseImage(String exerciseId, Uint8List bytes, String fileName) {
    final i = _exercises.indexWhere((e) => e.id == exerciseId);
    if (i != -1) {
      _exercises[i] = _exercises[i].copyWith(imageBytes: bytes, imageName: fileName);
      notifyListeners();
    }
  }

  void removeExerciseImage(String exerciseId) {
    final i = _exercises.indexWhere((e) => e.id == exerciseId);
    if (i != -1) {
      _exercises[i] = _exercises[i].clearImage();
      notifyListeners();
    }
  }

  ForgeExercise? findExercise(String id) {
    final idx = _exercises.indexWhere((e) => e.id == id);
    return idx != -1 ? _exercises[idx] : null;
  }

  // ── ROUTINES ──────────────────────────────────────────────────────────────
  List<ForgeRoutine> get routines => List.unmodifiable(_routines);
  int get routineCount => _routines.length;

  Future<void> addRoutine(ForgeRoutine r) async {
    _routines.insert(0, r);
    notifyListeners();
    
    // Persist to Firestore
    await _saveRoutineToFirestore(r);
  }

  Future<void> updateRoutine(ForgeRoutine r) async {
    final i = _routines.indexWhere((e) => e.id == r.id);
    if (i != -1) {
      _routines[i] = r;
      notifyListeners();
      
      // Persist to Firestore
      await _saveRoutineToFirestore(r);
    }
  }

  Future<void> deleteRoutine(String id) async {
    _routines.removeWhere((e) => e.id == id);
    notifyListeners();
    
    // Delete from Firestore
    await _deleteRoutineFromFirestore(id);
  }

  Future<void> _saveRoutineToFirestore(ForgeRoutine routine) async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId?.value;
      final userId = auth.profile?.uid;
      
      if (gymId == null || userId == null) return;

      await _firestore.collection('routines').doc(routine.id).set({
        'gymId': gymId,
        'createdBy': userId,
        'name': routine.name,
        'description': routine.description,
        'difficulty': routine.difficulty,
        'focus': routine.focus,
        'estimatedMinutes': routine.estimatedMinutes,
        'exercises': routine.exerciseIds.map((id) => {
          'exerciseId': id,
          'order': routine.exerciseIds.indexOf(id) + 1,
          'sets': 3,
          'reps': '8-12',
          'restSeconds': 90,
        }).toList(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving routine to Firestore: $e');
    }
  }

  Future<void> _deleteRoutineFromFirestore(String routineId) async {
    try {
      await _firestore.collection('routines').doc(routineId).delete();
    } catch (e) {
      debugPrint('Error deleting routine from Firestore: $e');
    }
  }

  // ── PROGRAMS ──────────────────────────────────────────────────────────────
  List<ForgeProgram> get programs => List.unmodifiable(_programs);
  int get programCount => _programs.length;

  void addProgram(ForgeProgram p) {
    _programs.insert(0, p);
    notifyListeners();
  }

  void updateProgram(ForgeProgram p) {
    final i = _programs.indexWhere((e) => e.id == p.id);
    if (i != -1) {
      _programs[i] = p;
      notifyListeners();
    }
  }

  void deleteProgram(String id) {
    _programs.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ── DEFAULT DATA ──────────────────────────────────────────────────────────
  static List<ForgeExercise> _defaultExercises() => [
    ForgeExercise(id: 'ex_001', name: 'Press de Banca Plano', description: 'Ejercicio compuesto para pecho. Acostado en banco plano, bajar barra al pecho y empujar.', primaryMuscle: 'Pecho', secondaryMuscles: ['Tríceps', 'Hombro Anterior'], movementPattern: 'Empuje Horizontal', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra', 'Banco'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 1, 15)),
    ForgeExercise(id: 'ex_002', name: 'Sentadilla con Barra', description: 'Rey de los ejercicios. Barra en trapecios, bajar caderas por debajo de rodillas.', primaryMuscle: 'Cuádriceps', secondaryMuscles: ['Glúteos', 'Isquiotibiales', 'Core'], movementPattern: 'Sentadilla', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra', 'Rack'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 1, 15)),
    ForgeExercise(id: 'ex_003', name: 'Peso Muerto Sumo', description: 'Variante de peso muerto con stance amplio. Enfatiza aductores y glúteos.', primaryMuscle: 'Isquiotibiales', secondaryMuscles: ['Glúteos', 'Espalda Baja', 'Aductores'], movementPattern: 'Bisagra de Cadera', exerciseType: 'Compuesto', difficulty: 'Avanzado', equipment: ['Barra'], gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 1)),
    ForgeExercise(id: 'ex_004', name: 'Dominadas Pronas', description: 'Agarre prono, ancho de hombros. Subir hasta mentón sobre barra.', primaryMuscle: 'Espalda', secondaryMuscles: ['Bíceps', 'Antebrazo'], movementPattern: 'Tracción Vertical', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra de Dominadas'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 1, 20)),
    ForgeExercise(id: 'ex_005', name: 'Curl de Bíceps', description: 'Flexión de codo con mancuernas. Supinación completa al final del movimiento.', primaryMuscle: 'Bíceps', secondaryMuscles: ['Antebrazo'], movementPattern: 'Aislamiento', exerciseType: 'Aislamiento', difficulty: 'Principiante', equipment: ['Mancuernas'], gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 5)),
    ForgeExercise(id: 'ex_006', name: 'Press Militar', description: 'Press sobre cabeza con barra. De pie, empujar barra desde clavículas hasta lockout.', primaryMuscle: 'Hombros', secondaryMuscles: ['Tríceps', 'Core'], movementPattern: 'Empuje Vertical', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 1, 25)),
    ForgeExercise(id: 'ex_007', name: 'Hip Thrust', description: 'Extensión de cadera con barra apoyada en banco. Máxima activación glútea.', primaryMuscle: 'Glúteos', secondaryMuscles: ['Isquiotibiales'], movementPattern: 'Bisagra de Cadera', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra', 'Banco'], gymCreator: 'FitZone Studio', createdAt: DateTime(2025, 3, 1)),
    ForgeExercise(id: 'ex_008', name: 'Fondos en Paralelas', description: 'Descender controlado, codos a 90°. Inclinación frontal para pecho, vertical para tríceps.', primaryMuscle: 'Tríceps', secondaryMuscles: ['Pecho', 'Hombro Anterior'], movementPattern: 'Empuje Vertical', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Paralelas'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 1, 28)),
    ForgeExercise(id: 'ex_009', name: 'Remo con Barra', description: 'Inclinación a 45°, tirar barra al ombligo. Escápulas juntas arriba.', primaryMuscle: 'Espalda', secondaryMuscles: ['Bíceps', 'Romboides'], movementPattern: 'Tracción Horizontal', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra'], gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 10)),
    ForgeExercise(id: 'ex_010', name: 'Extensión de Cuádriceps', description: 'Máquina de extensión. Extender rodillas completamente, contraer cuádriceps.', primaryMuscle: 'Cuádriceps', secondaryMuscles: [], movementPattern: 'Aislamiento', exerciseType: 'Aislamiento', difficulty: 'Principiante', equipment: ['Máquina'], gymCreator: 'FitZone Studio', createdAt: DateTime(2025, 3, 5)),
    ForgeExercise(id: 'ex_011', name: 'Elevaciones Laterales', description: 'Mancuernas a los lados, elevar brazos hasta paralelo al suelo.', primaryMuscle: 'Hombros', secondaryMuscles: ['Trapecio'], movementPattern: 'Aislamiento', exerciseType: 'Aislamiento', difficulty: 'Principiante', equipment: ['Mancuernas'], gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 2, 15)),
    ForgeExercise(id: 'ex_012', name: 'Peso Muerto Rumano', description: 'Bisagra de cadera con rodillas ligeramente flexionadas. Énfasis en isquiotibiales.', primaryMuscle: 'Isquiotibiales', secondaryMuscles: ['Glúteos', 'Espalda Baja'], movementPattern: 'Bisagra de Cadera', exerciseType: 'Compuesto', difficulty: 'Intermedio', equipment: ['Barra'], gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 20)),
  ];

  static List<ForgeRoutine> _defaultRoutines() => [
    ForgeRoutine(id: 'rt_001', name: 'Empuje (Push) A', description: 'Día de empuje enfocado en pecho y hombros', exerciseIds: ['ex_001', 'ex_006', 'ex_008', 'ex_011', 'ex_005'], focus: 'Hipertrofia', difficulty: 'Intermedio', estimatedMinutes: 55, gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 2, 1)),
    ForgeRoutine(id: 'rt_002', name: 'Tracción (Pull) B', description: 'Día de tracción enfocado en espalda y bíceps', exerciseIds: ['ex_004', 'ex_009', 'ex_005', 'ex_012'], focus: 'Hipertrofia', difficulty: 'Intermedio', estimatedMinutes: 55, gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 2, 1)),
    ForgeRoutine(id: 'rt_003', name: 'Pierna Pesada C', description: 'Día de piernas con enfoque en fuerza', exerciseIds: ['ex_002', 'ex_003', 'ex_007', 'ex_010'], focus: 'Fuerza', difficulty: 'Avanzado', estimatedMinutes: 65, gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 5)),
    ForgeRoutine(id: 'rt_004', name: 'Full Body Express', description: 'Rutina completa para días con poco tiempo', exerciseIds: ['ex_002', 'ex_001', 'ex_004', 'ex_006', 'ex_007'], focus: 'Hipertrofia', difficulty: 'Intermedio', estimatedMinutes: 50, gymCreator: 'FitZone Studio', createdAt: DateTime(2025, 3, 1)),
  ];

  static List<ForgeProgram> _defaultPrograms() => [
    ForgeProgram(id: 'pg_001', name: 'PPL: 12 SEMANAS PRO', description: 'Programa Push/Pull/Legs clásico de 12 semanas para hipertrofia avanzada', routineIds: ['rt_001', 'rt_002', 'rt_003'], weeks: 12, focus: 'Fuerza', difficulty: 'Intermedio', gymCreator: 'Iron Temple Gym', createdAt: DateTime(2025, 2, 10)),
    ForgeProgram(id: 'pg_002', name: 'BASIC BULK: 3 DÍAS', description: 'Programa de volumen básico de 3 días por semana', routineIds: ['rt_001', 'rt_002', 'rt_003', 'rt_004'], weeks: 8, focus: 'Fuerza', difficulty: 'Intermedio', gymCreator: 'PowerHouse Fitness', createdAt: DateTime(2025, 2, 15)),
    ForgeProgram(id: 'pg_003', name: 'SHREDDED SEASON: 5 DÍAS', description: 'Programa de definición intenso de 5 días por semana', routineIds: ['rt_001', 'rt_002', 'rt_003', 'rt_004'], weeks: 10, focus: 'Definición', difficulty: 'Avanzado', gymCreator: 'FitZone Studio', createdAt: DateTime(2025, 3, 5)),
  ];
}

// ── DATA MODELS ─────────────────────────────────────────────────────────────

class ForgeExercise {
  final String id;
  final String name;
  final String description;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String movementPattern;
  final String exerciseType;
  final String difficulty;
  final List<String> equipment;
  final String? imageUrl;
  final String? animationUrl;
  final String? videoUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final String gymCreator;
  final DateTime createdAt;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  const ForgeExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.movementPattern,
    required this.exerciseType,
    required this.difficulty,
    this.equipment = const [],
    this.imageUrl,
    this.animationUrl,
    this.videoUrl,
    this.imageBytes,
    this.imageName,
    required this.gymCreator,
    required this.createdAt,
  });

  String get subtitle => '${primaryMuscle.toUpperCase()} • ${exerciseType.toUpperCase()} • ${equipment.isNotEmpty ? equipment.first.toUpperCase() : "CORPORAL"}';

  ForgeExercise copyWith({
    String? name,
    String? description,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? movementPattern,
    String? exerciseType,
    String? difficulty,
    List<String>? equipment,
    String? imageUrl,
    String? animationUrl,
    String? videoUrl,
    Uint8List? imageBytes,
    String? imageName,
    String? gymCreator,
  }) {
    return ForgeExercise(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      movementPattern: movementPattern ?? this.movementPattern,
      exerciseType: exerciseType ?? this.exerciseType,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      gymCreator: gymCreator ?? this.gymCreator,
      createdAt: createdAt,
    );
  }

  ForgeExercise clearImage() {
    return ForgeExercise(
      id: id,
      name: name,
      description: description,
      primaryMuscle: primaryMuscle,
      secondaryMuscles: secondaryMuscles,
      movementPattern: movementPattern,
      exerciseType: exerciseType,
      difficulty: difficulty,
      equipment: equipment,
      imageUrl: null,
      animationUrl: null,
      videoUrl: null,
      imageBytes: null,
      imageName: null,
      gymCreator: gymCreator,
      createdAt: createdAt,
    );
  }
}

class ForgeRoutine {
  final String id;
  final String name;
  final String description;
  final List<String> exerciseIds;
  final String focus;
  final String difficulty;
  final int estimatedMinutes;
  final String gymCreator;
  final DateTime createdAt;

  const ForgeRoutine({
    required this.id,
    required this.name,
    required this.description,
    this.exerciseIds = const [],
    required this.focus,
    required this.difficulty,
    this.estimatedMinutes = 45,
    required this.gymCreator,
    required this.createdAt,
  });

  String get subtitle => '${exerciseIds.length} EJERCICIOS • $estimatedMinutes MIN • ${focus.toUpperCase()}';

  ForgeRoutine copyWith({
    String? name,
    String? description,
    List<String>? exerciseIds,
    String? focus,
    String? difficulty,
    int? estimatedMinutes,
    String? gymCreator,
  }) {
    return ForgeRoutine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      focus: focus ?? this.focus,
      difficulty: difficulty ?? this.difficulty,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      gymCreator: gymCreator ?? this.gymCreator,
      createdAt: createdAt,
    );
  }
}

class ForgeProgram {
  final String id;
  final String name;
  final String description;
  final List<String> routineIds;
  final int weeks;
  final String focus;
  final String difficulty;
  final String gymCreator;
  final DateTime createdAt;

  const ForgeProgram({
    required this.id,
    required this.name,
    required this.description,
    this.routineIds = const [],
    required this.weeks,
    required this.focus,
    required this.difficulty,
    required this.gymCreator,
    required this.createdAt,
  });

  String get subtitle => '${routineIds.length} RUTINAS • ENFOQUE ${focus.toUpperCase()} • ${difficulty.toUpperCase()}';

  ForgeProgram copyWith({
    String? name,
    String? description,
    List<String>? routineIds,
    int? weeks,
    String? focus,
    String? difficulty,
    String? gymCreator,
  }) {
    return ForgeProgram(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      routineIds: routineIds ?? this.routineIds,
      weeks: weeks ?? this.weeks,
      focus: focus ?? this.focus,
      difficulty: difficulty ?? this.difficulty,
      gymCreator: gymCreator ?? this.gymCreator,
      createdAt: createdAt,
    );
  }
}
