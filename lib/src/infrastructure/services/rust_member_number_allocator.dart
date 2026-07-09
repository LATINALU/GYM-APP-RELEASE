import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;

import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import '../../domain/ports/output/member_number_allocator_port.dart';
import '../../domain/value_objects/value_objects.dart';

class RustMemberNumberAllocator implements MemberNumberAllocatorPort {
  /// URL del servicio, inyectada en build con
  /// `--dart-define=MEMBER_NUMBER_SERVICE_URL=...`.
  /// Vacía por defecto: el servicio queda deshabilitado (isEnabled == false).
  static const String _envBaseUrl =
      String.fromEnvironment('MEMBER_NUMBER_SERVICE_URL');

  final http.Client _httpClient;
  final fb.FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  RustMemberNumberAllocator({
    required http.Client httpClient,
    required fb.FirebaseAuth firebaseAuth,
    String? baseUrl,
  })  : _httpClient = httpClient,
        _firebaseAuth = firebaseAuth,
        _baseUrl = (baseUrl ?? _envBaseUrl).trim();

  @override
  bool get isEnabled => _baseUrl.isNotEmpty;

  @override
  FutureResult<AllocatedMemberNumber> allocate({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    String? idempotencyKey,
  }) async {
    if (!isEnabled) {
      return left(
        const ServerFailure(
          message: 'El servicio de memberNumber no está configurado.',
          code: 'MEMBER_NUMBER_SERVICE_DISABLED',
        ),
      );
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return left(
        const AuthFailure(
          message: 'No hay sesión autenticada para solicitar memberNumber.',
          code: 'AUTH_REQUIRED',
        ),
      );
    }

    try {
      final token = await currentUser.getIdToken();
      if (token == null || token.isEmpty) {
        return left(
          const AuthFailure(
            message: 'No se pudo obtener el token de Firebase para memberNumber.',
            code: 'TOKEN_UNAVAILABLE',
          ),
        );
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/internal/member-numbers/allocate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId.value,
          'gym_id': gymId.value,
          'role': role.name,
          'idempotency_key': idempotencyKey ?? '${gymId.value}:${userId.value}:$role',
        }),
      );

      final Map<String, dynamic> payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return left(
          ServerFailure(
            message: (payload['message'] as String?) ??
                'Error al asignar memberNumber.',
            code: (payload['code'] as String?) ?? 'MEMBER_NUMBER_SERVICE_ERROR',
          ),
        );
      }

      return right(
        AllocatedMemberNumber(
          memberNumber: payload['member_number'] as String,
          sequence: (payload['sequence'] as num).toInt(),
          gymId: GymId(payload['gym_id'] as String),
          format: payload['format'] as String? ?? 'G-{gym}-M-{sequence}',
          allocatedAt: DateTime.tryParse(payload['allocated_at'] as String? ?? '') ?? DateTime.now(),
        ),
      );
    } on http.ClientException {
      return left(const NetworkFailure());
    } on FormatException catch (e) {
      return left(
        ServerFailure(
          message: 'Respuesta inválida del servicio de memberNumber: $e',
          code: 'INVALID_MEMBER_NUMBER_RESPONSE',
        ),
      );
    } catch (e) {
      return left(
        ServerFailure(
          message: 'Error inesperado al asignar memberNumber: $e',
          code: 'MEMBER_NUMBER_ALLOCATION_FAILED',
        ),
      );
    }
  }
}

class DisabledMemberNumberAllocator implements MemberNumberAllocatorPort {
  const DisabledMemberNumberAllocator();

  @override
  bool get isEnabled => false;

  @override
  FutureResult<AllocatedMemberNumber> allocate({
    required UserId userId,
    required GymId gymId,
    required GymRoleType role,
    String? idempotencyKey,
  }) async {
    return left(
      const ServerFailure(
        message: 'El servicio Rust de memberNumber está deshabilitado.',
        code: 'MEMBER_NUMBER_SERVICE_DISABLED',
      ),
    );
  }
}
