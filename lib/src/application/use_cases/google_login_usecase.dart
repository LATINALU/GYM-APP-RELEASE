import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import 'ensure_pending_registration_usecase.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import '../../domain/value_objects/value_objects.dart';

class GoogleLoginCommand {
  final String? gymCode;

  const GoogleLoginCommand({
    this.gymCode,
  });
}

class GoogleLoginResult {
  final User user;
  final String token;

  const GoogleLoginResult({
    required this.user,
    required this.token,
  });
}

class GoogleLoginUseCase {
  final AuthRepositoryPort _authRepository;
  final EnsurePendingRegistrationUseCase _ensurePendingRegistrationUseCase;

  GoogleLoginUseCase({
    required AuthRepositoryPort authRepository,
    required EnsurePendingRegistrationUseCase ensurePendingRegistrationUseCase,
  })  : _authRepository = authRepository,
        _ensurePendingRegistrationUseCase = ensurePendingRegistrationUseCase;

  FutureResult<GoogleLoginResult> execute(GoogleLoginCommand command) async {
    try {
      GymCode? gymCode;
      final rawGymCode = command.gymCode?.trim().toUpperCase();
      if (rawGymCode != null && rawGymCode.isNotEmpty) {
        try {
          gymCode = GymCode(rawGymCode);
        } catch (_) {
          return left(const ValidationFailure(
            message: 'Código de gimnasio inválido',
          ));
        }
      }

      final result = await _authRepository.signInWithGoogle(gymCode: gymCode);

      return await result.fold<Future<Either<Failure, GoogleLoginResult>>>(
        (failure) async => left(failure),
        (authResult) async {
          final pendingResult = await _ensurePendingRegistrationUseCase.execute(
            EnsurePendingRegistrationCommand(
              user: authResult.user,
              gymCode: gymCode,
            ),
          );

          return pendingResult.fold(
            (failure) => left(failure),
            (_) => right(
              GoogleLoginResult(
                user: authResult.user,
                token: authResult.token,
              ),
            ),
          );
        },
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
