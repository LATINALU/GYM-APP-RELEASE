/// Puerto de salida: media de ejercicios disponible sin conexión
///
/// Los GIFs del dataset (~127 MB en total) no se empaquetan en el APK;
/// se descargan a almacenamiento permanente de la app cuando hay red y a
/// partir de ahí se sirven desde disco. Los thumbnails sí van empaquetados
/// en assets, por lo que la biblioteca siempre es navegable offline.
abstract class ExerciseMediaPort {
  /// Ruta local del archivo si ya fue descargado; null si no existe aún
  Future<String?> localPath(String remoteUrl);

  /// Descargar y persistir el archivo (idempotente). Devuelve la ruta local
  /// o null si no hay conexión / falló la descarga (se reintentará después).
  Future<String?> ensureDownloaded(String remoteUrl);

  /// Prefetch en lote — p. ej. los GIFs de las rutinas asignadas al cliente,
  /// para garantizar que pueda revisarlas sin internet dentro del gym.
  /// Silencioso: ignora errores individuales.
  Future<void> prefetch(Iterable<String> remoteUrls);

  /// Descargar la biblioteca completa de GIFs (~127 MB).
  /// Emite el progreso como fracción 0.0–1.0.
  Stream<double> downloadFullLibrary(Iterable<String> remoteUrls);

  /// Cantidad de archivos ya descargados localmente
  Future<int> downloadedCount();
}
