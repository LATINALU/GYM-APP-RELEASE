import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';
import '../../../core/types/typedefs.dart';
import 'insforge_client.dart';

/// InsForge Storage Service
/// Handles file uploads (exercise images, gym logos, user photos)
/// Uses InsForge's S3-compatible storage or local filesystem fallback
class InsForgeStorageService {
  final InsForgeClient _client;

  InsForgeStorageService(this._client);

  /// Upload an image file and return its public URL
  /// [bucket] - storage bucket (e.g., 'exercises', 'gyms', 'users')
  /// [path] - file path within bucket (e.g., 'global/bench-press.png')
  /// [bytes] - file content
  /// [contentType] - MIME type (e.g., 'image/png')
  FutureResult<String> uploadImage({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/png',
  }) async {
    try {
      final response = await _client.uploadFile(bucket, path, bytes, contentType);

      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error subiendo imagen'));
      }

      // Return the public URL
      final url = _client.getFileUrl(bucket, path);
      return Right(url);
    } catch (e) {
      debugPrint('[InsForgeStorage] Upload error: $e');
      return Left(ServerFailure(message: 'Error subiendo archivo: $e'));
    }
  }

  /// Upload exercise image (Admin global or Owner gym-specific)
  FutureResult<String> uploadExerciseImage({
    required String exerciseId,
    required Uint8List bytes,
    required String filename,
    bool isGlobal = false,
    String? gymId,
  }) async {
    final bucket = 'gym-app';
    final prefix = isGlobal ? 'exercises/global' : 'exercises/gym/$gymId';
    final path = '$prefix/$exerciseId/$filename';
    return uploadImage(bucket: bucket, path: path, bytes: bytes);
  }

  /// Upload gym logo
  FutureResult<String> uploadGymLogo({
    required String gymId,
    required Uint8List bytes,
    required String filename,
  }) async {
    return uploadImage(
      bucket: 'gym-app',
      path: 'gyms/$gymId/logo/$filename',
      bytes: bytes,
    );
  }

  /// Upload gym cover photo
  FutureResult<String> uploadGymCover({
    required String gymId,
    required Uint8List bytes,
    required String filename,
  }) async {
    return uploadImage(
      bucket: 'gym-app',
      path: 'gyms/$gymId/cover/$filename',
      bytes: bytes,
    );
  }

  /// Upload user profile photo
  FutureResult<String> uploadUserPhoto({
    required String userId,
    required Uint8List bytes,
    required String filename,
  }) async {
    return uploadImage(
      bucket: 'gym-app',
      path: 'users/$userId/photo/$filename',
      bytes: bytes,
    );
  }

  /// Delete a file
  FutureVoidResult deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final response = await _client.deleteFile(bucket, path);
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error eliminando archivo'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error eliminando archivo: $e'));
    }
  }

  /// Get public URL for a stored file
  String getPublicUrl(String bucket, String path) {
    return _client.getFileUrl(bucket, path);
  }

  /// Save file metadata to the storage_files table
  FutureVoidResult saveFileMetadata({
    required String bucket,
    required String path,
    required String filename,
    required String contentType,
    required int sizeBytes,
    String? uploadedBy,
    String? gymId,
  }) async {
    try {
      final response = await _client.insert('storage_files', {
        'bucket': bucket,
        'path': path,
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
        'uploaded_by': uploadedBy,
        'gym_id': gymId,
      });
      if (!response.isSuccess) {
        return Left(ServerFailure(message: response.error ?? 'Error guardando metadata'));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Error de conexión: $e'));
    }
  }
}
