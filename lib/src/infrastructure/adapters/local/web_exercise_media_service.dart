import '../../../domain/ports/output/exercise_media_port.dart';

/// Implementación web del puerto de media: no hay descarga a disco
/// (dart:io no existe en web). Los GIFs se muestran por red con el caché
/// del navegador; los thumbnails siguen viniendo de assets.
class WebExerciseMediaService implements ExerciseMediaPort {
  @override
  Future<String?> localPath(String remoteUrl) async => null;

  @override
  Future<String?> ensureDownloaded(String remoteUrl) async => null;

  @override
  Future<void> prefetch(Iterable<String> remoteUrls) async {}

  @override
  Stream<double> downloadFullLibrary(Iterable<String> remoteUrls) =>
      Stream<double>.value(1.0);

  @override
  Future<int> downloadedCount() async => 0;
}
