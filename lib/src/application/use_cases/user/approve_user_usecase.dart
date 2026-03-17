import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/ports/input/approve_user_usecase_port.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';

class ApproveUserUseCase implements ApproveUserUseCasePort {
  final UserRepositoryPort _userRepo;

  ApproveUserUseCase({
    required UserRepositoryPort userRepository,
  }) : _userRepo = userRepository;

  @override
  FutureVoidResult execute({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    required UserId approvedById,
  }) async {
    try {
      // 1. Get the admin performing the action
      final adminResult = await _userRepo.findByIdGlobal(approvedById);
      
      return await adminResult.fold(
        (failure) async => left(failure),
        (admin) async {
          // 2. Get the target user
          final userResult = await _userRepo.findById(
            id: userId,
            gymId: gymId,
            role: role,
          );

          return await userResult.fold(
            (failure) async => left(failure),
            (user) async {
              // 3. User logic behavior (enforces permissions)
              try {
                final approvedUser = user.approve(admin);
                await _userRepo.save(approvedUser);
                return right(null);
              } catch (e) {
                return left(DomainFailure(message: e.toString()));
              }
            },
          );
        },
      );
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  FutureVoidResult reject({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    required UserId rejectedById,
  }) async {
    try {
      final adminResult = await _userRepo.findByIdGlobal(rejectedById);
      
      return await adminResult.fold(
        (failure) async => left(failure),
        (admin) async {
          final userResult = await _userRepo.findById(
            id: userId,
            gymId: gymId,
            role: role,
          );

          return await userResult.fold(
            (failure) async => left(failure),
            (user) async {
              try {
                final rejectedUser = user.reject(admin);
                await _userRepo.save(rejectedUser);
                return right(null);
              } catch (e) {
                return left(DomainFailure(message: e.toString()));
              }
            },
          );
        },
      );
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
