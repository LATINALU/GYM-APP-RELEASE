import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/ports/output/output_ports.dart';
import '../../domain/value_objects/value_objects.dart';

/// Command for automatic user registration
class AutomaticRegistrationCommand {
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final bool sendWelcomeEmail;
  final bool notifyOwner;
  final UserId? registeredBy; // Employee or Owner who registered this user
  final GymId gymId; // Added for multi-tenancy

  const AutomaticRegistrationCommand({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.gymId,
    this.phone,
    this.sendWelcomeEmail = true,
    this.notifyOwner = true,
    this.registeredBy,
  });
}

/// Result of automatic registration
class AutomaticRegistrationResult {
  final User user;
  final String temporaryPassword;
  final String token;
  final bool welcomeEmailSent;
  final bool ownerNotified;
  final DateTime registeredAt;

  const AutomaticRegistrationResult({
    required this.user,
    required this.temporaryPassword,
    required this.token,
    required this.welcomeEmailSent,
    required this.ownerNotified,
    required this.registeredAt,
  });
}

/// Automatic Registration Use Case
/// 
/// This enhanced use case handles the complete automated registration flow:
/// 1. Validates input data
/// 2. Generates secure temporary password
/// 3. Creates user in Firebase Auth
/// 4. Creates user profile in Firestore
/// 5. Sends welcome email with credentials
/// 6. Notifies owner/relevant staff
/// 7. Subscribes user to FCM topics based on role
class AutomaticRegistrationUseCase {
  final AuthRepositoryPort _authRepository;
  final EmailServicePort _emailService;
  final NotificationServicePort _notificationService;

  /// App download link for welcome email
  static const String _appDownloadLink = 'https://gym-app.com/download';

  AutomaticRegistrationUseCase({
    required AuthRepositoryPort authRepository,
    required UserRepositoryPort userRepository,
    required EmailServicePort emailService,
    required NotificationServicePort notificationService,
  })  : _authRepository = authRepository,
        _emailService = emailService,
        _notificationService = notificationService;

  /// Execute the automatic registration process
  FutureResult<AutomaticRegistrationResult> execute(
    AutomaticRegistrationCommand command,
  ) async {
    try {
      // === STEP 1: Validate Input Data ===
      final validationResult = _validateInput(command);
      if (validationResult != null) {
        return left(validationResult);
      }

      // Parse email
      final email = Email.tryParse(command.email);
      if (email == null) {
        return left(const ValidationFailure(
          message: 'El correo electrónico no es válido',
          fieldErrors: {'email': 'Formato de email inválido'},
        ));
      }

      // === STEP 2: Generate Secure Temporary Password ===
      final temporaryPassword = _generateSecurePassword();

      // === STEP 3: Create Value Objects ===
      final name = PersonName(
        firstName: command.firstName.trim(),
        lastName: command.lastName.trim(),
      );
      final role = GymRole.fromString(command.role);
      final phone = command.phone != null && command.phone!.isNotEmpty
          ? PhoneNumber.tryParse(command.phone!)
          : null;

      // === STEP 4: Register in Firebase Auth ===
      final authResult = await _authRepository.register(
        email: email,
        password: temporaryPassword,
        name: name,
        role: role,
        gymId: command.gymId,
      );

      return await authResult.fold(
        (failure) => left(failure),
        (auth) async {
          final user = auth.user;
          bool welcomeEmailSent = false;
          bool ownerNotified = false;

          // === STEP 5: Send Welcome Email ===
          if (command.sendWelcomeEmail) {
            final emailResult = await _emailService.sendWelcomeEmail(
              to: email,
              userName: name.firstName,
              temporaryPassword: temporaryPassword,
              appDownloadLink: _appDownloadLink,
            );
            welcomeEmailSent = emailResult.success;
          }

          // === STEP 6: Notify Owner/Staff ===
          if (command.notifyOwner && user.isClient) {
            ownerNotified = await _notifyRelevantStaff(user, command.registeredBy);
          }

          // === STEP 7: Subscribe to FCM Topics ===
          await _subscribeToRoleTopics(user);

          // === STEP 8: Return Success Result ===
          return right(AutomaticRegistrationResult(
            user: user,
            temporaryPassword: temporaryPassword,
            token: auth.token,
            welcomeEmailSent: welcomeEmailSent,
            ownerNotified: ownerNotified,
            registeredAt: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  /// Validate input data before processing
  ValidationFailure? _validateInput(AutomaticRegistrationCommand command) {
    final errors = <String, String>{};

    // Email validation
    if (command.email.trim().isEmpty) {
      errors['email'] = 'El email es requerido';
    }

    // Name validation
    if (command.firstName.trim().isEmpty) {
      errors['firstName'] = 'El nombre es requerido';
    } else if (command.firstName.trim().length < 2) {
      errors['firstName'] = 'El nombre debe tener al menos 2 caracteres';
    }

    if (command.lastName.trim().isEmpty) {
      errors['lastName'] = 'El apellido es requerido';
    }

    // Role validation
    final validRoles = ['owner', 'employee', 'client'];
    if (!validRoles.contains(command.role.toLowerCase())) {
      errors['role'] = 'Rol inválido. Debe ser: owner, employee, o client';
    }

    // Phone validation (if provided)
    if (command.phone != null && command.phone!.isNotEmpty) {
      if (!_isValidPhoneFormat(command.phone!)) {
        errors['phone'] = 'Formato de teléfono inválido';
      }
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(
        message: 'Error de validación: ${errors.values.first}',
        fieldErrors: errors,
      );
    }

    return null;
  }

  /// Generate a secure temporary password
  /// Format: 3 random words + 3 digits (e.g., "SunTigerMoon123")
  String _generateSecurePassword() {
    final random = Random.secure();
    
    // Word lists for memorable passwords
    const adjectives = [
      'Happy', 'Fast', 'Strong', 'Bright', 'Cool', 'Swift', 'Bold', 'Keen',
      'Wild', 'Free', 'Pure', 'True', 'Wise', 'Calm', 'Warm', 'Fresh',
    ];
    
    const nouns = [
      'Tiger', 'Eagle', 'Lion', 'Wolf', 'Bear', 'Hawk', 'Shark', 'Fox',
      'Star', 'Moon', 'Sun', 'Fire', 'Storm', 'Wave', 'Peak', 'River',
    ];

    final adj = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final digits = (random.nextInt(900) + 100).toString(); // 3 digits

    return '$adj$noun$digits';
  }

  /// Alternative: Generate completely random secure password
  String _generateRandomPassword({int length = 12}) {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Validate phone number format
  bool _isValidPhoneFormat(String phone) {
    // Basic validation: allows international format
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,20}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Notify relevant staff about new user registration
  Future<bool> _notifyRelevantStaff(User newUser, UserId? registeredBy) async {
    try {
      // If registered by an employee/owner, notify them specifically
      if (registeredBy != null) {
        await _notificationService.sendPushNotification(
          userId: registeredBy,
          title: '✅ Nuevo cliente registrado',
          body: '${newUser.displayName} ha sido registrado exitosamente',
          data: {
            'type': 'new_client',
            'userId': newUser.id.value,
          },
        );
        return true;
      }

      // Otherwise, notify via topic (all employees and owner)
      await _notificationService.sendToTopic(
        topic: NotificationTopics.allEmployees,
        title: '👋 Nuevo cliente',
        body: '${newUser.displayName} se ha unido al gimnasio',
        data: {
          'type': 'new_client',
          'userId': newUser.id.value,
        },
      );
      return true;
    } catch (e) {
      // Non-critical failure, log and continue
      return false;
    }
  }

  /// Subscribe user to appropriate FCM topics based on role
  Future<void> _subscribeToRoleTopics(User user) async {
    try {
      // Subscribe to general topic
      await _notificationService.subscribeToTopic(
        userId: user.id,
        topic: NotificationTopics.allUsers,
      );

      // Subscribe to role-specific topic
      await _notificationService.subscribeToTopic(
        userId: user.id,
        topic: NotificationTopics.forRole(user.role.type),
      );

      // Subscribe to announcements
      await _notificationService.subscribeToTopic(
        userId: user.id,
        topic: NotificationTopics.announcements,
      );
    } catch (e) {
      // Non-critical, continue even if subscription fails
    }
  }
}
