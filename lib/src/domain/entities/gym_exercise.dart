/// Exercise Library - Complete exercise database
import 'package:equatable/equatable.dart';

/// Muscle group enum
enum MuscleGroup {
  chest('Pecho', '🫁'),
  back('Espalda', '🔙'),
  shoulders('Hombros', '🦾'),
  biceps('Bíceps', '💪'),
  triceps('Tríceps', '🦵'),
  quadriceps('Cuádriceps', '🦿'),
  hamstrings('Isquiotibiales', '🦵'),
  glutes('Glúteos', '🍑'),
  calves('Gemelos', '🦶'),
  abs('Abdominales', '🎯'),
  forearms('Antebrazos', '✊'),
  traps('Trapecios', '🔺');

  final String displayName;
  final String icon;
  const MuscleGroup(this.displayName, this.icon);
}

/// Equipment type
enum Equipment {
  barbell('Barra', '🏋️'),
  dumbbell('Mancuernas', '💪'),
  machine('Máquina', '⚙️'),
  cable('Polea/Cable', '🔗'),
  bodyweight('Peso Corporal', '🧍'),
  kettlebell('Kettlebell', '🔔'),
  resistanceBand('Banda Elástica', '〰️'),
  other('Otro', '📦');

  final String displayName;
  final String icon;
  const Equipment(this.displayName, this.icon);
}

/// Exercise difficulty
enum ExerciseDifficulty {
  beginner('Principiante', 1),
  intermediate('Intermedio', 2),
  advanced('Avanzado', 3);

  final String displayName;
  final int level;
  const ExerciseDifficulty(this.displayName, this.level);
}

/// Movement pattern
enum MovementPattern {
  push('Empuje'),
  pull('Tirón'),
  squat('Sentadilla'),
  hinge('Bisagra'),
  lunge('Zancada'),
  rotation('Rotación'),
  carry('Acarreo'),
  isolation('Aislamiento');

  final String displayName;
  const MovementPattern(this.displayName);
}

/// Complete exercise definition
class GymExercise extends Equatable {
  final String id;
  final String name;
  final String description;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final ExerciseDifficulty difficulty;
  final MovementPattern pattern;
  
  // Instructions
  final List<String> instructions;
  final List<String> tips;
  final List<String> commonMistakes;
  
  // Media
  final String? imageUrl;
  final String? videoUrl;
  final String? gifUrl;
  
  // Metadata
  final bool isCompound;
  final bool requiresSpotter;
  final List<String> variations;
  final List<String> alternatives;

  const GymExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.difficulty,
    required this.pattern,
    this.instructions = const [],
    this.tips = const [],
    this.commonMistakes = const [],
    this.imageUrl,
    this.videoUrl,
    this.gifUrl,
    this.isCompound = false,
    this.requiresSpotter = false,
    this.variations = const [],
    this.alternatives = const [],
  });

  /// All muscles worked
  List<MuscleGroup> get allMuscles => [primaryMuscle, ...secondaryMuscles];

  /// Formatted instruction steps
  String get formattedInstructions => instructions.asMap().entries
      .map((e) => '${e.key + 1}. ${e.value}')
      .join('\n');

  @override
  List<Object?> get props => [id, name, primaryMuscle, equipment];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'primaryMuscle': primaryMuscle.name,
    'secondaryMuscles': secondaryMuscles.map((m) => m.name).toList(),
    'equipment': equipment.name,
    'difficulty': difficulty.name,
    'pattern': pattern.name,
    'instructions': instructions,
    'tips': tips,
    'commonMistakes': commonMistakes,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'gifUrl': gifUrl,
    'isCompound': isCompound,
    'requiresSpotter': requiresSpotter,
    'variations': variations,
    'alternatives': alternatives,
  };

  factory GymExercise.fromJson(Map<String, dynamic> json) => GymExercise(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    primaryMuscle: MuscleGroup.values.firstWhere((m) => m.name == json['primaryMuscle']),
    secondaryMuscles: (json['secondaryMuscles'] as List?)?.map((m) => MuscleGroup.values.firstWhere((mg) => mg.name == m)).toList() ?? [],
    equipment: Equipment.values.firstWhere((e) => e.name == json['equipment']),
    difficulty: ExerciseDifficulty.values.firstWhere((d) => d.name == json['difficulty']),
    pattern: MovementPattern.values.firstWhere((p) => p.name == json['pattern']),
    instructions: List<String>.from(json['instructions'] ?? []),
    tips: List<String>.from(json['tips'] ?? []),
    commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
    imageUrl: json['imageUrl'],
    videoUrl: json['videoUrl'],
    gifUrl: json['gifUrl'],
    isCompound: json['isCompound'] ?? false,
    requiresSpotter: json['requiresSpotter'] ?? false,
    variations: List<String>.from(json['variations'] ?? []),
    alternatives: List<String>.from(json['alternatives'] ?? []),
  );
}

/// Exercise Library Service - Contains all exercises
class ExerciseLibrary {
  static final List<GymExercise> _exercises = [
    // ═══════════════════════════════════════════════════════════════════════════
    // CHEST EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'bench_press',
      name: 'Press de Banca',
      description: 'Ejercicio fundamental para pecho que trabaja los pectorales, deltoides anteriores y tríceps.',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.push,
      isCompound: true,
      requiresSpotter: true,
      instructions: [
        'Acuéstate en el banco con los pies firmes en el suelo.',
        'Agarra la barra con las manos un poco más anchas que los hombros.',
        'Saca la barra del rack y posiciónala sobre el pecho.',
        'Baja la barra de forma controlada hasta tocar el pecho.',
        'Empuja la barra hacia arriba hasta extender los brazos.',
      ],
      tips: [
        'Mantén los omóplatos retraídos y el pecho elevado.',
        'Los codos a 45-75 grados del torso.',
        'Respira: inhala al bajar, exhala al subir.',
      ],
      commonMistakes: [
        'Rebotar la barra en el pecho.',
        'Arquear excesivamente la espalda.',
        'No bloquear los codos arriba.',
      ],
      variations: ['Press con mancuernas', 'Press inclinado', 'Press declinado'],
      alternatives: ['Flexiones', 'Press en máquina'],
    ),
    const GymExercise(
      id: 'incline_bench_press',
      name: 'Press Inclinado con Barra',
      description: 'Variación del press que enfatiza la parte superior del pectoral.',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.push,
      isCompound: true,
      requiresSpotter: true,
      instructions: [
        'Ajusta el banco a 30-45 grados de inclinación.',
        'Acuéstate con los pies firmes en el suelo.',
        'Agarra la barra con agarre medio-ancho.',
        'Baja la barra hasta la parte alta del pecho.',
        'Empuja hacia arriba en línea recta.',
      ],
      tips: [
        'Menor peso que el press plano.',
        '30-45° es el ángulo óptimo.',
      ],
      commonMistakes: [
        'Usar demasiada inclinación (se convierte en press de hombros).',
        'Bajar la barra muy abajo.',
      ],
    ),
    const GymExercise(
      id: 'dumbbell_flyes',
      name: 'Aperturas con Mancuernas',
      description: 'Ejercicio de aislamiento para estirar y contraer los pectorales.',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [],
      equipment: Equipment.dumbbell,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Acuéstate en el banco con una mancuerna en cada mano.',
        'Extiende los brazos sobre el pecho, palmas enfrentadas.',
        'Baja las mancuernas en arco, manteniendo codos ligeramente flexionados.',
        'Siente el estiramiento en el pecho.',
        'Sube las mancuernas siguiendo el mismo arco.',
      ],
      tips: [
        'Usa peso moderado - la técnica es más importante.',
        'No bajes más allá del nivel del banco.',
      ],
      commonMistakes: [
        'Extender completamente los codos (riesgo de lesión).',
        'Usar demasiado peso.',
      ],
    ),
    const GymExercise(
      id: 'cable_crossover',
      name: 'Cruces en Polea',
      description: 'Excelente para definición y trabajo continuo del pectoral.',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Coloca las poleas altas y agarra los mangos.',
        'Da un paso adelante con un pie para estabilidad.',
        'Con los brazos extendidos, lleva los mangos hacia el centro.',
        'Cruza ligeramente las manos al centro.',
        'Regresa de forma controlada.',
      ],
      tips: [
        'Mantén una ligera flexión de codos constante.',
        'Contrae el pecho en cada repetición.',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // BACK EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'deadlift',
      name: 'Peso Muerto',
      description: 'El rey de los ejercicios. Trabaja prácticamente todo el cuerpo con énfasis en espalda y piernas.',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.traps, MuscleGroup.forearms],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.advanced,
      pattern: MovementPattern.hinge,
      isCompound: true,
      requiresSpotter: false,
      instructions: [
        'Coloca los pies a la anchura de caderas, barra sobre el metatarso.',
        'Agáchate y agarra la barra con agarre prono o mixto.',
        'Pecho arriba, espalda recta, hombros sobre la barra.',
        'Empuja el suelo con los pies mientras elevas el torso.',
        'Bloquea caderas y rodillas arriba.',
        'Baja de forma controlada.',
      ],
      tips: [
        'La barra debe subir en línea recta pegada al cuerpo.',
        'Activa el core antes de levantar.',
        'No redondees la espalda bajo ninguna circunstancia.',
      ],
      commonMistakes: [
        'Redondear la espalda baja.',
        'Iniciar el movimiento con la espalda en lugar de las piernas.',
        'Hiperextender la espalda arriba.',
      ],
      variations: ['Peso muerto sumo', 'Peso muerto rumano', 'Peso muerto con trampa'],
    ),
    const GymExercise(
      id: 'pullups',
      name: 'Dominadas',
      description: 'Ejercicio fundamental de tracción vertical que construye una espalda ancha.',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
      equipment: Equipment.bodyweight,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.pull,
      isCompound: true,
      instructions: [
        'Agarra la barra con las manos más anchas que los hombros.',
        'Cuélgate con los brazos extendidos.',
        'Tira de tu cuerpo hacia arriba llevando el pecho a la barra.',
        'Aprieta los dorsales arriba.',
        'Baja de forma controlada.',
      ],
      tips: [
        'Inicia el movimiento con los dorsales, no los brazos.',
        'Evita el balanceo.',
      ],
      variations: ['Dominadas supinas (chin-ups)', 'Dominadas lastradas', 'Dominadas asistidas'],
    ),
    const GymExercise(
      id: 'barbell_row',
      name: 'Remo con Barra',
      description: 'Ejercicio compuesto para grosor de espalda.',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.traps],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.pull,
      isCompound: true,
      instructions: [
        'Inclínate hacia adelante con la espalda recta a 45 grados.',
        'Agarra la barra con las manos un poco más anchas que los hombros.',
        'Tira de la barra hacia el abdomen bajo.',
        'Aprieta los omóplatos arriba.',
        'Baja de forma controlada.',
      ],
      tips: [
        'Mantén el core activado.',
        'No uses impulso de la espalda baja.',
      ],
    ),
    const GymExercise(
      id: 'lat_pulldown',
      name: 'Jalón al Pecho',
      description: 'Alternativa a dominadas para trabajar dorsales.',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.pull,
      isCompound: true,
      instructions: [
        'Siéntate y ajusta el soporte de muslos.',
        'Agarra la barra ancha con agarre prono.',
        'Tira la barra hacia el pecho sacando el pecho.',
        'Aprieta los dorsales.',
        'Regresa de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'cable_row',
      name: 'Remo en Polea',
      description: 'Excelente para grosor de espalda media.',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.pull,
      isCompound: true,
      instructions: [
        'Siéntate con los pies en la plataforma.',
        'Agarra el mango con ambas manos.',
        'Tira hacia el abdomen manteniendo la espalda recta.',
        'Aprieta los omóplatos atrás.',
        'Extiende los brazos de forma controlada.',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // SHOULDER EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'ohp',
      name: 'Press Militar',
      description: 'Ejercicio fundamental para hombros que también trabaja tríceps y core.',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.traps],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.push,
      isCompound: true,
      instructions: [
        'De pie, agarra la barra a la altura de los hombros.',
        'Empuja la barra hacia arriba pasando la cara.',
        'Extiende completamente los brazos.',
        'Baja de forma controlada hasta los hombros.',
      ],
      tips: [
        'Aprieta los glúteos para estabilidad.',
        'No arquees la espalda.',
      ],
    ),
    const GymExercise(
      id: 'lateral_raise',
      name: 'Elevaciones Laterales',
      description: 'Aislamiento para el deltoides lateral - crea hombros anchos.',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [],
      equipment: Equipment.dumbbell,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'De pie con mancuernas a los lados.',
        'Eleva los brazos lateralmente hasta la altura de los hombros.',
        'Mantén una ligera flexión de codos.',
        'Baja de forma controlada.',
      ],
      tips: [
        'Lidera con los codos, no las manos.',
        'Usa peso ligero y buen control.',
      ],
    ),
    const GymExercise(
      id: 'face_pull',
      name: 'Face Pull',
      description: 'Excelente para deltoides posterior y salud del hombro.',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.back, MuscleGroup.traps],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.pull,
      isCompound: false,
      instructions: [
        'Ajusta la polea a la altura de la cara.',
        'Agarra la cuerda con agarre neutro.',
        'Tira hacia la cara separando las manos.',
        'Aprieta los omóplatos atrás.',
        'Regresa de forma controlada.',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // LEG EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'squat',
      name: 'Sentadilla',
      description: 'El ejercicio más efectivo para piernas. Base de cualquier programa serio.',
      primaryMuscle: MuscleGroup.quadriceps,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings, MuscleGroup.abs],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.squat,
      isCompound: true,
      requiresSpotter: true,
      instructions: [
        'Coloca la barra en la parte alta de la espalda (trapecios).',
        'Pies a la anchura de hombros, puntas ligeramente hacia afuera.',
        'Desbloquea las rodillas e inicia el descenso.',
        'Baja hasta que los muslos estén paralelos al suelo (o más).',
        'Empuja el suelo para subir.',
      ],
      tips: [
        'Rodillas en línea con los pies.',
        'Mantén el pecho arriba y la espalda recta.',
        'Peso sobre los talones y el centro del pie.',
      ],
      commonMistakes: [
        'Rodillas hacia adentro.',
        'Talones se despegan del suelo.',
        'Espalda se redondea.',
      ],
      variations: ['Sentadilla frontal', 'Sentadilla goblet', 'Sentadilla búlgara'],
    ),
    const GymExercise(
      id: 'leg_press',
      name: 'Prensa de Piernas',
      description: 'Excelente para cargar peso sin estrés en la espalda.',
      primaryMuscle: MuscleGroup.quadriceps,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      equipment: Equipment.machine,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.squat,
      isCompound: true,
      instructions: [
        'Siéntate con la espalda bien apoyada.',
        'Pies a la anchura de hombros en la plataforma.',
        'Desbloquea y baja la plataforma flexionando las rodillas.',
        'Baja hasta 90 grados de flexión.',
        'Empuja para extender las piernas sin bloquear rodillas.',
      ],
    ),
    const GymExercise(
      id: 'rdl',
      name: 'Peso Muerto Rumano',
      description: 'Enfocado en isquiotibiales y glúteos con menos carga en espalda baja.',
      primaryMuscle: MuscleGroup.hamstrings,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.back],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.hinge,
      isCompound: true,
      instructions: [
        'De pie con la barra, rodillas ligeramente flexionadas.',
        'Empuja las caderas hacia atrás manteniendo la espalda recta.',
        'Baja la barra por las piernas sintiendo el estiramiento.',
        'Baja hasta donde permita tu flexibilidad.',
        'Contrae glúteos para subir.',
      ],
    ),
    const GymExercise(
      id: 'leg_extension',
      name: 'Extensión de Piernas',
      description: 'Aislamiento de cuádriceps.',
      primaryMuscle: MuscleGroup.quadriceps,
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Siéntate y ajusta el respaldo y el rodillo.',
        'El rodillo debe estar sobre los tobillos.',
        'Extiende las piernas contrayendo los cuádriceps.',
        'Sostén arriba un momento.',
        'Baja de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'leg_curl',
      name: 'Curl Femoral',
      description: 'Aislamiento de isquiotibiales.',
      primaryMuscle: MuscleGroup.hamstrings,
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Acuéstate boca abajo en la máquina.',
        'Ajusta el rodillo sobre los talones.',
        'Flexiona las rodillas llevando los talones a los glúteos.',
        'Aprieta los isquiotibiales arriba.',
        'Baja de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'calf_raise',
      name: 'Elevación de Gemelos',
      description: 'Ejercicio fundamental para desarrollar los gemelos.',
      primaryMuscle: MuscleGroup.calves,
      secondaryMuscles: [],
      equipment: Equipment.machine,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Páralo con la punta de los pies en el borde.',
        'Baja los talones para estirar.',
        'Elévate sobre las puntas contrayendo los gemelos.',
        'Sostén arriba un momento.',
        'Baja de forma controlada.',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // ARM EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'barbell_curl',
      name: 'Curl con Barra',
      description: 'Ejercicio clásico para bíceps.',
      primaryMuscle: MuscleGroup.biceps,
      secondaryMuscles: [MuscleGroup.forearms],
      equipment: Equipment.barbell,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'De pie con la barra, brazos extendidos.',
        'Mantén los codos pegados al cuerpo.',
        'Flexiona los codos llevando la barra hacia los hombros.',
        'Aprieta los bíceps arriba.',
        'Baja de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'hammer_curl',
      name: 'Curl Martillo',
      description: 'Trabaja bíceps y braquial, desarrolla grosor del brazo.',
      primaryMuscle: MuscleGroup.biceps,
      secondaryMuscles: [MuscleGroup.forearms],
      equipment: Equipment.dumbbell,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'De pie con mancuernas, palmas mirándose.',
        'Mantén los codos fijos.',
        'Flexiona los codos manteniendo el agarre neutro.',
        'Baja de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'tricep_pushdown',
      name: 'Extensiones de Tríceps en Polea',
      description: 'Aislamiento efectivo para los tres cabezas del tríceps.',
      primaryMuscle: MuscleGroup.triceps,
      secondaryMuscles: [],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Agarra la barra o cuerda con las manos.',
        'Codos pegados al cuerpo.',
        'Extiende los brazos hacia abajo.',
        'Aprieta los tríceps abajo.',
        'Sube de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'dips',
      name: 'Fondos en Paralelas',
      description: 'Ejercicio compuesto para tríceps y pecho.',
      primaryMuscle: MuscleGroup.triceps,
      secondaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
      equipment: Equipment.bodyweight,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.push,
      isCompound: true,
      instructions: [
        'Agarra las barras paralelas y elévate.',
        'Inclina ligeramente hacia adelante.',
        'Baja hasta que los codos formen 90 grados.',
        'Empuja para subir.',
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════════════
    // CORE EXERCISES
    // ═══════════════════════════════════════════════════════════════════════════
    const GymExercise(
      id: 'plank',
      name: 'Plancha',
      description: 'Ejercicio isométrico fundamental para el core.',
      primaryMuscle: MuscleGroup.abs,
      secondaryMuscles: [MuscleGroup.shoulders],
      equipment: Equipment.bodyweight,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Apoya antebrazos y puntas de pies.',
        'Cuerpo en línea recta de cabeza a talones.',
        'Contrae el core y glúteos.',
        'Mantén la posición el tiempo indicado.',
      ],
    ),
    const GymExercise(
      id: 'hanging_leg_raise',
      name: 'Elevación de Piernas Colgado',
      description: 'Ejercicio avanzado para abdomen inferior.',
      primaryMuscle: MuscleGroup.abs,
      secondaryMuscles: [],
      equipment: Equipment.bodyweight,
      difficulty: ExerciseDifficulty.intermediate,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Cuélgate de una barra.',
        'Mantén las piernas juntas.',
        'Eleva las piernas hasta 90 grados.',
        'Baja de forma controlada.',
      ],
    ),
    const GymExercise(
      id: 'cable_crunch',
      name: 'Crunch en Polea',
      description: 'Crunch con resistencia progresiva.',
      primaryMuscle: MuscleGroup.abs,
      secondaryMuscles: [],
      equipment: Equipment.cable,
      difficulty: ExerciseDifficulty.beginner,
      pattern: MovementPattern.isolation,
      isCompound: false,
      instructions: [
        'Arrodíllate frente a la polea alta.',
        'Sostén la cuerda detrás de la cabeza.',
        'Flexiona el torso llevando los codos hacia las rodillas.',
        'Aprieta los abdominales.',
        'Sube de forma controlada.',
      ],
    ),
  ];

  /// Get all exercises
  static List<GymExercise> get all => _exercises;

  /// Get exercise by ID
  static GymExercise? getById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get exercises by muscle group
  static List<GymExercise> getByMuscle(MuscleGroup muscle) {
    return _exercises.where((e) => e.primaryMuscle == muscle || e.secondaryMuscles.contains(muscle)).toList();
  }

  /// Get exercises by equipment
  static List<GymExercise> getByEquipment(Equipment equipment) {
    return _exercises.where((e) => e.equipment == equipment).toList();
  }

  /// Get exercises by difficulty
  static List<GymExercise> getByDifficulty(ExerciseDifficulty difficulty) {
    return _exercises.where((e) => e.difficulty == difficulty).toList();
  }

  /// Get compound exercises only
  static List<GymExercise> get compoundOnly {
    return _exercises.where((e) => e.isCompound).toList();
  }

  /// Search exercises by name
  static List<GymExercise> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _exercises.where((e) => 
      e.name.toLowerCase().contains(lowerQuery) ||
      e.primaryMuscle.displayName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get exercise count
  static int get count => _exercises.length;
}
