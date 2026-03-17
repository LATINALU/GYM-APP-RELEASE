/// Domain exception for business rule violations
class DomainException implements Exception {
  final String message;
  final String? code;

  const DomainException(this.message, {this.code});

  @override
  String toString() => 'DomainException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception when an entity is not found
class EntityNotFoundException extends DomainException {
  final String entityType;
  final String entityId;

  EntityNotFoundException({
    required this.entityType,
    required this.entityId,
  }) : super('$entityType con ID $entityId no encontrado');
}

/// Exception for authentication failures
class AuthException extends DomainException {
  const AuthException(super.message, {super.code});
}

/// Exception for insufficient permissions
class UnauthorizedException extends DomainException {
  const UnauthorizedException([super.message = 'No tienes permisos para realizar esta acción'])
      : super(code: 'UNAUTHORIZED');
}

/// Exception for validation failures
class ValidationException extends DomainException {
  final Map<String, String> errors;

  ValidationException({
    required String message,
    this.errors = const {},
  }) : super(message, code: 'VALIDATION_ERROR');
}
