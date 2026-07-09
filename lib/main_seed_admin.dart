import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'firebase_options.dart';
import 'core/errors/failures.dart';
import 'src/domain/entities/entities.dart';
import 'src/domain/ports/output/auth_repository_port.dart';
import 'src/domain/value_objects/value_objects.dart';
import 'src/infrastructure/config/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  final adminConfig = await _loadAdminConfig();
  final authRepository = getIt<AuthRepositoryPort>();
  final credentials = AuthCredentials(
    email: Email(adminConfig.email),
    password: adminConfig.password,
  );

  try {
    final loginResult = await authRepository.login(credentials);

    final bool loginSucceeded = await loginResult.fold<Future<bool>>(
      (failure) async {
        if (failure is AuthFailure && failure.code == 'USER_NOT_FOUND') {
          final currentUser = fb.FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.email == adminConfig.email) {
            final repairedProfile = _buildAdminProfile(
              uid: currentUser.uid,
              email: Email(adminConfig.email),
              name: adminConfig.name,
            );
            final updateResult = await authRepository.updateProfile(repairedProfile);
            return updateResult.fold(
              (updateFailure) {
                stderr.writeln('No se pudo reparar el perfil admin: ${updateFailure.message}');
                return false;
              },
              (_) {
                stdout.writeln('Perfil admin reparado correctamente.');
                return true;
              },
            );
          }
        }

        final registerResult = await authRepository.register(
          email: Email(adminConfig.email),
          password: adminConfig.password,
          name: adminConfig.name,
          role: const GymRole.admin(),
          gymId: const GymId('admin-global'),
        );

        return registerResult.fold(
          (registerFailure) {
            if (registerFailure is AuthFailure && registerFailure.code == 'EMAIL_IN_USE') {
              stderr.writeln(
                'El correo admin ya existe en Firebase Auth con una contraseña diferente. Actualiza test-users.local.json o cambia la contraseña desde Firebase Auth.',
              );
            } else {
              stderr.writeln('No se pudo crear el admin: ${registerFailure.message}');
            }
            return false;
          },
          (authResult) async {
            final updateResult = await authRepository.updateProfile(
              _buildAdminProfile(
                uid: authResult.user.id.value,
                email: authResult.user.email,
                name: adminConfig.name,
                createdAt: authResult.user.createdAt,
                lastLoginAt: authResult.user.lastLoginAt,
              ),
            );
            return updateResult.fold(
              (updateFailure) {
                stderr.writeln('Admin creado, pero no se pudo consolidar el perfil: ${updateFailure.message}');
                return false;
              },
              (_) {
                stdout.writeln('Admin personal creado correctamente.');
                return true;
              },
            );
          },
        );
      },
      (authResult) async {
        final updateResult = await authRepository.updateProfile(
          _buildAdminProfile(
            uid: authResult.user.id.value,
            email: authResult.user.email,
            name: adminConfig.name,
            createdAt: authResult.user.createdAt,
            lastLoginAt: authResult.user.lastLoginAt,
          ),
        );

        return updateResult.fold(
          (updateFailure) {
            stderr.writeln('No se pudo asegurar el perfil admin: ${updateFailure.message}');
            return false;
          },
          (_) {
            stdout.writeln('Admin personal asegurado correctamente.');
            return true;
          },
        );
      },
    );

    await authRepository.logout();

    if (!loginSucceeded) {
      exit(1);
    }

    stdout.writeln('Email: ${adminConfig.email}');
    stdout.writeln('Password: ${adminConfig.password}');
    exit(0);
  } catch (error) {
    stderr.writeln('Seed admin falló: $error');
    try {
      await authRepository.logout();
    } catch (_) {}
    exit(1);
  }
}

Future<_SeedAdminConfig> _loadAdminConfig() async {
  final file = File('test-users.local.json');
  if (!await file.exists()) {
    throw Exception('No se encontró test-users.local.json en la raíz del proyecto.');
  }

  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('test-users.local.json tiene un formato inválido.');
  }

  final users = decoded['users'];
  if (users is! List) {
    throw Exception('test-users.local.json no contiene la lista users.');
  }

  final adminMap = users.cast<dynamic>().firstWhere(
    (user) => user is Map<String, dynamic> && user['key'] == 'admin',
    orElse: () => throw Exception('No se encontró el usuario admin en test-users.local.json.'),
  ) as Map<String, dynamic>;

  final email = adminMap['email']?.toString().trim() ?? '';
  final password = adminMap['password']?.toString() ?? '';
  final fullName = adminMap['name']?.toString() ?? '';

  if (email.isEmpty || password.isEmpty || fullName.trim().isEmpty) {
    throw Exception('El usuario admin en test-users.local.json está incompleto.');
  }

  return _SeedAdminConfig(
    email: email,
    password: password,
    name: _parseName(fullName),
  );
}

PersonName _parseName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    throw Exception('El nombre del admin es inválido.');
  }

  final firstName = parts.first;
  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  return PersonName(firstName: firstName, lastName: lastName);
}

User _buildAdminProfile({
  required String uid,
  required Email email,
  required PersonName name,
  DateTime? createdAt,
  DateTime? lastLoginAt,
}) {
  return User.restore(
    id: UserId(uid),
    email: email,
    name: name,
    role: const GymRole.admin(),
    gymId: const GymId('admin-global'),
    createdAt: createdAt ?? DateTime.now(),
    lastLoginAt: lastLoginAt,
    isActive: true,
    membershipStatus: MembershipStatus.approved,
  );
}

class _SeedAdminConfig {
  final String email;
  final String password;
  final PersonName name;

  const _SeedAdminConfig({
    required this.email,
    required this.password,
    required this.name,
  });
}
