import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/entities/pending_registration.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/ports/output/pending_registration_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of PendingRegistrationRepositoryPort
class InsForgePendingRegistrationRepository implements PendingRegistrationRepositoryPort {
  final InsForgeClient _client;

  InsForgePendingRegistrationRepository(this._client);

  @override
  FutureVoidResult save(PendingRegistration registration) async {
    try {
      final response = await _client.insert('pending_registrations', _toMap(registration));
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error guardando registro'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<PendingRegistration> findById(String registrationId) async {
    try {
      final response = await _client.from('pending_registrations', query: 'id=eq.$registrationId&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const Left(NotFoundFailure(message: 'Registro no encontrado'));
      }
      return Right(_map(response.firstItem!));
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByGymId(GymId gymId) async {
    try {
      final response = await _client.from('pending_registrations',
          query: 'target_gym_id=eq.${gymId.value}&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findByUserId(UserId userId) async {
    try {
      final response = await _client.from('pending_registrations',
          query: 'user_id=eq.${userId.value}&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findUnassigned() async {
    try {
      final response = await _client.from('pending_registrations',
          query: 'target_gym_id=is.null&status=eq.pending_review&select=*&order=created_at.desc');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult update(PendingRegistration registration) async {
    try {
      final response = await _client.update('pending_registrations', _toMap(registration), 'id=eq.${registration.id}');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureVoidResult delete(String registrationId) async {
    try {
      final response = await _client.delete('pending_registrations', 'id=eq.$registrationId');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  Stream<List<PendingRegistration>> watchByGymId(GymId gymId) {
    // PostgREST doesn't support real-time streams natively.
    // Implement polling as a fallback. In production, use InsForge's
    // real-time subscriptions or WebSocket channels.
    final controller = StreamController<List<PendingRegistration>>();

    Future<void> poll() async {
      while (!controller.isClosed) {
        final result = await findByGymId(gymId);
        result.fold(
          (failure) => controller.addError(failure),
          (registrations) => controller.add(registrations.where((r) => r.status == RegistrationStatus.pendingReview).toList()),
        );
        await Future.delayed(const Duration(seconds: 10));
      }
    }

    poll();
    return controller.stream;
  }

  @override
  Future<int> countPendingByGymId(GymId gymId) async {
    try {
      final response = await _client.from('pending_registrations',
          query: 'target_gym_id=eq.${gymId.value}&status=eq.pending_review&select=id');
      return response.dataList.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  FutureResult<List<PendingRegistration>> findExpired() async {
    try {
      final response = await _client.from('pending_registrations',
          query: 'status=eq.pending_review&expires_at=lt.${DateTime.now().toIso8601String()}&select=*');
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  @override
  FutureResult<List<PendingRegistration>> search({required String query, GymId? gymId}) async {
    try {
      String q = 'or=(user_name.ilike.*$query*,user_email.ilike.*$query*)&select=*&order=created_at.desc';
      if (gymId != null) {
        q = 'target_gym_id=eq.${gymId.value}&$q';
      }
      final response = await _client.from('pending_registrations', query: q);
      if (!response.isSuccess) return Left(ServerFailure(message: response.error ?? 'Error'));
      return Right(response.dataList.map((e) => _map(e as Map<String, dynamic>)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAPPERS
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> _toMap(PendingRegistration r) {
    return {
      'id': r.id,
      'user_id': r.userId,
      'user_email': r.userEmail,
      'user_name': r.userName,
      'user_phone': r.userPhone,
      'user_photo_url': r.userPhotoUrl,
      'target_gym_id': r.targetGymId,
      'target_gym_name': r.targetGymName,
      'target_gym_code': r.targetGymCode,
      'access_code_used': r.accessCodeUsed,
      'status': _statusToDb(r.status),
      'source': _sourceToDb(r.source),
      'message': r.message,
      'fitness_goal': r.fitnessGoal,
      'weight': r.weight,
      'height': r.height,
      'reviewed_by': r.reviewedBy,
      'reviewed_at': r.reviewedAt?.toIso8601String(),
      'rejection_reason': r.rejectionReason,
      'expires_at': r.expiresAt?.toIso8601String(),
      'metadata': r.metadata ?? {},
    };
  }

  PendingRegistration _map(Map<String, dynamic> data) {
    return PendingRegistration.restore(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      userEmail: data['user_email'] as String,
      userName: data['user_name'] as String,
      userPhone: data['user_phone'] as String?,
      userPhotoUrl: data['user_photo_url'] as String?,
      targetGymId: data['target_gym_id'] as String?,
      targetGymName: data['target_gym_name'] as String?,
      targetGymCode: data['target_gym_code'] as String?,
      accessCodeUsed: data['access_code_used'] as String?,
      status: _parseStatus(data['status'] as String? ?? 'pending_review'),
      source: _parseSource(data['source'] as String? ?? 'manual_code'),
      message: data['message'] as String?,
      fitnessGoal: data['fitness_goal'] as String?,
      weight: (data['weight'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      reviewedBy: data['reviewed_by'] as String?,
      reviewedAt: data['reviewed_at'] != null ? DateTime.tryParse(data['reviewed_at'] as String) : null,
      rejectionReason: data['rejection_reason'] as String?,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: data['expires_at'] != null ? DateTime.tryParse(data['expires_at'] as String) : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  String _statusToDb(RegistrationStatus s) {
    switch (s) {
      case RegistrationStatus.pendingReview: return 'pending_review';
      case RegistrationStatus.approved: return 'approved';
      case RegistrationStatus.rejected: return 'rejected';
      case RegistrationStatus.expired: return 'expired';
      case RegistrationStatus.cancelled: return 'cancelled';
    }
  }

  String _sourceToDb(RegistrationSource s) {
    switch (s) {
      case RegistrationSource.qrScan: return 'qr_scan';
      case RegistrationSource.manualCode: return 'manual_code';
      case RegistrationSource.invitation: return 'invitation';
      case RegistrationSource.appSearch: return 'app_search';
      case RegistrationSource.transfer: return 'transfer';
    }
  }

  RegistrationStatus _parseStatus(String v) {
    switch (v) {
      case 'approved': return RegistrationStatus.approved;
      case 'rejected': return RegistrationStatus.rejected;
      case 'expired': return RegistrationStatus.expired;
      case 'cancelled': return RegistrationStatus.cancelled;
      default: return RegistrationStatus.pendingReview;
    }
  }

  RegistrationSource _parseSource(String v) {
    switch (v) {
      case 'qr_scan': return RegistrationSource.qrScan;
      case 'invitation': return RegistrationSource.invitation;
      case 'app_search': return RegistrationSource.appSearch;
      case 'transfer': return RegistrationSource.transfer;
      default: return RegistrationSource.manualCode;
    }
  }
}
