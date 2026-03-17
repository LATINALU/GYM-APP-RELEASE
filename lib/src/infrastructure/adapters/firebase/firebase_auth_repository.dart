import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/auth_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of AuthRepositoryPort
class FirebaseAuthRepository implements AuthRepositoryPort {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  String? _claimAsString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value;
    return value.toString();
  }

  PersonName _personNameFromIdentity({
    required String email,
    String? displayName,
  }) {
    final normalizedDisplayName = displayName?.trim() ?? '';
    if (normalizedDisplayName.isNotEmpty) {
      final parts = normalizedDisplayName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return PersonName(
          firstName: parts.first,
          lastName: parts.skip(1).join(' '),
        );
      }
    }

    final fallbackParts = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    return PersonName(
      firstName: fallbackParts.isNotEmpty ? fallbackParts.first : 'Usuario',
      lastName: fallbackParts.length > 1 ? fallbackParts.skip(1).join(' ') : '',
    );
  }

  Future<GymId?> _resolveGymIdFromCode(GymCode? gymCode) async {
    if (gymCode == null) return null;

    final snapshot = await _firestore
        .collection('gyms')
        .where('code', isEqualTo: gymCode.value)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return GymId(snapshot.docs.first.id);
  }

  Future<({User? user, String token})> _resolveCurrentUser(
    fb.User firebaseUser, {
    bool forceRefreshToken = false,
  }) async {
    final idTokenResult = await firebaseUser.getIdTokenResult(forceRefreshToken);
    final token = idTokenResult.token ?? '';
    var gymId = _claimAsString(idTokenResult.claims?['gymId']);
    var role = _claimAsString(idTokenResult.claims?['role']);

    Map<String, dynamic>? userData;

    if (gymId != null && role != null && role != GymRoleType.admin.name) {
      final userDoc = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('${role}s')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        userData = userDoc.data();
      }
    }

    if (userData == null) {
      final rootDoc = await _usersRef.doc(firebaseUser.uid).get();
      if (rootDoc.exists && rootDoc.data() != null) {
        final rootData = rootDoc.data()!;
        userData = rootData;
        gymId ??= rootData['gymId']?.toString();
        role ??= _claimAsString(rootData['role']);
      }
    }

    if (userData == null) {
      return (user: null, token: token);
    }

    return (
      user: UserMapper.fromFirestore(userData, firebaseUser.uid),
      token: token,
    );
  }

  Future<void> _syncUserRootProfile(
    User user, {
    String? photoUrl,
  }) async {
    await _usersRef.doc(user.id.value).set({
      ...UserMapper.toFirestore(user),
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> _syncUserNestedProfile(User user) async {
    if (user.role.type == GymRoleType.admin) {
      return;
    }

    final nestedRef = _firestore
        .collection('gyms')
        .doc(user.gymId.value)
        .collection('${user.role.type.name}s')
        .doc(user.id.value);

    final nestedDoc = await nestedRef.get();
    if (nestedDoc.exists) {
      await nestedRef.set(UserMapper.toFirestore(user), SetOptions(merge: true));
    }
  }

  @override
  FutureResult<AuthResult> login(AuthCredentials credentials) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: credentials.email.value,
        password: credentials.password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return left(AuthFailure.invalidCredentials());
      }

      final resolved = await _resolveCurrentUser(
        firebaseUser,
        forceRefreshToken: true,
      );
      final user = resolved.user;
      if (user == null) {
        return left(AuthFailure.userNotFound());
      }

      final loggedInUser = user.recordLogin();
      await _syncUserNestedProfile(loggedInUser);
      await _syncUserRootProfile(
        loggedInUser,
        photoUrl: firebaseUser.photoURL,
      );

      return right(
        AuthResult(user: loggedInUser, token: resolved.token),
      );
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(message: 'Error de Firebase: ${e.message}', code: e.code),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> register({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    GymId? gymId,
    double? weight,
    double? height,
    String? fitnessGoal,
  }) async {
    final effectiveGymId = gymId ?? const GymId('orphan-gym');
    try {
      // 1. Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.value,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        return left(
          const ServerFailure(
            message: 'Error al crear cuenta en Firebase Auth',
          ),
        );
      }

      await userCredential.user?.updateDisplayName(name.fullName);

      final user = User.create(
        email: email,
        name: name,
        role: role,
        gymId: effectiveGymId,
        weight: weight,
        height: height,
        fitnessGoal: fitnessGoal,
      );

      // Reconstitute with Firebase UID
      final userWithFirebaseId = User.restore(
        id: UserId(uid),
        email: user.email,
        name: user.name,
        role: user.role,
        gymId: user.gymId,
        phone: user.phone,
        createdAt: user.createdAt,
        isActive: true,
        membershipStatus: user.membershipStatus,
        weight: user.weight,
        height: user.height,
        fitnessGoal: user.fitnessGoal,
        membershipExpiresAt: user.membershipExpiresAt,
        memberNumber: user.memberNumber,
        memberNumberAssignedAt: user.memberNumberAssignedAt,
      );

      await _syncUserRootProfile(userWithFirebaseId);

      final token = await userCredential.user!.getIdToken() ?? '';

      return right(AuthResult(user: userWithFirebaseId, token: token));
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(message: 'Error de Firebase: ${e.message}', code: e.code),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> signInWithGoogle({
    GymCode? gymCode,
  }) async {
    try {
      final provider = fb.GoogleAuthProvider();
      provider.addScope('email');
      provider.setCustomParameters({'prompt': 'select_account'});

      final userCredential = kIsWeb
          ? await _firebaseAuth.signInWithPopup(provider)
          : await _firebaseAuth.signInWithProvider(provider);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null || firebaseUser.email == null) {
        return left(const AuthFailure(message: 'No se pudo completar el acceso con Google'));
      }

      final resolved = await _resolveCurrentUser(
        firebaseUser,
        forceRefreshToken: true,
      );

      User user;
      if (resolved.user != null) {
        user = resolved.user!;
      } else {
        final resolvedGymId = await _resolveGymIdFromCode(gymCode);
        if (gymCode != null && resolvedGymId == null) {
          return left(const ServerFailure(
            message: 'Gimnasio no encontrado con ese código',
          ));
        }

        final name = _personNameFromIdentity(
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName,
        );

        final baseUser = User.create(
          email: Email(firebaseUser.email!),
          name: name,
          role: const GymRole.client(),
          gymId: resolvedGymId ?? const GymId('orphan-gym'),
        );

        user = User.restore(
          id: UserId(firebaseUser.uid),
          email: baseUser.email,
          name: baseUser.name,
          role: baseUser.role,
          gymId: baseUser.gymId,
          phone: baseUser.phone,
          createdAt: baseUser.createdAt,
          isActive: true,
          membershipStatus: baseUser.membershipStatus,
          weight: baseUser.weight,
          height: baseUser.height,
          fitnessGoal: baseUser.fitnessGoal,
          membershipExpiresAt: baseUser.membershipExpiresAt,
          memberNumber: baseUser.memberNumber,
          memberNumberAssignedAt: baseUser.memberNumberAssignedAt,
        );
      }

      final loggedInUser = user.recordLogin();
      await _syncUserNestedProfile(loggedInUser);
      await _syncUserRootProfile(
        loggedInUser,
        photoUrl: firebaseUser.photoURL,
      );

      return right(
        AuthResult(user: loggedInUser, token: resolved.token),
      );
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(message: 'Error de Firebase: ${e.message}', code: e.code),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<AuthResult> provisionUser({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    required GymId gymId,
    PhoneNumber? phone,
  }) async {
    FirebaseApp? secondaryApp;
    fb.FirebaseAuth? secondaryAuth;
    fb.User? provisionedUser;
    var profilePersisted = false;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'admin-provision-${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      secondaryAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.value,
        password: password,
      );

      provisionedUser = userCredential.user;
      if (provisionedUser == null) {
        return left(
          const ServerFailure(
            message: 'Error al crear cuenta en Firebase Auth',
          ),
        );
      }

      await provisionedUser.updateDisplayName(name.fullName);

      final baseUser = User.create(
        email: email,
        name: name,
        role: role,
        gymId: gymId,
        phone: phone,
      );

      final persistedUser = User.restore(
        id: UserId(provisionedUser.uid),
        email: baseUser.email,
        name: baseUser.name,
        role: baseUser.role,
        gymId: baseUser.gymId,
        phone: baseUser.phone,
        createdAt: baseUser.createdAt,
        isActive: true,
        membershipStatus: baseUser.membershipStatus,
        weight: baseUser.weight,
        height: baseUser.height,
        fitnessGoal: baseUser.fitnessGoal,
        membershipExpiresAt: baseUser.membershipExpiresAt,
        memberNumber: baseUser.memberNumber,
        memberNumberAssignedAt: baseUser.memberNumberAssignedAt,
      );

      await _firestore
          .collection('gyms')
          .doc(gymId.value)
          .collection('${role.type.name}s')
          .doc(persistedUser.id.value)
          .set(UserMapper.toFirestore(persistedUser));

      await _syncUserRootProfile(persistedUser);
      profilePersisted = true;

      final token = await provisionedUser.getIdToken() ?? '';
      return right(AuthResult(user: persistedUser, token: token));
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(message: 'Error de Firebase: ${e.message}', code: e.code),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    } finally {
      if (!profilePersisted && provisionedUser != null) {
        try {
          await provisionedUser.delete();
        } catch (_) {}
      }
      try {
        await secondaryAuth?.signOut();
      } catch (_) {}
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  @override
  FutureVoidResult logout() async {
    try {
      await _firebaseAuth.signOut();
      return right(null);
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: 'Error al cerrar sesión: ${e.message}',
          code: e.code,
        ),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return right(null);
      }

      final resolved = await _resolveCurrentUser(firebaseUser);
      return right(resolved.user);
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: 'Error de base de datos: ${e.message}',
          code: e.code,
        ),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  FutureVoidResult sendPasswordReset(Email email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.value);
      return right(null);
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error al enviar email: $e'));
    }
  }

  @override
  FutureVoidResult changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        return left(const AuthFailure(message: 'No hay sesión activa'));
      }

      // Re-authenticate first
      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
      return right(null);
    } on fb.FirebaseAuthException catch (e) {
      return left(_mapFirebaseAuthError(e));
    } catch (e) {
      return left(ServerFailure(message: 'Error al cambiar contraseña: $e'));
    }
  }

  @override
  FutureVoidResult updateProfile(User user) async {
    try {
      if (user.role.type != GymRoleType.admin) {
        await _firestore
            .collection('gyms')
            .doc(user.gymId.value)
            .collection('${user.role.type.name}s')
            .doc(user.id.value)
            .set(UserMapper.toFirestore(user), SetOptions(merge: true));
      }

      await _syncUserRootProfile(user);

      return right(null);
    } on fb.FirebaseException catch (e) {
      return left(
        ServerFailure(
          message: 'Error de actualización: ${e.message}',
          code: e.code,
        ),
      );
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        final resolved = await _resolveCurrentUser(firebaseUser);
        return resolved.user;
      } catch (e) {
        return null;
      }
    });
  }

  AuthFailure _mapFirebaseAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure(message: 'Correo electrónico inválido');
      case 'user-disabled':
        return const AuthFailure(message: 'Usuario deshabilitado');
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'operation-not-allowed':
        return const AuthFailure(message: 'Operación no permitida');
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Demasiados intentos. Intenta más tarde.',
        );
      default:
        return AuthFailure(message: 'Error de autenticación: ${e.message}');
    }
  }
}
