import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of UserRepositoryPort
class FirebaseUserRepository implements UserRepositoryPort {
  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  FirebaseUserRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_collection);

  @override
  FutureResult<User> findById({required UserId id, required GymId gymId, required GymRoleType role}) async {
    try {
      final collectionName = '${role.name}s';
      final doc = await _firestore
          .collection('gyms')
          .doc(gymId.value)
          .collection(collectionName)
          .doc(id.value)
          .get();

      if (!doc.exists || doc.data() == null) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }
      return right(UserMapper.fromFirestore(doc.data()!, doc.id));
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error de base de datos: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User> findByIdGlobal(UserId id) async {
    try {
      // Use the global /users index for lookup
      final doc = await _usersRef.doc(id.value).get();

      if (!doc.exists || doc.data() == null) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }
      return right(UserMapper.fromFirestore(doc.data()!, doc.id));
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error de consulta global: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<User> findByEmail(Email email) async {
    try {
      // Use the root collection for global lookup
      final query = await _usersRef
          .where('email', isEqualTo: email.value)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return left(const ServerFailure(
          message: 'Usuario no encontrado',
          code: 'USER_NOT_FOUND',
        ));
      }

      final doc = query.docs.first;
      return right(UserMapper.fromFirestore(doc.data(), doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar usuario por email: $e'));
    }
  }

  @override
  FutureResult<List<User>> findByRole({required GymId gymId, required GymRole role}) async {
    try {
      final collectionName = '${role.type.name}s';
      final query = await _firestore
          .collection('gyms')
          .doc(gymId.value)
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final users = query.docs
          .map((doc) => UserMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(users);
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error al filtrar usuarios: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<List<User>> findAllActive(GymId gymId) async {
    try {
      // In a multi-tenant nested structure, we would need to query all 3 sub-collections
      // owners, employees, clients and merge them (or use collection group if indexed)
      
      final roles = ['owners', 'employees', 'clients'];
      final allUsers = <User>[];
      
      for (final roleColl in roles) {
        final query = await _firestore
            .collection('gyms')
            .doc(gymId.value)
            .collection(roleColl)
            .where('isActive', isEqualTo: true)
            .get();
            
        allUsers.addAll(query.docs.map((doc) => UserMapper.fromFirestore(doc.data(), doc.id)));
      }

      return right(allUsers);
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar usuarios activos: $e'));
    }
  }

  @override
  FutureVoidResult save(User user) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Save to nested collection (Primary data - GYM-APP style)
      final collectionName = '${user.role.type.name}s';
      final nestedRef = _firestore
          .collection('gyms')
          .doc(user.gymId.value)
          .collection(collectionName)
          .doc(user.id.value);
          
      final userData = UserMapper.toFirestore(user);
      batch.set(nestedRef, userData, SetOptions(merge: true));
      
      // 2. Save to root collection (Index for lookup - GYM-APP style)
      final rootRef = _usersRef.doc(user.id.value);
      batch.set(rootRef, userData, SetOptions(merge: true));

      // 3. Save to LEGACY root collection (GYM-APP style)
      // GYM-APP uses 'user' collection with IDs like Firebase Auth UIDs
      final legacyRef = _firestore.collection('user').doc(user.id.value);
      batch.set(legacyRef, {
        'FirstName': user.name.firstName,
        'LastName': user.name.lastName,
        'Email': user.email.value,
        'Age': '', // Placeholder
        'ProfilePic': '', // Placeholder
      }, SetOptions(merge: true));
      
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error al persistir cambios: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureVoidResult delete({required UserId id, required GymId gymId, required GymRoleType role}) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Delete from nested
      final collectionName = '${role.name}s';
      batch.delete(_firestore
          .collection('gyms')
          .doc(gymId.value)
          .collection(collectionName)
          .doc(id.value));
          
      // 2. Delete from root
      batch.delete(_usersRef.doc(id.value));
      
      await batch.commit();
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al eliminar usuario: $e'));
    }
  }

  @override
  Future<bool> existsByEmail(Email email) async {
    try {
      final query = await _usersRef
          .where('email', isEqualTo: email.value)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  FutureResult<List<User>> searchByName({required String query, required GymId gymId}) async {
    try {
      // Simplified: search in all 3 sub-collections for this gym
      final normalizedQuery = query.toLowerCase().trim();
      final roles = ['owners', 'employees', 'clients'];
      final results = <User>[];
      
      for (final roleColl in roles) {
        final snapshot = await _firestore
            .collection('gyms')
            .doc(gymId.value)
            .collection(roleColl)
            .where('isActive', isEqualTo: true)
            .get();
            
        results.addAll(snapshot.docs
            .map((doc) => UserMapper.fromFirestore(doc.data(), doc.id))
            .where((user) =>
                user.name.firstName.toLowerCase().contains(normalizedQuery) ||
                user.name.lastName.toLowerCase().contains(normalizedQuery)));
      }

      return right(results);
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error en búsqueda: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  FutureResult<List<User>> findPendingUsers(GymId gymId) async {
    try {
      // In our architecture, clients usually have the pending status
      final query = await _firestore
          .collection('gyms')
          .doc(gymId.value)
          .collection('clients')
          .where('membershipStatus', isEqualTo: 'pending')
          .get();

      final users = query.docs
          .map((doc) => UserMapper.fromFirestore(doc.data(), doc.id))
          .toList();

      return right(users);
    } on FirebaseException catch (e) {
      return left(ServerFailure(
        message: 'Error de sincronización: ${e.message}',
        code: e.code,
      ));
    } catch (e) {
      return left(ServerFailure(message: 'Error inesperado: $e'));
    }
  }
}
