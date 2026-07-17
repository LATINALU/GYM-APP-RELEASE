import '../entities/workout_routine.dart';
import '../ports/input/manage_routine_usecase_port.dart';

/// Rutina predefinida construida con ejercicios del dataset
class RoutineSeed {
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final List<RoutineExerciseInput> exercises;

  const RoutineSeed({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.exercises,
  });
}

/// Catálogo de rutinas predefinidas profesionales
///
/// Todos los `templateId` son IDs verificados del dataset (`ds_XXXX`,
/// ver [DatasetExerciseCatalog]), por lo que cada ejercicio trae GIF,
/// thumbnail e instrucciones en español.
class RoutineSeeds {
  RoutineSeeds._();

  static const List<RoutineSeed> all = [
    RoutineSeed(
      name: 'Full Body Principiante',
      description:
          'Rutina de cuerpo completo ideal para empezar: patrones básicos '
          'con mancuernas y peso corporal, 3 días por semana.',
      difficulty: DifficultyLevel.beginner,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_1760', // dumbbell goblet squat
          order: 0, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0662', // push-up
          order: 1, sets: 3, minReps: 8, maxReps: 12, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_2330', // cable lat pulldown full range of motion
          order: 2, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0426', // dumbbell standing overhead press
          order: 3, sets: 3, minReps: 8, maxReps: 10, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3013', // low glute bridge on floor
          order: 4, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0001', // 3/4 sit-up
          order: 5, sets: 3, minReps: 12, maxReps: 15, restSeconds: 45,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Empuje — Pecho, Hombros y Tríceps',
      description:
          'Día de empuje del clásico Push/Pull/Legs: press pesados primero, '
          'aislamiento al final.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0025', // barbell bench press
          order: 0, sets: 4, minReps: 6, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0047', // barbell incline bench press
          order: 1, sets: 3, minReps: 8, maxReps: 10, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0426', // dumbbell standing overhead press
          order: 2, sets: 3, minReps: 8, maxReps: 10, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0334', // dumbbell lateral raise
          order: 3, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0251', // chest dip
          order: 4, sets: 3, minReps: 8, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0201', // cable pushdown
          order: 5, sets: 3, minReps: 10, maxReps: 12, restSeconds: 60,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Tirón — Espalda y Bíceps',
      description:
          'Día de tirón: remos y jalones para espalda completa, '
          'con trabajo directo de bíceps.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0027', // barbell bent over row
          order: 0, sets: 4, minReps: 8, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_2330', // cable lat pulldown full range of motion
          order: 1, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0861', // cable seated row
          order: 2, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0095', // barbell shrug
          order: 3, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0031', // barbell curl
          order: 4, sets: 3, minReps: 10, maxReps: 12, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0313', // dumbbell hammer curl
          order: 5, sets: 3, minReps: 10, maxReps: 12, restSeconds: 60,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Pierna Completa',
      description:
          'Día de pierna: sentadilla y bisagra de cadera como base, '
          'máquinas para completar cuádriceps, femoral y pantorrilla.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0043', // barbell full squat
          order: 0, sets: 4, minReps: 6, maxReps: 10, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0085', // barbell romanian deadlift
          order: 1, sets: 3, minReps: 8, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0739', // sled 45° leg press
          order: 2, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0585', // lever leg extension
          order: 3, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0586', // lever lying leg curl
          order: 4, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0088', // barbell seated calf raise
          order: 5, sets: 4, minReps: 12, maxReps: 15, restSeconds: 45,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Glúteos y Femoral',
      description:
          'Enfocada en cadena posterior: puente de glúteo con barra, '
          'zancadas y peso muerto rumano.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_1409', // barbell glute bridge
          order: 0, sets: 4, minReps: 8, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0054', // barbell lunge
          order: 1, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1459', // dumbbell romanian deadlift
          order: 2, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0534', // kettlebell goblet squat
          order: 3, sets: 3, minReps: 10, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0586', // lever lying leg curl
          order: 4, sets: 3, minReps: 12, maxReps: 15, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3561', // glute bridge march
          order: 5, sets: 3, minReps: 12, maxReps: 15, restSeconds: 45,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Core y Acondicionamiento',
      description:
          'Circuito de core y cardio sin equipamiento: ideal para días '
          'de recuperación activa o como complemento.',
      difficulty: DifficultyLevel.beginner,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0001', // 3/4 sit-up
          order: 0, sets: 3, minReps: 12, maxReps: 15, restSeconds: 45,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0687', // russian twist
          order: 1, sets: 3, minReps: 15, maxReps: 20, restSeconds: 45,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0464', // front plank with twist
          order: 2, sets: 3, minReps: 10, maxReps: 12, restSeconds: 45,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0630', // mountain climber
          order: 3, sets: 3, minReps: 15, maxReps: 20, restSeconds: 45,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1160', // burpee
          order: 4, sets: 3, minReps: 8, maxReps: 10, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1761', // hanging oblique knee raise
          order: 5, sets: 3, minReps: 10, maxReps: 12, restSeconds: 60,
        ),
      ],
    ),

    // ═════════════════════════════════════════════════════════════════════
    // Programas de LogPress (github.com/hasaneyldrm/logpress-public, MIT)
    // — la app oficial del autor del dataset. Portados con sus sets/reps/
    // descansos originales; cada ejercicio mapeado a su equivalente ds_*.
    // ═════════════════════════════════════════════════════════════════════

    RoutineSeed(
      name: 'Fuerza de Inicio',
      description:
          'Programa LogPress para principiantes: máquinas y movimientos '
          'guiados de cuerpo completo, ideal como primera rutina de gym.',
      difficulty: DifficultyLevel.beginner,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0739', // sled 45° leg press
          order: 0, sets: 3, minReps: 12, maxReps: 12, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0577', // lever chest press
          order: 1, sets: 3, minReps: 10, maxReps: 10, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1350', // lever seated row
          order: 2, sets: 3, minReps: 10, maxReps: 10, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_2330', // cable lat pulldown full range of motion
          order: 3, sets: 3, minReps: 10, maxReps: 10, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3013', // low glute bridge on floor
          order: 4, sets: 3, minReps: 15, maxReps: 15, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0203', // cable rear delt row (rope) ≈ face pull
          order: 5, sets: 3, minReps: 12, maxReps: 12, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0178', // cable lateral raise
          order: 6, sets: 3, minReps: 12, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3666', // walking on incline treadmill
          order: 7, sets: 1, minReps: 10, maxReps: 10, restSeconds: 30,
          notes: 'Minutos de caminata inclinada',
        ),
        RoutineExerciseInput(
          templateId: 'ds_0586', // lever lying leg curl
          order: 8, sets: 3, minReps: 12, maxReps: 12, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0687', // russian twist
          order: 9, sets: 3, minReps: 20, maxReps: 20, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0597', // lever seated hip abduction
          order: 10, sets: 3, minReps: 15, maxReps: 15, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_2135', // weighted front plank
          order: 11, sets: 3, minReps: 30, maxReps: 30, restSeconds: 60,
          notes: 'Segundos de plancha',
        ),
      ],
    ),
    RoutineSeed(
      name: 'Destructor Cardio',
      description:
          'Programa LogPress de cardio intenso: pliometría y '
          'acondicionamiento metabólico de cuerpo completo.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_1160', // burpee
          order: 0, sets: 3, minReps: 10, maxReps: 10, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_2612', // jump rope
          order: 1, sets: 3, minReps: 100, maxReps: 100, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0630', // mountain climber
          order: 2, sets: 3, minReps: 20, maxReps: 20, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0514', // jump squat
          order: 3, sets: 3, minReps: 15, maxReps: 15, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3224', // jack jump ≈ jumping jack
          order: 4, sets: 3, minReps: 25, maxReps: 25, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1374', // box jump down with one leg stabilization
          order: 5, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3636', // high knee against wall
          order: 6, sets: 3, minReps: 30, maxReps: 30, restSeconds: 60,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3655', // walking high knees lunge ≈ jumping lunge
          order: 7, sets: 3, minReps: 12, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0684', // run (equipment)
          order: 8, sets: 1, minReps: 5, maxReps: 5, restSeconds: 120,
          notes: 'Kilómetros de carrera',
        ),
        RoutineExerciseInput(
          templateId: 'ds_2138', // stationary bike run
          order: 9, sets: 1, minReps: 10, maxReps: 10, restSeconds: 120,
          notes: 'Minutos de bicicleta',
        ),
        RoutineExerciseInput(
          templateId: 'ds_3433', // swimmer kicks ≈ natación
          order: 10, sets: 2, minReps: 20, maxReps: 20, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3666', // walking on incline treadmill
          order: 11, sets: 1, minReps: 15, maxReps: 15, restSeconds: 60,
          notes: 'Minutos de caminata inclinada',
        ),
      ],
    ),
    RoutineSeed(
      name: 'Maestro de Peso Corporal',
      description:
          'Programa LogPress avanzado sin equipamiento: calistenia completa '
          'desde push-ups hasta handstand push-ups.',
      difficulty: DifficultyLevel.advanced,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0662', // push-up
          order: 0, sets: 3, minReps: 12, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0652', // pull-up
          order: 1, sets: 3, minReps: 8, maxReps: 8, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3204', // arms overhead full sit-up
          order: 2, sets: 3, minReps: 15, maxReps: 15, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0464', // front plank with twist
          order: 3, sets: 3, minReps: 45, maxReps: 45, restSeconds: 60,
          notes: 'Segundos de plancha',
        ),
        RoutineExerciseInput(
          templateId: 'ds_0283', // diamond push-up
          order: 4, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1296', // pike push up
          order: 5, sets: 3, minReps: 8, maxReps: 8, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0471', // handstand push-up
          order: 6, sets: 3, minReps: 5, maxReps: 5, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1429', // wide grip pull-up
          order: 7, sets: 3, minReps: 6, maxReps: 6, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0687', // russian twist
          order: 8, sets: 3, minReps: 20, maxReps: 20, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0002', // 45° side bend
          order: 9, sets: 3, minReps: 15, maxReps: 15, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0279', // decline push-up
          order: 10, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0630', // mountain climber
          order: 11, sets: 3, minReps: 20, maxReps: 20, restSeconds: 90,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Fundamentos de Powerlifting',
      description:
          'Programa LogPress enfocado en los tres básicos: sentadilla, '
          'press de banca y peso muerto con sus variantes.',
      difficulty: DifficultyLevel.advanced,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0043', // barbell full squat
          order: 0, sets: 3, minReps: 5, maxReps: 5, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0025', // barbell bench press
          order: 1, sets: 3, minReps: 5, maxReps: 5, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0032', // barbell deadlift
          order: 2, sets: 3, minReps: 5, maxReps: 5, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0085', // barbell romanian deadlift
          order: 3, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0047', // barbell incline bench press
          order: 4, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0026', // barbell bench squat ≈ box squat
          order: 5, sets: 3, minReps: 6, maxReps: 6, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_3142', // smith sumo squat
          order: 6, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0030', // barbell close-grip bench press
          order: 7, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1461', // barbell full squat (back pov) ≈ pause squat
          order: 8, sets: 3, minReps: 5, maxReps: 5, restSeconds: 180,
          notes: 'Pausa de 2 seg abajo',
        ),
        RoutineExerciseInput(
          templateId: 'ds_1308', // smith wide grip bench press
          order: 9, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0537', // kettlebell one arm clean and jerk
          order: 10, sets: 3, minReps: 3, maxReps: 3, restSeconds: 180,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0091', // barbell seated overhead press
          order: 11, sets: 3, minReps: 8, maxReps: 8, restSeconds: 150,
        ),
      ],
    ),
    RoutineSeed(
      name: 'Dinamo de Mancuernas',
      description:
          'Programa LogPress de cuerpo completo usando solo mancuernas: '
          'perfecto para gyms con equipo limitado o entrenamiento en casa.',
      difficulty: DifficultyLevel.intermediate,
      exercises: [
        RoutineExerciseInput(
          templateId: 'ds_0413', // dumbbell squat
          order: 0, sets: 3, minReps: 12, maxReps: 12, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0289', // dumbbell bench press
          order: 1, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0300', // dumbbell deadlift
          order: 2, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0293', // dumbbell bent over row
          order: 3, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0405', // dumbbell seated shoulder press
          order: 4, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0294', // dumbbell biceps curl
          order: 5, sets: 3, minReps: 12, maxReps: 12, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0336', // dumbbell lunge
          order: 6, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0375', // dumbbell pullover
          order: 7, sets: 3, minReps: 12, maxReps: 12, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0314', // dumbbell incline bench press
          order: 8, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
        RoutineExerciseInput(
          templateId: 'ds_0407', // dumbbell side bend
          order: 9, sets: 3, minReps: 15, maxReps: 15, restSeconds: 90,
        ),
        RoutineExerciseInput(
          templateId: 'ds_1460', // walking lunge
          order: 10, sets: 3, minReps: 12, maxReps: 12, restSeconds: 120,
          notes: 'Con mancuernas en mano',
        ),
        RoutineExerciseInput(
          templateId: 'ds_0381', // dumbbell rear lunge ≈ curtsy lunge
          order: 11, sets: 3, minReps: 10, maxReps: 10, restSeconds: 120,
        ),
      ],
    ),
  ];
}
