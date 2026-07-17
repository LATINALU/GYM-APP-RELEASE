import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/infrastructure/adapters/local/local_exercise_media_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late Directory tempDir;
  late _MockHttpClient client;
  late LocalExerciseMediaService service;

  const url =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0001-abc.gif';

  setUpAll(() {
    registerFallbackValue(Uri.parse(url));
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('media_test');
    client = _MockHttpClient();
    service = LocalExerciseMediaService(
      client: client,
      baseDirectory: () async => tempDir,
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('LocalExerciseMediaService', () {
    test('descarga y persiste un GIF; después lo sirve desde disco', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response.bytes([1, 2, 3, 4], 200),
      );

      expect(await service.localPath(url), isNull);

      final path = await service.ensureDownloaded(url);
      expect(path, isNotNull);
      expect(File(path!).readAsBytesSync(), [1, 2, 3, 4]);
      expect(path, endsWith('0001-abc.gif'));

      // Segunda llamada: no vuelve a bajar, resuelve local
      final again = await service.ensureDownloaded(url);
      expect(again, path);
      verify(() => client.get(any())).called(1);

      expect(await service.localPath(url), path);
      expect(await service.downloadedCount(), 1);
    });

    test('devuelve null sin conexión y no deja archivos corruptos', () async {
      when(() => client.get(any()))
          .thenThrow(const SocketException('sin red'));

      final path = await service.ensureDownloaded(url);
      expect(path, isNull);
      expect(await service.downloadedCount(), 0);

      // Al volver la red, reintenta con éxito
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response.bytes([9, 9], 200),
      );
      expect(await service.ensureDownloaded(url), isNotNull);
    });

    test('respuestas no-200 no se persisten', () async {
      when(() => client.get(any()))
          .thenAnswer((_) async => http.Response('not found', 404));
      expect(await service.ensureDownloaded(url), isNull);
      expect(await service.downloadedCount(), 0);
    });

    test('prefetch descarga varios GIFs ignorando fallos individuales', () async {
      const urlOk = 'https://example.com/videos/a.gif';
      const urlFail = 'https://example.com/videos/b.gif';
      when(() => client.get(Uri.parse(urlOk))).thenAnswer(
        (_) async => http.Response.bytes([1], 200),
      );
      when(() => client.get(Uri.parse(urlFail)))
          .thenThrow(const SocketException('sin red'));

      await service.prefetch([urlOk, urlFail, urlOk]);
      expect(await service.downloadedCount(), 1);
    });

    test('downloadFullLibrary emite progreso hasta 1.0', () async {
      final urls = List.generate(10, (i) => 'https://example.com/v/$i.gif');
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response.bytes([0], 200),
      );

      final progress = await service.downloadFullLibrary(urls).toList();
      expect(progress.last, 1.0);
      expect(progress, isNotEmpty);
      expect(await service.downloadedCount(), 10);
    });
  });
}
