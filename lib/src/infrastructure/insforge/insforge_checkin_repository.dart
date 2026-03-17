import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/check_in_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of CheckInRepositoryPort
class InsForgeCheckInRepository implements CheckInRepositoryPort {
  final InsForgeClient _client;

  InsForgeCheckInRepository(this._client);

  @override
  FutureResult<CheckIn> findById(CheckInId id) async {
    try {
      final response = await _client.from('check_ins', query: 'id=eq.${id.value}&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Check-in no encontrado'));
      }
      return Right(_map(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByClient(UserId clientId) async {
    try {
      final response = await _client.from('check_ins',
          query: 'client_id=eq.${clientId.value}&select=*&order=check_in_time.desc&limit=50');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByDateRange({required DateTime startDate, required DateTime endDate}) async {
    try {
      final response = await _client.from('check_ins',
          query: 'check_in_time=gte.${startDate.toIso8601String()}&check_in_time=lte.${endDate.toIso8601String()}&select=*&order=check_in_time.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findByClientAndDateRange({required UserId clientId, required DateTime startDate, required DateTime endDate}) async {
    try {
      final response = await _client.from('check_ins',
          query: 'client_id=eq.${clientId.value}&check_in_time=gte.${startDate.toIso8601String()}&check_in_time=lte.${endDate.toIso8601String()}&select=*&order=check_in_time.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<CheckIn>> findToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return findByDateRange(startDate: start, endDate: today);
  }

  @override
  FutureVoidResult save(CheckIn checkIn) async {
    try {
      final response = await _client.insert('check_ins', {
        'id': checkIn.id.value,
        'client_id': checkIn.clientId.value,
        'check_in_time': checkIn.checkInTime.toIso8601String(),
        'check_out_time': checkIn.checkOutTime?.toIso8601String(),
        'registered_by': checkIn.registeredById?.value,
        'notes': checkIn.notes,
      });
      if (!response.isSuccess) {
        if (response.isConflict) {
          // Update existing
          await _client.update('check_ins', {
            'check_out_time': checkIn.checkOutTime?.toIso8601String(),
            'notes': checkIn.notes,
          }, 'id=eq.${checkIn.id.value}');
        } else {
          return Left(ServerFailure(message: response.error ?? 'Error guardando check-in'));
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<CheckIn?> findActiveByClient(UserId clientId) async {
    try {
      final response = await _client.from('check_ins',
          query: 'client_id=eq.${clientId.value}&check_out_time=is.null&select=*&order=check_in_time.desc&limit=1');
      if (!response.isSuccess || response.dataList.isEmpty) return const Right(null);
      return Right(_map(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  Future<int> countByClientAndPeriod({required UserId clientId, required DateTime startDate, required DateTime endDate}) async {
    try {
      final response = await _client.from('check_ins',
          query: 'client_id=eq.${clientId.value}&check_in_time=gte.${startDate.toIso8601String()}&check_in_time=lte.${endDate.toIso8601String()}&select=id');
      return response.dataList.length;
    } catch (e) {
      return 0;
    }
  }

  CheckIn _map(Map<String, dynamic> data) {
    return CheckIn.restore(
      id: CheckInId(data['id'] as String),
      clientId: UserId(data['client_id'] as String),
      checkInTime: DateTime.parse(data['check_in_time'] as String),
      checkOutTime: data['check_out_time'] != null ? DateTime.parse(data['check_out_time'] as String) : null,
      registeredById: data['registered_by'] != null ? UserId(data['registered_by'] as String) : null,
      notes: data['notes'] as String?,
    );
  }
}
