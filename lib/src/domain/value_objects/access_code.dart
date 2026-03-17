import 'dart:math';
import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';

/// Types of access codes in the system
enum AccessCodeType {
  /// Code for gym entry (members scan to check-in)
  gymEntry('Entrada al Gym'),

  /// Code for owner verification (business management)
  ownerVerification('Verificación de Dueño'),

  /// Code for employee invitation
  employeeInvitation('Invitación de Empleado'),

  /// Code for member onboarding (join a gym)
  memberOnboarding('Registro de Miembro'),

  /// Code for password reset
  passwordReset('Reseteo de Contraseña'),

  /// Code for two-factor authentication
  twoFactorAuth('Verificación 2FA');

  final String displayName;
  const AccessCodeType(this.displayName);
}

/// Value Object for Secure Access Codes
/// Uses Cryptographically Secure Pseudo-Random Number Generator (CSPRNG)
/// 
/// Security features:
/// - Uses `Random.secure()` for cryptographic randomness
/// - Configurable length (6-32 chars)
/// - Time-bound expiration
/// - Single-use tracking
/// - Type-specific prefixes for easy identification
class AccessCode extends Equatable {
  final String value;
  final AccessCodeType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedBy; // UserId of who consumed the code
  final DateTime? usedAt;

  const AccessCode._({
    required this.value,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedBy,
    this.usedAt,
  });

  /// Generate a new secure access code
  /// [length] - Number of random characters (6-32, default: 8)
  /// [expirationMinutes] - Time until expiration (default: 30 min)
  factory AccessCode.generate({
    required AccessCodeType type,
    int length = 8,
    int expirationMinutes = 30,
  }) {
    if (length < 6 || length > 32) {
      throw const DomainException(
        'La longitud del código debe ser entre 6 y 32 caracteres',
      );
    }

    final code = _generateSecureCode(length, type);
    final now = DateTime.now();

    return AccessCode._(
      value: code,
      type: type,
      createdAt: now,
      expiresAt: now.add(Duration(minutes: expirationMinutes)),
    );
  }

  /// Restore from persistence
  factory AccessCode.restore({
    required String value,
    required AccessCodeType type,
    required DateTime createdAt,
    required DateTime expiresAt,
    bool isUsed = false,
    String? usedBy,
    DateTime? usedAt,
  }) {
    return AccessCode._(
      value: value,
      type: type,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isUsed: isUsed,
      usedBy: usedBy,
      usedAt: usedAt,
    );
  }

  // === BEHAVIOR ===

  /// Check if code is still valid (not expired and not used)
  bool get isValid => !isUsed && !isExpired;

  /// Check if code has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Remaining time before expiration
  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Consume this code (mark as used)
  AccessCode consume(String userId) {
    if (!isValid) {
      throw const DomainException('El código ya no es válido');
    }
    return AccessCode._(
      value: value,
      type: type,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isUsed: true,
      usedBy: userId,
      usedAt: DateTime.now(),
    );
  }

  /// Validate a code string against this AccessCode
  bool matches(String input) {
    return value.toUpperCase() == input.trim().toUpperCase();
  }

  // === PRIVATE METHODS ===

  /// Generate cryptographically secure random code
  /// Uses `Random.secure()` which is backed by OS-level CSPRNG
  static String _generateSecureCode(int length, AccessCodeType type) {
    final random = Random.secure(); // CSPRNG
    final prefix = _getPrefix(type);

    // Character set: Uppercase + Digits, excluding ambiguous chars (0/O, 1/I/L)
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

    final buffer = StringBuffer(prefix);
    for (var i = 0; i < length; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  /// Get type-specific prefix for easy identification
  static String _getPrefix(AccessCodeType type) {
    switch (type) {
      case AccessCodeType.gymEntry:
        return 'GE-';
      case AccessCodeType.ownerVerification:
        return 'OV-';
      case AccessCodeType.employeeInvitation:
        return 'EI-';
      case AccessCodeType.memberOnboarding:
        return 'MO-';
      case AccessCodeType.passwordReset:
        return 'PR-';
      case AccessCodeType.twoFactorAuth:
        return '2F-';
    }
  }

  @override
  List<Object?> get props => [value, type, createdAt];

  @override
  String toString() => 'AccessCode($value, ${type.displayName}, valid: $isValid)';
}
