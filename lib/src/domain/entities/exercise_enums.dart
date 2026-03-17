/// Exercise Scope - Alcance del ejercicio (global por Admin o específico de gym)
enum ExerciseScope {
  global,  // Creado por Admin, disponible para todos los gyms
  gym,     // Creado por Owner, solo disponible en su gym
}

extension ExerciseScopeX on ExerciseScope {
  String get displayName {
    switch (this) {
      case ExerciseScope.global:
        return 'Global (Plataforma)';
      case ExerciseScope.gym:
        return 'Personalizado (Gym)';
    }
  }
}

/// Movement Pattern - Patrón de movimiento del ejercicio
enum MovementPattern {
  // Empuje
  verticalPush,      // Press Militar, Press Hombros
  horizontalPush,    // Press Banca, Fondos
  
  // Tracción
  verticalPull,      // Dominadas, Jalón
  horizontalPull,    // Remo
  
  // Piernas
  squat,             // Sentadilla, Prensa
  hipHinge,          // Peso Muerto, RDL
  lunge,             // Zancadas
  kneeFlexion,       // Extensión de cuádriceps
  hipExtension,      // Hip Thrust
  
  // Aislamiento
  isolation,         // Curl, Extensiones
  
  // Core
  coreStability,     // Plancha
  coreFlexion,       // Crunch
  coreRotation,      // Russian twist
  
  // Otros
  carry,             // Farmer's walk
  plyometric,        // Box jump
}

extension MovementPatternX on MovementPattern {
  String get displayName {
    switch (this) {
      case MovementPattern.verticalPush:
        return 'Empuje Vertical';
      case MovementPattern.horizontalPush:
        return 'Empuje Horizontal';
      case MovementPattern.verticalPull:
        return 'Tracción Vertical';
      case MovementPattern.horizontalPull:
        return 'Tracción Horizontal';
      case MovementPattern.squat:
        return 'Sentadilla';
      case MovementPattern.hipHinge:
        return 'Bisagra de Cadera';
      case MovementPattern.lunge:
        return 'Zancada';
      case MovementPattern.kneeFlexion:
        return 'Flexión de Rodilla';
      case MovementPattern.hipExtension:
        return 'Extensión de Cadera';
      case MovementPattern.isolation:
        return 'Aislamiento';
      case MovementPattern.coreStability:
        return 'Core - Estabilidad';
      case MovementPattern.coreFlexion:
        return 'Core - Flexión';
      case MovementPattern.coreRotation:
        return 'Core - Rotación';
      case MovementPattern.carry:
        return 'Carga/Transporte';
      case MovementPattern.plyometric:
        return 'Pliométrico';
    }
  }
  
  String get icon {
    switch (this) {
      case MovementPattern.verticalPush:
        return '⬆️';
      case MovementPattern.horizontalPush:
        return '➡️';
      case MovementPattern.verticalPull:
        return '⬇️';
      case MovementPattern.horizontalPull:
        return '⬅️';
      case MovementPattern.squat:
        return '🏋️';
      case MovementPattern.hipHinge:
        return '🔄';
      case MovementPattern.lunge:
        return '🚶';
      case MovementPattern.kneeFlexion:
        return '🦵';
      case MovementPattern.hipExtension:
        return '🍑';
      case MovementPattern.isolation:
        return '💪';
      case MovementPattern.coreStability:
        return '🧘';
      case MovementPattern.coreFlexion:
        return '🔻';
      case MovementPattern.coreRotation:
        return '🔃';
      case MovementPattern.carry:
        return '🏃';
      case MovementPattern.plyometric:
        return '🦘';
    }
  }
}

/// Equipment Type - Tipo de equipamiento necesario
enum EquipmentType {
  barbell,           // Barra olímpica
  dumbbell,          // Mancuernas
  kettlebell,        // Kettlebell/Pesa rusa
  cable,             // Poleas/Cables
  machine,           // Máquina
  smithMachine,      // Máquina Smith
  bodyweight,        // Peso corporal
  resistanceBand,    // Bandas de resistencia
  medicineBall,      // Balón medicinal
  pullupBar,         // Barra de dominadas
  bench,             // Banco
  box,               // Cajón
  trapBar,           // Trap Bar/Hex Bar
  ezBar,             // Barra Z/EZ
  specialtyBar,      // Barras especiales (SSB, Buffalo, etc)
}

extension EquipmentTypeX on EquipmentType {
  String get displayName {
    switch (this) {
      case EquipmentType.barbell:
        return 'Barra';
      case EquipmentType.dumbbell:
        return 'Mancuernas';
      case EquipmentType.kettlebell:
        return 'Kettlebell';
      case EquipmentType.cable:
        return 'Polea/Cable';
      case EquipmentType.machine:
        return 'Máquina';
      case EquipmentType.smithMachine:
        return 'Máquina Smith';
      case EquipmentType.bodyweight:
        return 'Peso Corporal';
      case EquipmentType.resistanceBand:
        return 'Banda Elástica';
      case EquipmentType.medicineBall:
        return 'Balón Medicinal';
      case EquipmentType.pullupBar:
        return 'Barra de Dominadas';
      case EquipmentType.bench:
        return 'Banco';
      case EquipmentType.box:
        return 'Cajón';
      case EquipmentType.trapBar:
        return 'Trap Bar';
      case EquipmentType.ezBar:
        return 'Barra EZ';
      case EquipmentType.specialtyBar:
        return 'Barra Especial';
    }
  }
  
  String get icon {
    switch (this) {
      case EquipmentType.barbell:
        return '🏋️';
      case EquipmentType.dumbbell:
        return '💪';
      case EquipmentType.kettlebell:
        return '🔔';
      case EquipmentType.cable:
        return '🔗';
      case EquipmentType.machine:
        return '⚙️';
      case EquipmentType.smithMachine:
        return '🔧';
      case EquipmentType.bodyweight:
        return '🧍';
      case EquipmentType.resistanceBand:
        return '〰️';
      case EquipmentType.medicineBall:
        return '⚽';
      case EquipmentType.pullupBar:
        return '🔝';
      case EquipmentType.bench:
        return '🛋️';
      case EquipmentType.box:
        return '📦';
      case EquipmentType.trapBar:
        return '⬡';
      case EquipmentType.ezBar:
        return '〰️';
      case EquipmentType.specialtyBar:
        return '⚒️';
    }
  }
}

/// Exercise Type - Tipo de ejercicio
enum ExerciseType {
  compound,          // Compuesto/Multiarticular
  isolation,         // Aislamiento
  accessory,         // Accesorio
  plyometric,        // Pliométrico
  isometric,         // Isométrico
  cardio,            // Cardiovascular
}

extension ExerciseTypeX on ExerciseType {
  String get displayName {
    switch (this) {
      case ExerciseType.compound:
        return 'Compuesto';
      case ExerciseType.isolation:
        return 'Aislamiento';
      case ExerciseType.accessory:
        return 'Accesorio';
      case ExerciseType.plyometric:
        return 'Pliométrico';
      case ExerciseType.isometric:
        return 'Isométrico';
      case ExerciseType.cardio:
        return 'Cardio';
    }
  }
  
  /// Color hex para UI
  String get colorHex {
    switch (this) {
      case ExerciseType.compound:
        return '#EF4444'; // Rojo
      case ExerciseType.isolation:
        return '#3B82F6'; // Azul
      case ExerciseType.accessory:
        return '#10B981'; // Verde
      case ExerciseType.plyometric:
        return '#F59E0B'; // Amarillo
      case ExerciseType.isometric:
        return '#8B5CF6'; // Púrpura
      case ExerciseType.cardio:
        return '#EC4899'; // Rosa
    }
  }
}

/// Exercise Difficulty Level
enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

extension ExerciseDifficultyX on ExerciseDifficulty {
  String get displayName {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return 'Principiante';
      case ExerciseDifficulty.intermediate:
        return 'Intermedio';
      case ExerciseDifficulty.advanced:
        return 'Avanzado';
      case ExerciseDifficulty.expert:
        return 'Experto';
    }
  }
  
  int get stars {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return 1;
      case ExerciseDifficulty.intermediate:
        return 2;
      case ExerciseDifficulty.advanced:
        return 3;
      case ExerciseDifficulty.expert:
        return 4;
    }
  }
}

/// Rep Range Type - Rango de repeticiones recomendado
enum RepRangeType {
  strength,          // 1-5 reps - Fuerza
  hypertrophy,       // 6-12 reps - Hipertrofia
  endurance,         // 12+ reps - Resistencia
  power,             // 1-5 reps explosivas
}

extension RepRangeTypeX on RepRangeType {
  String get displayName {
    switch (this) {
      case RepRangeType.strength:
        return 'Fuerza (1-5)';
      case RepRangeType.hypertrophy:
        return 'Hipertrofia (6-12)';
      case RepRangeType.endurance:
        return 'Resistencia (12+)';
      case RepRangeType.power:
        return 'Potencia';
    }
  }
  
  int get minReps {
    switch (this) {
      case RepRangeType.strength:
        return 1;
      case RepRangeType.hypertrophy:
        return 6;
      case RepRangeType.endurance:
        return 12;
      case RepRangeType.power:
        return 1;
    }
  }
  
  int get maxReps {
    switch (this) {
      case RepRangeType.strength:
        return 5;
      case RepRangeType.hypertrophy:
        return 12;
      case RepRangeType.endurance:
        return 30;
      case RepRangeType.power:
        return 5;
    }
  }
  
  int get restSeconds {
    switch (this) {
      case RepRangeType.strength:
        return 180; // 3-5 min
      case RepRangeType.hypertrophy:
        return 90;  // 60-120 sec
      case RepRangeType.endurance:
        return 45;  // 30-60 sec
      case RepRangeType.power:
        return 240; // 3-5 min
    }
  }
}
