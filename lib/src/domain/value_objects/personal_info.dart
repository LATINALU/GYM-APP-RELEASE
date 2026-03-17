import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/validators.dart';

/// Value Object for Password with strength validation
/// Only used for creation/update, never stored as plaintext
class Password extends Equatable {
  final String value;

  const Password._(this.value);

  /// Create with validation
  factory Password(String value) {
    final error = PasswordValidator.validate(value);
    if (error != null) {
      throw DomainException(error, code: 'INVALID_PASSWORD');
    }
    return Password._(value);
  }

  /// Check if passwords match
  bool matches(Password other) => value == other.value;

  @override
  List<Object?> get props => [value];

  // Never expose password in toString for security
  @override
  String toString() => '********';
}

/// Value Object for Person Name
class PersonName extends Equatable {
  final String firstName;
  final String lastName;

  const PersonName._({
    required this.firstName,
    required this.lastName,
  });

  factory PersonName({
    required String firstName,
    required String lastName,
  }) {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();

    if (trimmedFirst.isEmpty) {
      throw const DomainException(
        'El nombre es requerido',
        code: 'INVALID_NAME',
      );
    }
    if (trimmedFirst.length > 50) {
      throw const DomainException(
        'El nombre no puede exceder 50 caracteres',
        code: 'INVALID_NAME',
      );
    }
    if (trimmedLast.length > 50) {
      throw const DomainException(
        'El apellido no puede exceder 50 caracteres',
        code: 'INVALID_NAME',
      );
    }

    return PersonName._(
      firstName: _capitalize(trimmedFirst),
      lastName: _capitalize(trimmedLast),
    );
  }

  /// Full name display
  String get fullName =>
      lastName.isNotEmpty ? '$firstName $lastName' : firstName;

  /// Initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  List<Object?> get props => [firstName, lastName];

  @override
  String toString() => fullName;
}

/// Value Object for Phone Number (optional)
class PhoneNumber extends Equatable {
  final String value;

  const PhoneNumber._(this.value);

  factory PhoneNumber(String value) {
    // Remove all non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) {
      throw const DomainException(
        'El número de teléfono no puede estar vacío',
        code: 'INVALID_PHONE',
      );
    }
    if (cleaned.length < 10 || cleaned.length > 15) {
      throw const DomainException(
        'El número de teléfono debe tener entre 10 y 15 dígitos',
        code: 'INVALID_PHONE',
      );
    }

    return PhoneNumber._(cleaned);
  }

  static PhoneNumber? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return PhoneNumber(value);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
