import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/input/assign_routine_usecase_port.dart';
import '../../domain/ports/output/output_ports.dart';

/// Implementation of AssignRoutineUseCasePort
/// Handles the business logic for assigning routines to clients
class AssignRoutineUseCase implements AssignRoutineUseCasePort {
  final UserRepositoryPort _userRepository;
  final RoutineRepositoryPort _routineRepository;
  final AssignmentRepositoryPort _assignmentRepository;

  AssignRoutineUseCase({
    required UserRepositoryPort userRepository,
    required RoutineRepositoryPort routineRepository,
    required AssignmentRepositoryPort assignmentRepository,
  })  : _userRepository = userRepository,
        _routineRepository = routineRepository,
        _assignmentRepository = assignmentRepository;

  @override
  FutureResult<AssignRoutineResult> execute(AssignRoutineCommand command) async {
    try {
      // 1. Get and validate the assigner
      final assignerResult = await _userRepository.findByIdGlobal(command.assignerId);
      final assigner = assignerResult.fold(
        (failure) => throw DomainException(failure.message),
        (user) => user,
      );

      // 2. Validate assigner has permission
      if (!assigner.role.canAssignRoutines) {
        return left(const PermissionFailure(
          message: 'No tienes permisos para asignar rutinas',
        ));
      }

      // 3. Get and validate the client
      final clientResult = await _userRepository.findByIdGlobal(command.clientId);
      final client = clientResult.fold(
        (failure) => throw const DomainException('Cliente no encontrado'),
        (user) => user,
      );

      // 4. Validate client is actually a client
      if (!client.isClient) {
        return left(const ValidationFailure(
          message: 'Solo se pueden asignar rutinas a clientes',
        ));
      }

      // 5. Get and validate the routine
      final routineResult = await _routineRepository.findById(command.routineId);
      final routine = routineResult.fold(
        (failure) => throw const DomainException('Rutina no encontrada'),
        (r) => r,
      );

      // 6. Check if routine is active
      if (!routine.isActive) {
        return left(const ValidationFailure(
          message: 'No se puede asignar una rutina inactiva',
        ));
      }

      // 7. Check if client already has this routine assigned
      final hasActive = await _assignmentRepository.hasActiveAssignment(
        command.clientId,
        command.routineId,
      );
      if (hasActive) {
        return left(const ValidationFailure(
          message: 'El cliente ya tiene esta rutina asignada',
        ));
      }

      // 8. Validate routine suitability (optional business rule)
      if (!routine.isSuitableFor(client)) {
        return left(const ValidationFailure(
          message: 'Esta rutina no es adecuada para el nivel del cliente',
        ));
      }

      // 9. Create the assignment
      final assignment = RoutineAssignment.create(
        routineId: command.routineId,
        clientId: command.clientId,
        assignedBy: assigner,
        startDate: command.startDate,
        endDate: command.endDate,
        notes: command.notes,
      );

      // 10. Save the assignment
      final saveResult = await _assignmentRepository.save(assignment);
      if (saveResult.isLeft()) {
        return left(saveResult.fold(
          (f) => f,
          (_) => const ServerFailure(message: 'Error al guardar'),
        ));
      }

      // 11. Return success
      return right(AssignRoutineResult(
        assignment: assignment,
        message: 'Rutina "${routine.name}" asignada a ${client.displayName}',
      ));
    } on DomainException catch (e) {
      return left(ValidationFailure(message: e.message));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
