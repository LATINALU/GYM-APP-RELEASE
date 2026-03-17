import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import '../../domain/ports/output/gym_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Register command input
class RegisterCommand {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;
  final GymId? gymId;
  final GymCode? gymCode;
  final double? weight;
  final double? height;
  final String? fitnessGoal;

  const RegisterCommand({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.gymId,
    this.gymCode,
    this.weight,
    this.height,
    this.fitnessGoal,
  });
}

/// Register result
class RegisterResult {
  final User user;
  final String token;

  const RegisterResult({
    required this.user,
    required this.token,
  });
}

/// Register use case
class RegisterUseCase {
  final AuthRepositoryPort _authRepository;
  final GymRepositoryPort _gymRepository;

  RegisterUseCase({
    required AuthRepositoryPort authRepository,
    required GymRepositoryPort gymRepository,
  })  : _authRepository = authRepository,
        _gymRepository = gymRepository;

  FutureResult<RegisterResult> execute(RegisterCommand command) async {
    try {
      // 1. Resolve GymId (optional for clients until QR scan)
      GymId? finalGymId = command.gymId;
      
      if (finalGymId == null && command.gymCode != null) {
        final gymResult = await _gymRepository.findByCode(command.gymCode!);
        finalGymId = gymResult.fold(
          (failure) => null,
          (gym) => gym.id,
        );
      }

      // 2. Resolve field values
      final emailResult = Email.tryParse(command.email);
      if (emailResult == null) return left(const ValidationFailure(message: 'Correo inválido'));

      final name = PersonName(firstName: command.firstName, lastName: command.lastName);
      final role = GymRole.fromString(command.role);

      // 3. Attempt registration via Repository
      final result = await _authRepository.register(
        email: emailResult,
        password: command.password,
        name: name,
        role: role,
        gymId: finalGymId,
        weight: command.weight,
        height: command.height,
        fitnessGoal: command.fitnessGoal,
      );

      return result.fold(
        (failure) => left(failure),
        (authResult) => right(RegisterResult(
          user: authResult.user,
          token: authResult.token,
        )),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
