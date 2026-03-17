import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/ports/output/gym_repository_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../mappers/mappers.dart';

/// Firebase implementation of GymRepositoryPort
class FirebaseGymRepository implements GymRepositoryPort {
  final FirebaseFirestore _firestore;

  static const String _gymsCollection = 'gyms';

  FirebaseGymRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _gymsRef =>
      _firestore.collection(_gymsCollection);

  @override
  FutureResult<GymId> save(Gym gym) async {
    try {
      await _gymsRef.doc(gym.id.value).set(GymMapper.toFirestore(gym));
      return right(gym.id);
    } catch (e) {
      return left(ServerFailure(message: 'Error al guardar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<Gym> findById(GymId id) async {
    try {
      final doc = await _gymsRef.doc(id.value).get();
      if (!doc.exists || doc.data() == null) {
        return left(const ServerFailure(message: 'Gimnasio no encontrado'));
      }
      return right(GymMapper.fromFirestore(doc.data()!, doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<void> update(Gym gym) async {
    try {
      await _gymsRef.doc(gym.id.value).update(GymMapper.toFirestore(gym));
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al actualizar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<List<Gym>> findAll() async {
    try {
      final snapshot = await _gymsRef.where('isActive', isEqualTo: true).get();
      final gyms = snapshot.docs
          .map((doc) => GymMapper.fromFirestore(doc.data(), doc.id))
          .toList();
      return right(gyms);
    } catch (e) {
      return left(ServerFailure(message: 'Error al listar gimnasios: $e'));
    }
  }

  @override
  FutureResult<void> deactivate(GymId id) async {
    try {
      await _gymsRef.doc(id.value).update({'isActive': false});
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: 'Error al desactivar el gimnasio: $e'));
    }
  }

  @override
  FutureResult<Map<String, dynamic>> getStats(GymId id) async {
    try {
      final doc = await _gymsRef
          .doc(id.value)
          .collection('stats')
          .doc('overview')
          .get();
      
      return right(doc.exists ? doc.data()! : {});
    } catch (e) {
      return left(ServerFailure(message: 'Error al obtener estadísticas: $e'));
    }
  }

  @override
  FutureResult<List<Map<String, dynamic>>> getDailyMetrics({
    required GymId id,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _gymsRef
          .doc(id.value)
          .collection('metrics')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();
      
      final metrics = snapshot.docs.map((doc) => doc.data()).toList();
      return right(metrics);
    } catch (e) {
      return left(ServerFailure(message: 'Error al obtener métricas diarias: $e'));
    }
  }

  @override
  Future<Gym?> getGym(String gymId) async {
    final result = await findById(GymId(gymId));
    return result.fold(
      (failure) => null,
      (gym) => gym,
    );
  }
  @override
  FutureResult<Gym> findByCode(GymCode code) async {
    try {
      final snapshot = await _gymsRef
          .where('code', isEqualTo: code.value)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return left(const ServerFailure(
          message: 'Gimnasio no encontrado con ese código',
        ));
      }

      final doc = snapshot.docs.first;
      return right(GymMapper.fromFirestore(doc.data(), doc.id));
    } catch (e) {
      return left(ServerFailure(message: 'Error al buscar gimnasio por código: $e'));
    }
  }
}
