import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/gym_repository_port.dart';
import '../../domain/ports/output/pending_registration_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';

class EnsurePendingRegistrationCommand {
  final User user;
  final GymCode? gymCode;
  final RegistrationSource? source;

  const EnsurePendingRegistrationCommand({
    required this.user,
    this.gymCode,
    this.source,
  });
}

class EnsurePendingRegistrationUseCase {
  final PendingRegistrationRepositoryPort _pendingRegistrationRepository;
  final GymRepositoryPort _gymRepository;

  const EnsurePendingRegistrationUseCase({
    required PendingRegistrationRepositoryPort pendingRegistrationRepository,
    required GymRepositoryPort gymRepository,
  })  : _pendingRegistrationRepository = pendingRegistrationRepository,
        _gymRepository = gymRepository;

  FutureVoidResult execute(EnsurePendingRegistrationCommand command) async {
    try {
      if (command.user.role.type != GymRoleType.client) {
        return const Right(null);
      }

      final hasExplicitGymIntent = command.gymCode != null;
      final hasAssignedGym = command.user.gymId.value != 'orphan-gym';
      final isApprovedMember =
          command.user.membershipStatus == MembershipStatus.approved;

      if (isApprovedMember && hasAssignedGym && !hasExplicitGymIntent) {
        return const Right(null);
      }

      final gymResult = await _resolveTargetGym(command);
      return await gymResult.fold(
        (failure) async => Left(failure),
        (targetGym) async {
          final registrationsResult = await _pendingRegistrationRepository.findByUserId(
            command.user.id,
          );

          return await registrationsResult.fold(
            (failure) async => Left(failure),
            (registrations) async {
              PendingRegistration? pendingRegistration;
              for (final registration in registrations) {
                if (registration.status == RegistrationStatus.pendingReview) {
                  pendingRegistration = registration;
                  break;
                }
              }

              if (pendingRegistration != null) {
                if (targetGym == null) {
                  return const Right(null);
                }

                final alreadyTargetsGym =
                    pendingRegistration.targetGymId == targetGym.id.value;
                if (alreadyTargetsGym) {
                  return const Right(null);
                }

                if (pendingRegistration.targetGymId != null &&
                    pendingRegistration.targetGymId!.isNotEmpty) {
                  return const Left(DomainFailure(
                    message:
                        'Ya tienes una solicitud pendiente para otro gimnasio. Cancélala o espera a que sea revisada.',
                  ));
                }

                final reassigned = pendingRegistration.assignToGym(
                  gymId: targetGym.id.value,
                  gymName: targetGym.name,
                  gymCode: targetGym.code.value,
                  accessCode: command.gymCode?.value,
                );

                return _pendingRegistrationRepository.update(reassigned);
              }

              final registration = PendingRegistration.create(
                userId: command.user.id.value,
                userEmail: command.user.email.value,
                userName: command.user.name.fullName,
                userPhone: command.user.phone?.value,
                targetGymId: targetGym?.id.value,
                targetGymName: targetGym?.name,
                targetGymCode: targetGym?.code.value,
                accessCodeUsed: command.gymCode?.value,
                source: command.source ??
                    (command.gymCode != null
                        ? RegistrationSource.manualCode
                        : RegistrationSource.appSearch),
                fitnessGoal: command.user.fitnessGoal,
                weight: command.user.weight,
                height: command.user.height,
              );

              return _pendingRegistrationRepository.save(registration);
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  FutureResult<Gym?> _resolveTargetGym(
    EnsurePendingRegistrationCommand command,
  ) async {
    if (command.gymCode != null) {
      final gymResult = await _gymRepository.findByCode(command.gymCode!);
      return gymResult.fold(
        (failure) => Left(failure),
        (gym) => Right(gym),
      );
    }

    final hasAssignedGym = command.user.gymId.value != 'orphan-gym';
    if (!hasAssignedGym) {
      return const Right(null);
    }

    final gymResult = await _gymRepository.findById(command.user.gymId);
    return gymResult.fold(
      (failure) => Left(failure),
      (gym) => Right(gym),
    );
  }
}
