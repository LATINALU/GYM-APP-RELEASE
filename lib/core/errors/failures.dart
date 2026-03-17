import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server/API related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Error de conexión. Verifica tu internet.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Error al acceder a datos locales.',
    super.code = 'CACHE_ERROR',
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Credenciales inválidas',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'Usuario no encontrado',
        code: 'USER_NOT_FOUND',
      );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
        message: 'El correo ya está registrado',
        code: 'EMAIL_IN_USE',
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'La contraseña es muy débil',
        code: 'WEAK_PASSWORD',
      );
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors = const {},
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'No tienes permisos para realizar esta acción',
    super.code = 'PERMISSION_DENIED',
  });
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Recurso no encontrado',
    super.code = 'NOT_FOUND',
  });
}

/// Domain business logic failures
class DomainFailure extends Failure {
  const DomainFailure({
    required super.message,
    super.code = 'DOMAIN_ERROR',
  });
}
