import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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

      // 1. Get custom claims from token to find the user in the nested structure
      final idTokenResult = await firebaseUser.getIdTokenResult(
        true,
      ); // force refresh to get latest claims
      final gymId = idTokenResult.claims?['gymId'] as String?;
      final role = idTokenResult.claims?['role'] as String?;

      if (gymId == null || role == null) {
        // Fallback or Error: if claims are missing, we might have a global users collection or it's a new user
        // For this architecture, claims are required.
        return left(
          const ServerFailure(
            message: 'Sesión inválida: Faltan permisos de gimnasio (claims)',
          ),
        );
      }

      // 2. Get user data from nested Firestore path: gyms/{gymId}/{role}s/{uid}
      final collectionName = '${role}s';
      final userDoc =
          await _firestore
              .collection('gyms')
              .doc(gymId)
              .collection(collectionName)
              .doc(firebaseUser.uid)
              .get();

      if (!userDoc.exists || userDoc.data() == null) {
        return left(AuthFailure.userNotFound());
      }

      final user = UserMapper.fromFirestore(userDoc.data()!, userDoc.id);

      // 3. Update last login
      final nowIso = DateTime.now().toIso8601String();
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection(collectionName)
          .doc(user.id.value)
          .update({'lastLoginAt': nowIso});

      // Keep global users index in sync
      await _usersRef.doc(user.id.value).set({
        ...UserMapper.toFirestore(user),
        'lastLoginAt': nowIso,
        'gymId': gymId,
        'role': role,
      }, SetOptions(merge: true));

      return right(
        AuthResult(user: user.recordLogin(), token: idTokenResult.token ?? ''),
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

      // 2. Create domain user
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
      );

      // 3. Save to Firestore nested collection: gyms/{gymId}/{role}s/{uid}
      // Note: role.toValue().toLowerCase() + 's' produces owners, employees, clients
      final collectionName = '${role.type.name}s';

      // If orphan, maybe save in a different path? For now sticking to gym structure
      // But ideally: if effectiveGymId == orphan, save in /users or /pending_users

      await _firestore
          .collection('gyms')
          .doc(effectiveGymId.value)
          .collection(collectionName)
          .doc(uid)
          .set(UserMapper.toFirestore(userWithFirebaseId));

      // 3b. Save to global users index
      await _usersRef
          .doc(uid)
          .set(
            UserMapper.toFirestore(userWithFirebaseId),
            SetOptions(merge: true),
          );

      // 4. Get token
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

      final idTokenResult = await firebaseUser.getIdTokenResult();
      final gymId = idTokenResult.claims?['gymId'] as String?;
      final role = idTokenResult.claims?['role'] as String?;

      if (gymId == null || role == null) return right(null);

      final userDoc =
          await _firestore
              .collection('gyms')
              .doc(gymId)
              .collection('${role}s')
              .doc(firebaseUser.uid)
              .get();

      if (!userDoc.exists || userDoc.data() == null) {
        return right(null);
      }

      return right(UserMapper.fromFirestore(userDoc.data()!, userDoc.id));
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
      await _firestore
          .collection('gyms')
          .doc(user.gymId.value)
          .collection('${user.role.type.name}s')
          .doc(user.id.value)
          .update(UserMapper.toFirestore(user));

      await _usersRef
          .doc(user.id.value)
          .set(UserMapper.toFirestore(user), SetOptions(merge: true));

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
        final idTokenResult = await firebaseUser.getIdTokenResult();
        final gymId = idTokenResult.claims?['gymId'] as String?;
        final role = idTokenResult.claims?['role'] as String?;

        if (gymId == null || role == null) return null;

        final userDoc =
            await _firestore
                .collection('gyms')
                .doc(gymId)
                .collection('${role}s')
                .doc(firebaseUser.uid)
                .get();

        if (!userDoc.exists || userDoc.data() == null) {
          return null;
        }
        return UserMapper.fromFirestore(userDoc.data()!, userDoc.id);
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
