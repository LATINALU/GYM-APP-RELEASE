import 'dataset_exercise_catalog.dart';

/// Resolución de media de ejercicios (shim de compatibilidad)
///
/// Históricamente mapeaba IDs a GIFs de musclewiki; hoy delega por completo
/// en [DatasetExerciseCatalog] (media uniforme de Gym visual con soporte
/// offline). Preferir [ExerciseGifView] en presentación.
class ExerciseGifs {
  ExerciseGifs._();

  /// Obtener GIF por ID de plantilla (`ds_XXXX`) o nombre del ejercicio
  static String? getGifUrl(String exerciseKey) {
    return DatasetExerciseCatalog.gifUrl(exerciseKey);
  }

  /// Obtener thumbnail remoto (180x180 JPG)
  static String? getImageUrl(String exerciseKey) {
    return DatasetExerciseCatalog.imageUrl(exerciseKey);
  }

  /// Thumbnail empaquetado en assets (disponible sin internet)
  static String? getThumbAsset(String exerciseKey) {
    return DatasetExerciseCatalog.thumbAssetPath(exerciseKey);
  }

  /// Placeholder para ejercicios sin media
  static const String placeholder =
      'https://via.placeholder.com/300x200/374151/9CA3AF?text=Ejercicio';
}
