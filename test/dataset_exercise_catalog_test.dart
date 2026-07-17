import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/domain/data/dataset_exercise_catalog.dart';
import 'package:gym_app/src/domain/data/exercise_catalog.dart';
import 'package:gym_app/src/domain/data/exercise_gifs.dart';
import 'package:gym_app/src/domain/entities/exercise.dart';

void main() {
  setUpAll(() {
    final json =
        File('assets/data/exercises_dataset.json').readAsStringSync();
    DatasetExerciseCatalog.loadFromJsonString(json);
  });

  group('DatasetExerciseCatalog', () {
    test('carga los 1,324 ejercicios del dataset', () {
      expect(DatasetExerciseCatalog.count, 1324);
      expect(DatasetExerciseCatalog.isLoaded, isTrue);
    });

    test('los ejercicios tienen instrucciones en español y músculo mapeado', () {
      final first = DatasetExerciseCatalog.exercises.first;
      expect(first.id, startsWith(DatasetExerciseCatalog.idPrefix));
      expect(first.tips, isNotEmpty);
      expect(first.description, isNotEmpty);
      // Ningún ejercicio debe quedar sin grupo muscular conocido
      final unmapped = DatasetExerciseCatalog.exercises
          .where((e) => e.primaryMuscle == MuscleGroup.fullBody)
          .length;
      expect(unmapped, 0);
    });

    test('resuelve URLs de GIF y thumbnail por ID y por nombre', () {
      final first = DatasetExerciseCatalog.exercises.first;
      final gifById = DatasetExerciseCatalog.gifUrl(first.id);
      expect(gifById, isNotNull);
      expect(gifById, contains('raw.githubusercontent.com'));
      expect(gifById, endsWith('.gif'));

      final imageById = DatasetExerciseCatalog.imageUrl(first.id);
      expect(imageById, endsWith('.jpg'));

      final gifByName = DatasetExerciseCatalog.gifUrl(first.name);
      expect(gifByName, gifById);
    });

    test('ExerciseCatalog muestra solo el dataset (diseño uniforme)', () {
      expect(ExerciseCatalog.count, 1324);
      expect(
        ExerciseCatalog.all.every((e) => e.id.startsWith(DatasetExerciseCatalog.idPrefix)),
        isTrue,
      );
      final first = DatasetExerciseCatalog.exercises.first;
      expect(ExerciseCatalog.byId(first.id), isNotNull);
      // byId también resuelve por nombre exacto (ejercicios persistidos)
      expect(ExerciseCatalog.byId(first.name)?.id, first.id);
      // Los IDs del catálogo legacy ya no existen
      expect(ExerciseCatalog.byId('bench_press_barbell'), isNull);
    });

    test('las plantillas del dataset traen media (GIF, imagen y thumbnail)', () {
      final withMedia = DatasetExerciseCatalog.exercises
          .where((e) => e.gifUrl != null && e.imageUrl != null && e.thumbAsset != null)
          .length;
      expect(withMedia, 1324);
      final first = DatasetExerciseCatalog.exercises.first;
      expect(first.thumbAsset, startsWith('assets/exercise_images/'));
    });

    test('Exercise.createFromTemplate propaga media e instrucciones', () {
      final template = DatasetExerciseCatalog.exercises.first;
      final exercise = Exercise.createFromTemplate(template: template);
      expect(exercise.animationUrl, template.gifUrl);
      expect(exercise.imageUrl, template.imageUrl);
      expect(exercise.instructions, isNotNull);
      expect(exercise.primaryMuscle, template.primaryMuscle);
    });

    test('ExerciseGifs delega en el dataset', () {
      final dsId = DatasetExerciseCatalog.exercises.first.id;
      expect(ExerciseGifs.getGifUrl(dsId), contains('raw.githubusercontent'));
      expect(ExerciseGifs.getThumbAsset(dsId),
          startsWith('assets/exercise_images/'));
      expect(ExerciseGifs.getGifUrl('bench_press_barbell'), isNull);
    });

    test('la búsqueda del catálogo encuentra ejercicios del dataset', () {
      final results = ExerciseCatalog.search('sit-up');
      expect(results.any((e) => e.id.startsWith(DatasetExerciseCatalog.idPrefix)),
          isTrue);
    });
  });
}
