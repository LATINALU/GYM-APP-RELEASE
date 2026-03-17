import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import '../../domain/ports/output/gym_repository_port.dart';
import '../../domain/ports/output/email_service_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Command for registering a new gym and its owner
class RegisterGymAndOwnerCommand {
  final String gymName;
  final String? gymAddress;
  final String ownerEmail;
  final String ownerPassword;
  final String ownerFirstName;
  final String ownerLastName;

  const RegisterGymAndOwnerCommand({
    required this.gymName,
    this.gymAddress,
    required this.ownerEmail,
    required this.ownerPassword,
    required this.ownerFirstName,
    required this.ownerLastName,
  });
}

/// Result of gym and owner registration
class RegisterGymAndOwnerResult {
  final Gym gym;
  final User owner;
  final String token;

  const RegisterGymAndOwnerResult({
    required this.gym,
    required this.owner,
    required this.token,
  });
}

/// Use case for registering a new gym and its owner
/// This is the entry point for new SaaS customers (Owners)
class RegisterGymAndOwnerUseCase {
  final GymRepositoryPort _gymRepository;
  final AuthRepositoryPort _authRepository;
  final EmailServicePort _emailService;

  RegisterGymAndOwnerUseCase({
    required GymRepositoryPort gymRepository,
    required AuthRepositoryPort authRepository,
    required EmailServicePort emailService,
  })  : _gymRepository = gymRepository,
        _authRepository = authRepository,
        _emailService = emailService;

  FutureResult<RegisterGymAndOwnerResult> execute(
    RegisterGymAndOwnerCommand command,
  ) async {
    try {
      // 1. Create Gym Entity
      final gym = Gym.create(
        name: command.gymName,
        address: command.gymAddress,
      );

      // 2. Save Gym
      final saveGymResult = await _gymRepository.save(gym);
      
      return await saveGymResult.fold(
        (failure) => left(failure),
        (gymId) async {
          // 3. Register Owner User
          final email = Email(command.ownerEmail);
          final name = PersonName(
            firstName: command.ownerFirstName,
            lastName: command.ownerLastName,
          );
          final role = const GymRole.owner();

          final authResult = await _authRepository.register(
            email: email,
            password: command.ownerPassword,
            name: name,
            role: role,
            gymId: gymId,
          );

          return await authResult.fold(
            (failure) async {
              // Rollback: delete gym if auth fails (optional but recommended)
              await _gymRepository.deactivate(gymId);
              return left(failure);
            },
            (auth) async {
              // 4. Send Welcome Email
              await _emailService.sendWelcomeEmail(
                to: email,
                userName: name.firstName,
                temporaryPassword: command.ownerPassword, // Since they chose it, maybe different template?
                appDownloadLink: 'https://gym-app.com/dashboard',
              );

              return right(RegisterGymAndOwnerResult(
                gym: gym,
                owner: auth.user,
                token: auth.token,
              ));
            },
          );
        },
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado al registrar el gimnasio: $e'));
    }
  }
}
