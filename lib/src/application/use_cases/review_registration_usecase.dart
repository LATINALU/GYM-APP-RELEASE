import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/entities/user.dart';
import '../../domain/ports/input/review_registration_usecase_port.dart';
import '../../domain/ports/output/pending_registration_repository_port.dart';
import '../../domain/ports/output/user_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Implementation of ReviewRegistrationUseCasePort
/// 
/// Orchestrates the approval/rejection workflow:
/// 1. Owner/Admin reviews a pending registration
/// 2. If approved: creates user in gym's member collection, updates registration status
/// 3. If rejected: updates registration status with reason
class ReviewRegistrationUseCase implements ReviewRegistrationUseCasePort {
  final PendingRegistrationRepositoryPort _registrationRepo;
  final UserRepositoryPort _userRepo;

  const ReviewRegistrationUseCase({
    required PendingRegistrationRepositoryPort registrationRepository,
    required UserRepositoryPort userRepository,
  })  : _registrationRepo = registrationRepository,
        _userRepo = userRepository;

  @override
  FutureVoidResult approve({
    required String registrationId,
    required UserId reviewedBy,
    required GymId gymId,
    GymRoleType assignedRole = GymRoleType.client,
  }) async {
    try {
      // 1. Find the registration
      final registrationResult = await _registrationRepo.findById(registrationId);
      
      return registrationResult.fold(
        (failure) => Left(failure),
        (registration) async {
          // 2. Validate it can be reviewed
          if (!registration.canBeReviewed) {
            return const Left(DomainFailure(
              message: 'Esta solicitud ya fue procesada o ha expirado',
            ));
          }

          // 3. Verify the reviewer has permission
          final reviewerResult = await _userRepo.findByIdGlobal(reviewedBy);
          final reviewer = reviewerResult.fold(
            (f) => null,
            (user) => user,
          );

          if (reviewer == null) {
            return const Left(DomainFailure(
              message: 'Revisor no encontrado',
            ));
          }

          if (!reviewer.role.canManageEmployees && reviewer.role.type != GymRoleType.owner) {
            return const Left(DomainFailure(
              message: 'No tienes permisos para aprobar solicitudes',
            ));
          }

          // 4. Approve the registration
          final approved = registration.approve(approvedBy: reviewedBy.value);

          // 5. Create the user in the gym's member collection
          final newUser = User.create(
            email: Email(registration.userEmail),
            name: PersonName(
              firstName: registration.userName.split(' ').first,
              lastName: registration.userName.split(' ').length > 1
                  ? registration.userName.split(' ').sublist(1).join(' ')
                  : '',
            ),
            role: GymRole.fromString(assignedRole.name),
            gymId: gymId,
            membershipStatus: MembershipStatus.approved,
            weight: registration.weight,
            height: registration.height,
            fitnessGoal: registration.fitnessGoal,
          );

          // 6. Save the new user
          final saveResult = await _userRepo.save(newUser);
          
          return saveResult.fold(
            (failure) => Left(failure),
            (_) async {
              // 7. Update registration status
              final updateResult = await _registrationRepo.update(approved);
              return updateResult;
            },
          );
        },
      );
    } catch (e) {
      return Left(DomainFailure(message: 'Error al aprobar: $e'));
    }
  }

  @override
  FutureVoidResult reject({
    required String registrationId,
    required UserId rejectedBy,
    String? reason,
  }) async {
    try {
      final registrationResult = await _registrationRepo.findById(registrationId);
      
      return registrationResult.fold(
        (failure) => Left(failure),
        (registration) async {
          if (!registration.canBeReviewed) {
            return const Left(DomainFailure(
              message: 'Esta solicitud ya fue procesada o ha expirado',
            ));
          }

          final rejected = registration.reject(
            rejectedBy: rejectedBy.value,
            reason: reason,
          );

          return await _registrationRepo.update(rejected);
        },
      );
    } catch (e) {
      return Left(DomainFailure(message: 'Error al rechazar: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> getPendingForGym(GymId gymId) {
    return _registrationRepo.findByGymId(gymId);
  }

  @override
  Future<int> getPendingCount(GymId gymId) {
    return _registrationRepo.countPendingByGymId(gymId);
  }
}
