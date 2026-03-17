import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';

/// Value Object for Gym Discovery Code
/// Requirements: Alphanumeric, Uppercase, 4-10 characters
class GymCode extends Equatable {
  final String value;

  factory GymCode(String code) {
    final sanitized = code.trim().toUpperCase();
    
    // Security and Format Validation
    if (sanitized.isEmpty) {
      throw const DomainException('El código no puede estar vacío');
    }
    
    if (sanitized.length < 4 || sanitized.length > 10) {
      throw const DomainException('El código debe tener entre 4 y 10 caracteres');
    }
    
    final alphanumeric = RegExp(r'^[A-Z0-9]+$');
    if (!alphanumeric.hasMatch(sanitized)) {
      throw const DomainException('Solo se permiten caracteres alfanuméricos');
    }

    return GymCode._(sanitized);
  }

  const GymCode._(this.value);

  /// Generate a code from gym name (first 4 uppercase letters + 2 random digits)
  factory GymCode.generate(String gymName) {
    final clean = gymName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final prefix = clean.length >= 4 ? clean.substring(0, 4) : clean.padRight(4, 'X');
    final suffix = (DateTime.now().millisecondsSinceEpoch % 99).toString().padLeft(2, '0');
    return GymCode('$prefix$suffix');
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
