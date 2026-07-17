import 'dart:convert';

import '../entities/exercise.dart';

/// Catálogo de ejercicios del dataset open-source
/// https://github.com/hasaneyldrm/exercises-dataset (MIT; media © Gym visual)
///
/// Se carga desde el asset `assets/data/exercises_dataset.json` (1,324
/// ejercicios con instrucciones en español) y se fusiona con el catálogo
/// estático a través de [ExerciseCatalog]. Los GIFs y thumbnails se sirven
/// desde GitHub raw y se cachean con cached_network_image.
class DatasetExerciseCatalog {
  DatasetExerciseCatalog._();

  static const String attribution = '© Gym visual — https://gymvisual.com/';
  static const String _mediaBaseUrl =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main';

  /// Prefijo de IDs para distinguirlos del catálogo estático
  static const String idPrefix = 'ds_';

  static List<ExerciseTemplate> _exercises = const [];
  static Map<String, String> _mediaById = const {};
  static Map<String, String> _idByName = const {};

  /// Se incrementa en cada carga; [ExerciseCatalog] lo usa para invalidar su caché
  static int version = 0;

  static List<ExerciseTemplate> get exercises => _exercises;
  static bool get isLoaded => _exercises.isNotEmpty;
  static int get count => _exercises.length;

  /// Parsear el JSON del asset y poblar el catálogo
  static void loadFromJsonString(String jsonString) {
    final raw = jsonDecode(jsonString) as List<dynamic>;
    final exercises = <ExerciseTemplate>[];
    final mediaById = <String, String>{};
    final idByName = <String, String>{};

    for (final item in raw) {
      final map = item as Map<String, dynamic>;
      final id = '$idPrefix${map['id']}';
      final name = map['n'] as String;
      final target = map['t'] as String;
      final equipment = map['e'] as String;
      final secondary = (map['s'] as List<dynamic>? ?? const []).cast<String>();
      final steps = (map['i'] as List<dynamic>? ?? const []).cast<String>();
      final media = map['m'] as String?;

      final pattern = _inferPattern(name, target);
      final primaryMuscle = _targetToMuscle(target);
      final secondaryMuscles = secondary
          .map(_secondaryToMuscle)
          .whereType<MuscleGroup>()
          .where((m) => m != primaryMuscle)
          .toSet()
          .toList();
      final equipmentType = _equipmentToType(equipment);

      exercises.add(ExerciseTemplate(
        id: id,
        name: name,
        spanishName: '',
        description: steps.isNotEmpty ? steps.first : name,
        movementPattern: pattern,
        exerciseType: _inferType(target, pattern, secondaryMuscles.length),
        difficulty: equipmentType == EquipmentType.bodyweight
            ? ExerciseDifficulty.beginner
            : ExerciseDifficulty.intermediate,
        primaryMuscle: primaryMuscle,
        secondaryMuscles: secondaryMuscles,
        equipment: [equipmentType],
        tips: steps,
        gifUrl: media != null ? '$_mediaBaseUrl/videos/$media.gif' : null,
        imageUrl: media != null ? '$_mediaBaseUrl/images/$media.jpg' : null,
        thumbAsset: media != null ? 'assets/exercise_images/$media.jpg' : null,
      ));

      if (media != null) {
        mediaById[id] = media;
        idByName[name.toLowerCase()] = id;
      }
    }

    _exercises = List.unmodifiable(exercises);
    _mediaById = mediaById;
    _idByName = idByName;
    version++;
  }

  /// URL del GIF animado. Acepta ID de plantilla (`ds_0001`) o nombre del ejercicio.
  static String? gifUrl(String key) {
    final media = _mediaFor(key);
    return media != null ? '$_mediaBaseUrl/videos/$media.gif' : null;
  }

  /// URL del thumbnail estático (180x180 JPG)
  static String? imageUrl(String key) {
    final media = _mediaFor(key);
    return media != null ? '$_mediaBaseUrl/images/$media.jpg' : null;
  }

  /// Ruta del thumbnail empaquetado en assets (disponible sin internet)
  static String? thumbAssetPath(String key) {
    final media = _mediaFor(key);
    return media != null ? 'assets/exercise_images/$media.jpg' : null;
  }

  /// Ruta de asset del thumbnail a partir de una URL remota de media
  /// (GIF o JPG del dataset). Útil como fallback offline.
  static String? thumbAssetForRemoteUrl(String remoteUrl) {
    if (!remoteUrl.startsWith(_mediaBaseUrl)) return null;
    final stem = remoteUrl.split('/').last.split('.').first;
    return 'assets/exercise_images/$stem.jpg';
  }

  static String? _mediaFor(String key) {
    final byId = _mediaById[key];
    if (byId != null) return byId;
    final id = _idByName[key.toLowerCase()];
    return id != null ? _mediaById[id] : null;
  }

  /// ID de plantilla (`ds_XXXX`) a partir del nombre exacto del ejercicio.
  /// Útil para resolver ejercicios persistidos que solo guardan el nombre.
  static String? templateIdForName(String name) => _idByName[name.toLowerCase()];

  // === Mapeos dataset -> enums de la app ===

  static MuscleGroup _targetToMuscle(String target) {
    switch (target) {
      case 'abductors': return MuscleGroup.abductors;
      case 'abs': return MuscleGroup.abs;
      case 'adductors': return MuscleGroup.adductors;
      case 'biceps': return MuscleGroup.biceps;
      case 'calves': return MuscleGroup.calves;
      case 'cardiovascular system': return MuscleGroup.cardio;
      case 'delts': return MuscleGroup.shoulders;
      case 'forearms': return MuscleGroup.forearms;
      case 'glutes': return MuscleGroup.glutes;
      case 'hamstrings': return MuscleGroup.hamstrings;
      case 'lats': return MuscleGroup.lats;
      case 'levator scapulae': return MuscleGroup.traps;
      case 'pectorals': return MuscleGroup.chest;
      case 'quads': return MuscleGroup.quadriceps;
      case 'serratus anterior': return MuscleGroup.chest;
      case 'spine': return MuscleGroup.lowerBack;
      case 'traps': return MuscleGroup.traps;
      case 'triceps': return MuscleGroup.triceps;
      case 'upper back': return MuscleGroup.upperBack;
      default: return MuscleGroup.fullBody;
    }
  }

  static MuscleGroup? _secondaryToMuscle(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('rear delt')) return MuscleGroup.rearDelts;
    if (m.contains('delt') || m.contains('shoulder') || m.contains('rotator')) {
      return MuscleGroup.shoulders;
    }
    if (m.contains('oblique')) return MuscleGroup.obliques;
    if (m.contains('hip flexor')) return MuscleGroup.hipFlexors;
    if (m.contains('lower back')) return MuscleGroup.lowerBack;
    if (m.contains('upper back')) return MuscleGroup.upperBack;
    if (m.contains('rhomboid')) return MuscleGroup.rhomboids;
    if (m.contains('trap') || m.contains('sternocleido') || m.contains('levator')) {
      return MuscleGroup.traps;
    }
    if (m.contains('latissimus') || m == 'lats') return MuscleGroup.lats;
    if (m.contains('chest') || m.contains('pector') || m.contains('serratus')) {
      return MuscleGroup.chest;
    }
    if (m.contains('quad')) return MuscleGroup.quadriceps;
    if (m.contains('hamstring')) return MuscleGroup.hamstrings;
    if (m.contains('glute')) return MuscleGroup.glutes;
    if (m.contains('calv') || m.contains('soleus') || m.contains('shin') ||
        m.contains('ankle') || m.contains('feet')) {
      return MuscleGroup.calves;
    }
    if (m.contains('bicep') || m.contains('brachialis')) return MuscleGroup.biceps;
    if (m.contains('tricep')) return MuscleGroup.triceps;
    if (m.contains('forearm') || m.contains('wrist') || m.contains('grip') ||
        m.contains('hand')) {
      return MuscleGroup.forearms;
    }
    if (m.contains('abdominal') || m.contains('abs') || m == 'core') {
      return MuscleGroup.abs;
    }
    if (m.contains('adductor') || m.contains('groin') || m.contains('inner thigh')) {
      return MuscleGroup.adductors;
    }
    if (m.contains('abductor')) return MuscleGroup.abductors;
    if (m == 'back') return MuscleGroup.back;
    return null;
  }

  static EquipmentType _equipmentToType(String equipment) {
    switch (equipment) {
      case 'barbell':
      case 'olympic barbell': return EquipmentType.barbell;
      case 'dumbbell': return EquipmentType.dumbbell;
      case 'kettlebell': return EquipmentType.kettlebell;
      case 'cable': return EquipmentType.cable;
      case 'ez barbell': return EquipmentType.ezBar;
      case 'trap bar': return EquipmentType.trapBar;
      case 'smith machine': return EquipmentType.smithMachine;
      case 'band':
      case 'resistance band': return EquipmentType.resistanceBand;
      case 'medicine ball':
      case 'stability ball': return EquipmentType.medicineBall;
      case 'assisted':
      case 'leverage machine':
      case 'sled machine':
      case 'elliptical machine':
      case 'skierg machine':
      case 'stationary bike':
      case 'stepmill machine':
      case 'upper body ergometer':
      case 'hammer': return EquipmentType.machine;
      case 'tire': return EquipmentType.box;
      default: return EquipmentType.bodyweight;
    }
  }

  static MovementPattern _inferPattern(String name, String target) {
    final n = name.toLowerCase();
    if (n.contains('squat')) return MovementPattern.squat;
    if (n.contains('lunge') || n.contains('step-up') || n.contains('step up')) {
      return MovementPattern.lunge;
    }
    if (n.contains('deadlift') || n.contains('good morning') ||
        n.contains('swing') || n.contains('clean') || n.contains('snatch')) {
      return MovementPattern.hipHinge;
    }
    if (n.contains('hip thrust') || n.contains('bridge') ||
        (n.contains('kickback') && target == 'glutes')) {
      return MovementPattern.hipExtension;
    }
    if (n.contains('leg curl') || n.contains('leg extension')) {
      return MovementPattern.kneeFlexion;
    }
    if (n.contains('pull-up') || n.contains('pull up') || n.contains('chin') ||
        n.contains('pulldown') || n.contains('pull-down')) {
      return MovementPattern.verticalPull;
    }
    if (n.contains('row') || n.contains('face pull')) {
      return MovementPattern.horizontalPull;
    }
    if (n.contains('overhead press') || n.contains('shoulder press') ||
        n.contains('military press') || n.contains('arnold') ||
        n.contains('handstand') || n.contains('pike push')) {
      return MovementPattern.verticalPush;
    }
    if (n.contains('bench press') || n.contains('push-up') ||
        n.contains('push up') || n.contains('chest press') || n.contains('dip')) {
      return MovementPattern.horizontalPush;
    }
    if (n.contains('press') && target == 'delts') return MovementPattern.verticalPush;
    if (n.contains('press') && target == 'pectorals') return MovementPattern.horizontalPush;
    if (n.contains('plank') || n.contains('hold')) return MovementPattern.coreStability;
    if (n.contains('crunch') || n.contains('sit-up') || n.contains('sit up') ||
        n.contains('leg raise') || n.contains('knee raise') || n.contains('v-up')) {
      return MovementPattern.coreFlexion;
    }
    if (n.contains('twist') || n.contains('rotation') || n.contains('wood chop') ||
        n.contains('woodchop')) {
      return MovementPattern.coreRotation;
    }
    if (n.contains('carry') || n.contains('farmer') || n.contains('walk')) {
      return MovementPattern.carry;
    }
    if (n.contains('jump') || n.contains('hop') || n.contains('burpee') ||
        n.contains('plyo')) {
      return MovementPattern.plyometric;
    }
    return MovementPattern.isolation;
  }

  static ExerciseType _inferType(
      String target, MovementPattern pattern, int secondaryCount) {
    if (target == 'cardiovascular system') return ExerciseType.cardio;
    if (pattern == MovementPattern.coreStability) return ExerciseType.isometric;
    if (pattern == MovementPattern.plyometric) return ExerciseType.plyometric;
    const compoundPatterns = {
      MovementPattern.squat,
      MovementPattern.hipHinge,
      MovementPattern.lunge,
      MovementPattern.hipExtension,
      MovementPattern.verticalPush,
      MovementPattern.horizontalPush,
      MovementPattern.verticalPull,
      MovementPattern.horizontalPull,
      MovementPattern.carry,
    };
    if (compoundPatterns.contains(pattern)) return ExerciseType.compound;
    return secondaryCount >= 2 ? ExerciseType.compound : ExerciseType.isolation;
  }
}
