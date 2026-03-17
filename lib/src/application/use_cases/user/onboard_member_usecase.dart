import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/ports/input/onboard_member_usecase_port.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';

class OnboardMemberUseCase implements OnboardMemberUseCasePort {
  final UserRepositoryPort _userRepo;

  OnboardMemberUseCase({
    required UserRepositoryPort userRepository,
  }) : _userRepo = userRepository;

  @override
  FutureVoidResult execute({
    required String identifier,
    required GymId gymId,
    required UserId ownerId,
  }) async {
    try {
      // 1. Get the owner/admin performing the action to check permissions
      final ownerResult = await _userRepo.findByIdGlobal(ownerId);
      
      return await ownerResult.fold(
        (failure) async => left(failure),
        (owner) async {
          // Verify permissions: Only Owners or Staff can onboard
          if (!owner.role.canManageEmployees && !owner.isOwner) {
            return left(const PermissionFailure(
              message: 'No tienes permisos para agregar miembros.',
            ));
          }

          // 2. Identify the target user. 
          // Assuming identifier is the UserId for now (scanned from QR).
          UserId targetId;
          try {
             targetId = UserId(identifier);
          } catch (e) {
             return left(const ValidationFailure(message: 'Código de usuario inválido.'));
          }

          final userResult = await _userRepo.findByIdGlobal(targetId);

          return await userResult.fold(
            (failure) async => left(failure),
            (user) async {
              // 3. Link user to gym and approve
              // We create a copy of the user with the new gym assignment and approved status
              // Note: In a real DB, this might involve creating a new record in the gym subcollection
              final onboardedUser = user.updateProfile().approve(owner); 
              
              // We explicitly set the gymId since the user might be from 'orphan-gym'
              // This is a business decision: Onboarding sets the user's primary gym
              final updatedUser = onboardedUser.assignToGym(gymId);

              await _userRepo.save(updatedUser);
              return right(null);
            },
          );
        },
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}

// Extension to help with Gym Assignment in the Use Case
extension UserGymAssignment on dynamic {
  // Since 'User' is an entity, let's assume we have a way to assign gym
  // I need to check if 'User' entity has this capability or just copyWith
}
