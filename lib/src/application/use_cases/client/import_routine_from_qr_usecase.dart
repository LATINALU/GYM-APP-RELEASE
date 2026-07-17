import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/output_ports.dart';
import '../../../domain/value_objects/value_objects.dart';

/// Payload del QR `routine_import` ya parseado y validado.
/// Se usa para previsualizar la rutina antes de confirmar la importación.
class RoutineImportPreview {
  final String routineId;
  final String gymId;
  final String name;
  final String? description;
  final String difficulty;
  final int estimatedDuration;
  final List<Map<String, dynamic>> exercises;
  final DateTime? expiresAt;

  const RoutineImportPreview({
    required this.routineId,
    required this.gymId,
    required this.name,
    this.description,
    required this.difficulty,
    required this.estimatedDuration,
    required this.exercises,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Resultado de una importación exitosa.
class ImportRoutineResult {
  final RoutineAssignment assignment;
  final WorkoutRoutine routine;
  final String message;

  const ImportRoutineResult({
    required this.assignment,
    required this.routine,
    required this.message,
  });
}

/// Caso de uso: importar una rutina escaneando un QR `routine_import`
/// (generado por el kiosko o por "Compartir QR" en Training Forge).
///
/// El cliente se auto-asigna la rutina existente de su gimnasio: no se
/// duplica el documento, solo se crea una [RoutineAssignment] con
/// `assignedById == clientId` (permitido en dominio y reglas Firestore).
class ImportRoutineFromQrUseCase {
  final UserRepositoryPort _userRepository;
  final RoutineRepositoryPort _routineRepository;
  final AssignmentRepositoryPort _assignmentRepository;

  ImportRoutineFromQrUseCase({
    required UserRepositoryPort userRepository,
    required RoutineRepositoryPort routineRepository,
    required AssignmentRepositoryPort assignmentRepository,
  })  : _userRepository = userRepository,
        _routineRepository = routineRepository,
        _assignmentRepository = assignmentRepository;

  /// Parsea y valida el payload del QR sin tocar la red.
  /// Devuelve el preview para mostrar al usuario antes de importar.
  static Either<Failure, RoutineImportPreview> parsePayload(String raw) {
    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic>) {
        return left(const ValidationFailure(
          message: 'El código QR no contiene una rutina',
        ));
      }
      data = decoded;
    } catch (_) {
      return left(const ValidationFailure(
        message: 'El código QR no contiene una rutina',
      ));
    }

    if (data['type'] != 'routine_import') {
      return left(const ValidationFailure(
        message: 'Este QR no es de una rutina (¿escaneaste el pase de acceso?)',
      ));
    }

    final routineId = (data['routineId'] as String?)?.trim() ?? '';
    final name = (data['name'] as String?)?.trim() ?? '';
    if (routineId.isEmpty || name.isEmpty) {
      return left(const ValidationFailure(
        message: 'El código QR está incompleto',
      ));
    }

    DateTime? expiresAt;
    final rawExpiry = data['expiresAt'] as String?;
    if (rawExpiry != null && rawExpiry.isNotEmpty) {
      expiresAt = DateTime.tryParse(rawExpiry);
    }

    final preview = RoutineImportPreview(
      routineId: routineId,
      gymId: (data['gymId'] as String?)?.trim() ?? '',
      name: name,
      description: (data['description'] as String?)?.trim().isNotEmpty == true
          ? (data['description'] as String).trim()
          : null,
      difficulty: (data['difficulty'] as String?)?.trim() ?? 'Intermedio',
      estimatedDuration: (data['estimatedDuration'] as num?)?.toInt() ?? 60,
      exercises: ((data['exercises'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      expiresAt: expiresAt,
    );

    if (preview.isExpired) {
      return left(const ValidationFailure(
        message: 'El código QR expiró. Genera uno nuevo desde el kiosko.',
      ));
    }

    return right(preview);
  }

  FutureResult<ImportRoutineResult> execute({
    required String rawPayload,
    required UserId clientId,
  }) async {
    try {
      // 1. Re-validar el payload (incluida la expiración al momento de confirmar)
      final previewResult = parsePayload(rawPayload);
      final preview = previewResult.fold<RoutineImportPreview?>(
        (_) => null,
        (p) => p,
      );
      if (preview == null) {
        return left(previewResult.fold(
          (f) => f,
          (_) => const ValidationFailure(message: 'QR inválido'),
        ));
      }

      // 2. Cargar al cliente que importa
      final userResult = await _userRepository.findByIdGlobal(clientId);
      final user = userResult.fold(
        (failure) => throw DomainException(failure.message),
        (u) => u,
      );

      // 3. La rutina debe ser del gimnasio del cliente
      if (preview.gymId.isNotEmpty && user.gymId.value != preview.gymId) {
        return left(const ValidationFailure(
          message: 'Esta rutina pertenece a otro gimnasio',
        ));
      }

      // 4. La rutina debe seguir existiendo y estar activa
      final routineResult =
          await _routineRepository.findById(RoutineId(preview.routineId));
      final routine = routineResult.fold<WorkoutRoutine?>(
        (_) => null,
        (r) => r,
      );
      if (routine == null || !routine.isActive) {
        return left(const ValidationFailure(
          message: 'La rutina ya no está disponible en tu gimnasio',
        ));
      }

      // 5. Evitar duplicados
      final hasActive = await _assignmentRepository.hasActiveAssignment(
        clientId,
        routine.id,
      );
      if (hasActive) {
        return left(const ValidationFailure(
          message: 'Ya tienes esta rutina en tu plan',
        ));
      }

      // 6. Auto-asignación
      final assignment = RoutineAssignment.create(
        routineId: routine.id,
        clientId: clientId,
        assignedBy: user,
        notes: 'Importada por QR',
      );

      final saveResult = await _assignmentRepository.save(assignment);
      if (saveResult.isLeft()) {
        return left(saveResult.fold(
          (f) => f,
          (_) => const ServerFailure(message: 'Error al guardar'),
        ));
      }

      return right(ImportRoutineResult(
        assignment: assignment,
        routine: routine,
        message: 'Rutina "${routine.name}" agregada a tu plan',
      ));
    } on UnauthorizedException catch (e) {
      return left(PermissionFailure(message: e.message));
    } on DomainException catch (e) {
      return left(ValidationFailure(message: e.message));
    } catch (e) {
      return left(ServerFailure(message: 'Error al importar la rutina: $e'));
    }
  }
}
