import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/src/application/use_cases/maintain_routines_usecase.dart';
import 'package:gym_app/src/application/use_cases/manage_routine_usecase.dart';
import 'package:gym_app/src/domain/data/dataset_exercise_catalog.dart';
import 'package:gym_app/src/domain/data/routine_seeds.dart';
import 'package:gym_app/src/domain/entities/entities.dart';
import 'package:gym_app/src/domain/ports/output/output_ports.dart';
import 'package:gym_app/src/domain/value_objects/value_objects.dart';
import 'package:gym_app/src/infrastructure/adapters/local/in_memory_routine_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRepository extends Mock implements UserRepositoryPort {}

void main() {
  late _MockUserRepository userRepo;
  late InMemoryRoutineRepository routineRepo;
  late ManageRoutineUseCase manageRoutines;

  final ownerId = UserId.generate();
  final owner = User.restore(
    id: ownerId,
    email: Email('owner@gym.com'),
    name: PersonName(firstName: 'Owner', lastName: 'Test'),
    role: const GymRole.owner(),
    gymId: const GymId('gym-1'),
    createdAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(UserId.generate());
    final json =
        File('assets/data/exercises_dataset.json').readAsStringSync();
    DatasetExerciseCatalog.loadFromJsonString(json);
  });

  setUp(() {
    userRepo = _MockUserRepository();
    routineRepo = InMemoryRoutineRepository();
    manageRoutines = ManageRoutineUseCase(
      userRepository: userRepo,
      routineRepository: routineRepo,
    );
    when(() => userRepo.findByIdGlobal(any()))
        .thenAnswer((_) async => right(owner));
  });

  group('RoutineSeeds — integridad', () {
    test('todos los templateId de las semillas existen en el catálogo', () {
      for (final seed in RoutineSeeds.all) {
        expect(seed.exercises, isNotEmpty, reason: seed.name);
        for (final input in seed.exercises) {
          final template =
              DatasetExerciseCatalog.exercises.where((e) => e.id == input.templateId);
          expect(template, isNotEmpty,
              reason: '${seed.name}: templateId ${input.templateId} no existe');
        }
      }
    });

    test('las semillas no tienen nombres duplicados ni ejercicios repetidos', () {
      final names = RoutineSeeds.all.map((s) => s.name.toLowerCase()).toList();
      expect(names.toSet().length, names.length);
      for (final seed in RoutineSeeds.all) {
        final orders = seed.exercises.map((e) => e.order).toList();
        expect(orders.toSet().length, orders.length,
            reason: '${seed.name}: orden duplicado');
      }
    });
  });

  group('SeedRoutinesUseCase', () {
    test('crea las rutinas predefinidas con ejercicios del dataset', () async {
      final useCase = SeedRoutinesUseCase(manageRoutines: manageRoutines);

      final result = await useCase.execute(ownerId);

      expect(result.isRight(), isTrue);
      final maintenance = result.getOrElse(() => throw Exception());
      expect(maintenance.affected, RoutineSeeds.all.length);

      final routines =
          (await routineRepo.findAllActive()).getOrElse(() => []);
      expect(routines.length, RoutineSeeds.all.length);
      // Cada ejercicio sembrado trae media del dataset (GIF persistible)
      for (final routine in routines) {
        expect(routine.exercises, isNotEmpty);
        for (final exercise in routine.exercises) {
          expect(exercise.animationUrl, contains('raw.githubusercontent'),
              reason: '${exercise.name} debería traer GIF del dataset');
          expect(exercise.instructions, isNotNull);
        }
      }
    });

    test('es idempotente: no duplica rutinas existentes', () async {
      final useCase = SeedRoutinesUseCase(manageRoutines: manageRoutines);
      await useCase.execute(ownerId);

      final second = await useCase.execute(ownerId);

      expect(second.isRight(), isTrue);
      expect(second.getOrElse(() => throw Exception()).affected, 0);
      final routines =
          (await routineRepo.findAllActive()).getOrElse(() => []);
      expect(routines.length, RoutineSeeds.all.length);
    });

    test('rechaza usuarios sin permisos de rutinas', () async {
      final client = User.restore(
        id: UserId.generate(),
        email: Email('client@gym.com'),
        name: PersonName(firstName: 'Client', lastName: 'Test'),
        role: const GymRole.client(),
        gymId: const GymId('gym-1'),
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => userRepo.findByIdGlobal(any()))
          .thenAnswer((_) async => right(client));

      final useCase = SeedRoutinesUseCase(manageRoutines: manageRoutines);
      final result = await useCase.execute(client.id);

      // ManageRoutineUseCase valida permisos en cada createRoutine
      expect(result.isLeft(), isTrue);
      final routines =
          (await routineRepo.findAllActive()).getOrElse(() => []);
      expect(routines, isEmpty);
    });
  });
}
