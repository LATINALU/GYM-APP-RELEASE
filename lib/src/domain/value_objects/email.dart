import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/validators.dart';

/// Value Object for Email with validation
/// Immutable, validated in constructor
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  /// Factory constructor with validation
  factory Email(String value) {
    final trimmed = value.toLowerCase().trim();
    if (!EmailValidator.isValid(trimmed)) {
      throw const DomainException(
        'El correo electrónico no es válido',
        code: 'INVALID_EMAIL',
      );
    }
    return Email._(trimmed);
  }

  /// Tries to create Email, returns null if invalid
  static Email? tryParse(String value) {
    try {
      return Email(value);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
