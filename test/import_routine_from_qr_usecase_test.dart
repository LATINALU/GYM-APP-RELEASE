import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/errors/failures.dart';
import 'package:gym_app/src/application/use_cases/client/import_routine_from_qr_usecase.dart';
import 'package:gym_app/src/domain/entities/entities.dart';
import 'package:gym_app/src/domain/ports/output/output_ports.dart';
import 'package:gym_app/src/domain/value_objects/value_objects.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRepository extends Mock implements UserRepositoryPort {}

class _MockRoutineRepository extends Mock implements RoutineRepositoryPort {}

class _MockAssignmentRepository extends Mock
    implements AssignmentRepositoryPort {}

class _FakeRoutineAssignment extends Fake implements RoutineAssignment {}

void main() {
  late _MockUserRepository userRepo;
  late _MockRoutineRepository routineRepo;
  late _MockAssignmentRepository assignmentRepo;
  late ImportRoutineFromQrUseCase useCase;

  final clientId = UserId.generate();
  final client = User.restore(
    id: clientId,
    email: Email('cliente@gym.com'),
    name: PersonName(firstName: 'Cliente', lastName: 'Test'),
    role: const GymRole.client(),
    gymId: const GymId('gym-1'),
    createdAt: DateTime(2026, 1, 1),
  );

  final routineId = RoutineId('rt-1');
  final routine = WorkoutRoutine.restore(
    id: routineId,
    name: 'Push Day',
    difficulty: DifficultyLevel.intermediate,
    exercises: const [],
    estimatedDurationMinutes: 60,
    createdBy: UserId.generate(),
    createdAt: DateTime(2026, 1, 1),
  );

  String buildPayload({
    String type = 'routine_import',
    String routineId = 'rt-1',
    String gymId = 'gym-1',
    String name = 'Push Day',
    DateTime? expiresAt,
  }) {
    return jsonEncode({
      'type': type,
      'routineId': routineId,
      'gymId': gymId,
      'name': name,
      'difficulty': 'Intermedio',
      'exercises': [
        {
          'exerciseId': 'e1',
          'exerciseName': 'Press de Banca',
          'sets': 4,
          'reps': '8-10',
        },
      ],
      'estimatedDuration': 60,
      'expiresAt': (expiresAt ??
              DateTime.now().add(const Duration(minutes: 10)))
          .toIso8601String(),
    });
  }

  setUpAll(() {
    registerFallbackValue(UserId.generate());
    registerFallbackValue(RoutineId('fallback'));
    registerFallbackValue(_FakeRoutineAssignment());
  });

  setUp(() {
    userRepo = _MockUserRepository();
    routineRepo = _MockRoutineRepository();
    assignmentRepo = _MockAssignmentRepository();
    useCase = ImportRoutineFromQrUseCase(
      userRepository: userRepo,
      routineRepository: routineRepo,
      assignmentRepository: assignmentRepo,
    );

    when(() => userRepo.findByIdGlobal(any()))
        .thenAnswer((_) async => right(client));
    when(() => routineRepo.findById(any()))
        .thenAnswer((_) async => right(routine));
    when(() => assignmentRepo.hasActiveAssignment(any(), any()))
        .thenAnswer((_) async => false);
    when(() => assignmentRepo.save(any()))
        .thenAnswer((_) async => const Right(null));
  });

  group('parsePayload', () {
    test('rechaza contenido que no es JSON', () {
      final result = ImportRoutineFromQrUseCase.parsePayload('QUANTUM_abc123');
      expect(result.isLeft(), isTrue);
    });

    test('rechaza QR de otro tipo (pase de acceso)', () {
      final result = ImportRoutineFromQrUseCase.parsePayload(
        jsonEncode({'type': 'access_pass', 'userId': 'u1'}),
      );
      expect(result.isLeft(), isTrue);
    });

    test('rechaza QR expirado', () {
      final result = ImportRoutineFromQrUseCase.parsePayload(
        buildPayload(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      result.fold(
        (f) => expect(f.message, contains('expiró')),
        (_) => fail('debería rechazar el QR expirado'),
      );
    });

    test('acepta payload válido y expone el preview', () {
      final result = ImportRoutineFromQrUseCase.parsePayload(buildPayload());
      result.fold(
        (f) => fail('debería aceptar el payload: ${f.message}'),
        (preview) {
          expect(preview.routineId, 'rt-1');
          expect(preview.gymId, 'gym-1');
          expect(preview.name, 'Push Day');
          expect(preview.exercises, hasLength(1));
          expect(preview.isExpired, isFalse);
        },
      );
    });
  });

  group('execute', () {
    test('rechaza rutina de otro gimnasio', () async {
      final result = await useCase.execute(
        rawPayload: buildPayload(gymId: 'gym-otro'),
        clientId: clientId,
      );
      result.fold(
        (f) => expect(f.message, contains('otro gimnasio')),
        (_) => fail('debería rechazar rutina de otro gym'),
      );
      verifyNever(() => assignmentRepo.save(any()));
    });

    test('rechaza rutina que ya no existe', () async {
      when(() => routineRepo.findById(any())).thenAnswer(
        (_) async => left(const ServerFailure(message: 'not found')),
      );
      final result = await useCase.execute(
        rawPayload: buildPayload(),
        clientId: clientId,
      );
      result.fold(
        (f) => expect(f.message, contains('ya no está disponible')),
        (_) => fail('debería rechazar rutina inexistente'),
      );
    });

    test('rechaza si el cliente ya tiene la rutina asignada', () async {
      when(() => assignmentRepo.hasActiveAssignment(any(), any()))
          .thenAnswer((_) async => true);
      final result = await useCase.execute(
        rawPayload: buildPayload(),
        clientId: clientId,
      );
      result.fold(
        (f) => expect(f.message, contains('Ya tienes')),
        (_) => fail('debería rechazar el duplicado'),
      );
      verifyNever(() => assignmentRepo.save(any()));
    });

    test('happy path: crea auto-asignación activa y la guarda', () async {
      final result = await useCase.execute(
        rawPayload: buildPayload(),
        clientId: clientId,
      );

      result.fold(
        (f) => fail('debería importar: ${f.message}'),
        (imported) {
          expect(imported.message, contains('Push Day'));
          expect(imported.assignment.clientId, clientId);
          expect(imported.assignment.assignedById, clientId);
          expect(imported.assignment.isActive, isTrue);
          expect(imported.assignment.routineId, routineId);
        },
      );

      final captured =
          verify(() => assignmentRepo.save(captureAny())).captured;
      expect(captured, hasLength(1));
    });
  });

  group('RoutineAssignment.create — auto-asignación', () {
    test('un cliente puede asignarse una rutina a sí mismo', () {
      final assignment = RoutineAssignment.create(
        routineId: routineId,
        clientId: clientId,
        assignedBy: client,
      );
      expect(assignment.assignedById, clientId);
      expect(assignment.isActive, isTrue);
    });

    test('un cliente NO puede asignar rutinas a otro usuario', () {
      expect(
        () => RoutineAssignment.create(
          routineId: routineId,
          clientId: UserId.generate(),
          assignedBy: client,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
