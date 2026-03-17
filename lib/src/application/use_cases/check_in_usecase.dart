import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/input/check_in_usecase_port.dart';
import '../../domain/ports/output/output_ports.dart';

/// Implementation of CheckInUseCasePort
/// Handles client attendance tracking
class CheckInUseCase implements CheckInUseCasePort {
  final UserRepositoryPort _userRepository;
  final CheckInRepositoryPort _checkInRepository;

  CheckInUseCase({
    required UserRepositoryPort userRepository,
    required CheckInRepositoryPort checkInRepository,
  })  : _userRepository = userRepository,
        _checkInRepository = checkInRepository;

  @override
  FutureResult<CheckIn> checkIn(CheckInCommand command) async {
    try {
      // 1. Validate client exists and is active
      final clientResult = await _userRepository.findByIdGlobal(command.clientId);
      final client = clientResult.fold(
        (failure) => throw const DomainException('Cliente no encontrado'),
        (user) => user,
      );

      if (!client.isActive) {
        return left(const ValidationFailure(
          message: 'El cliente no está activo',
        ));
      }

      // 2. Check if client already has an active check-in
      final activeCheckIn = await _checkInRepository.findActiveByClient(command.clientId);
      final hasActive = activeCheckIn.fold(
        (_) => false,
        (checkIn) => checkIn != null,
      );

      if (hasActive) {
        return left(const ValidationFailure(
          message: 'El cliente ya tiene un check-in activo. Debe hacer check-out primero.',
        ));
      }

      // 3. Validate registeredBy if provided
      if (command.registeredById != null) {
        final registererResult = await _userRepository.findByIdGlobal(command.registeredById!);
        final registerer = registererResult.fold(
          (failure) => throw const DomainException('Usuario registrador no encontrado'),
          (user) => user,
        );

        if (!registerer.role.canRegisterCheckIns) {
          return left(const PermissionFailure(
            message: 'No tienes permisos para registrar check-ins',
          ));
        }
      }

      // 4. Create check-in
      final checkIn = CheckIn.create(
        clientId: command.clientId,
        registeredById: command.registeredById,
        notes: command.notes,
      );

      // 5. Save check-in
      final saveResult = await _checkInRepository.save(checkIn);
      if (saveResult.isLeft()) {
        return left(saveResult.fold(
          (f) => f,
          (_) => const ServerFailure(message: 'Error al guardar'),
        ));
      }

      return right(checkIn);
    } on DomainException catch (e) {
      return left(ValidationFailure(message: e.message));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<CheckIn> checkOut(CheckOutCommand command) async {
    try {
      // 1. Find active check-in
      final activeResult = await _checkInRepository.findActiveByClient(command.clientId);
      final activeCheckIn = activeResult.fold(
        (failure) => throw DomainException(failure.message),
        (checkIn) => checkIn,
      );

      if (activeCheckIn == null) {
        return left(const ValidationFailure(
          message: 'No hay check-in activo para este cliente',
        ));
      }

      // 2. Record check-out
      final updatedCheckIn = activeCheckIn.recordCheckOut();

      // 3. Save updated check-in
      final saveResult = await _checkInRepository.save(updatedCheckIn);
      if (saveResult.isLeft()) {
        return left(saveResult.fold(
          (f) => f,
          (_) => const ServerFailure(message: 'Error al guardar'),
        ));
      }

      return right(updatedCheckIn);
    } on DomainException catch (e) {
      return left(ValidationFailure(message: e.message));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
