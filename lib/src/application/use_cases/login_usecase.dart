import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';

/// Login command input
class LoginCommand {
  final String email;
  final String password;

  const LoginCommand({
    required this.email,
    required this.password,
  });
}

/// Login result
class LoginResult {
  final User user;
  final String token;

  const LoginResult({
    required this.user,
    required this.token,
  });
}

/// Login use case
class LoginUseCase {
  final AuthRepositoryPort _authRepository;

  LoginUseCase({required AuthRepositoryPort authRepository})
      : _authRepository = authRepository;

  FutureResult<LoginResult> execute(LoginCommand command) async {
    try {
      // 1. Validate email format
      final email = Email.tryParse(command.email);
      if (email == null) {
        return left(const ValidationFailure(
          message: 'El correo electrónico no es válido',
        ));
      }

      // 2. Validate password is not empty
      if (command.password.isEmpty) {
        return left(const ValidationFailure(
          message: 'La contraseña es requerida',
        ));
      }

      // 3. Attempt login
      final credentials = AuthCredentials(
        email: email,
        password: command.password,
      );

      final result = await _authRepository.login(credentials);

      return result.fold(
        (failure) => left(failure),
        (authResult) => right(LoginResult(
          user: authResult.user,
          token: authResult.token,
        )),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
