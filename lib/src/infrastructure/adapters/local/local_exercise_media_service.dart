import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/ports/output/exercise_media_port.dart';

/// Adaptador local de media de ejercicios
///
/// Persiste los GIFs en el directorio de soporte de la app
/// (`<appSupport>/exercise_media/`), fuera del caché del sistema, para que
/// no sean purgados y las rutinas funcionen sin internet dentro del gym.
class LocalExerciseMediaService implements ExerciseMediaPort {
  LocalExerciseMediaService({
    http.Client? client,
    Logger? logger,
    Future<Directory> Function()? baseDirectory,
  })  : _client = client ?? http.Client(),
        _logger = logger ?? Logger(),
        _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  final http.Client _client;
  final Logger _logger;
  final Future<Directory> Function() _baseDirectory;

  Directory? _mediaDir;
  final Map<String, Future<String?>> _inFlight = {};

  Future<Directory> _dir() async {
    if (_mediaDir != null) return _mediaDir!;
    final support = await _baseDirectory();
    final dir = Directory('${support.path}${Platform.pathSeparator}exercise_media');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _mediaDir = dir;
    return dir;
  }

  String _fileNameFor(String remoteUrl) => remoteUrl.split('/').last;

  @override
  Future<String?> localPath(String remoteUrl) async {
    final dir = await _dir();
    final file = File('${dir.path}${Platform.pathSeparator}${_fileNameFor(remoteUrl)}');
    return await file.exists() ? file.path : null;
  }

  @override
  Future<String?> ensureDownloaded(String remoteUrl) {
    // Evitar descargas duplicadas concurrentes del mismo archivo
    return _inFlight.putIfAbsent(remoteUrl, () async {
      try {
        final existing = await localPath(remoteUrl);
        if (existing != null) return existing;

        final response = await _client
            .get(Uri.parse(remoteUrl))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          return null;
        }

        final dir = await _dir();
        final target =
            File('${dir.path}${Platform.pathSeparator}${_fileNameFor(remoteUrl)}');
        // Escribir a temporal + rename: nunca dejar archivos corruptos a medias
        final tmp = File('${target.path}.part');
        await tmp.writeAsBytes(response.bodyBytes, flush: true);
        await tmp.rename(target.path);
        return target.path;
      } catch (e) {
        _logger.d('Media no descargada (se reintentará): $remoteUrl — $e');
        return null;
      } finally {
        _inFlight.remove(remoteUrl);
      }
    });
  }

  @override
  Future<void> prefetch(Iterable<String> remoteUrls) async {
    // Descarga secuencial en lotes pequeños para no saturar la red del gym
    final urls = remoteUrls.toSet().toList();
    const batchSize = 4;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      await Future.wait(batch.map(ensureDownloaded));
    }
  }

  @override
  Stream<double> downloadFullLibrary(Iterable<String> remoteUrls) async* {
    final urls = remoteUrls.toSet().toList();
    if (urls.isEmpty) {
      yield 1.0;
      return;
    }
    var done = 0;
    const batchSize = 6;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize).toList();
      await Future.wait(batch.map(ensureDownloaded));
      done += batch.length;
      yield done / urls.length;
    }
  }

  @override
  Future<int> downloadedCount() async {
    final dir = await _dir();
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && !entity.path.endsWith('.part')) count++;
    }
    return count;
  }
}
