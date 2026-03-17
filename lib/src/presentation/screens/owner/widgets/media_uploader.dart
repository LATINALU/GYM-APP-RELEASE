import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/auth/auth_state_notifier.dart';
import '../../../../infrastructure/insforge/insforge_service_locator.dart';

class ExerciseMediaUploader extends StatefulWidget {
  final String exerciseId;
  final Function(String imageUrl, String? animUrl) onUploadComplete;

  const ExerciseMediaUploader({
    super.key,
    required this.exerciseId,
    required this.onUploadComplete,
  });

  @override
  State<ExerciseMediaUploader> createState() => _ExerciseMediaUploaderState();
}

class _ExerciseMediaUploaderState extends State<ExerciseMediaUploader> {
  bool _isDragging = false;
  bool _isUploading = false;

  Future<void> _processFile({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    setState(() => _isUploading = true);

    try {
      final extension = p.extension(fileName).toLowerCase();
      final isAnim =
          extension == '.gif' ||
          extension == '.mp4' ||
          extension == '.mov' ||
          extension == '.webm';

      Uint8List? bytes = fileBytes;
      if (bytes == null && !kIsWeb && filePath != null && filePath.isNotEmpty) {
        bytes = await File(filePath).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No se pudo leer el archivo seleccionado.');
      }

      final gymId = AuthStateNotifier.instance.profile?.gymId?.value;
      if (gymId == null || gymId.isEmpty) {
        throw Exception('No se encontró gymId activo para subir el archivo.');
      }

      final uploadResult = await InsForgeServiceLocator.instance.storageService
          .uploadExerciseImage(
            exerciseId: widget.exerciseId,
            bytes: bytes,
            filename: fileName,
            isGlobal: false,
            gymId: gymId,
          );

      final uploadedUrl = uploadResult.fold(
        (failure) => throw Exception(failure.message),
        (url) => url,
      );

      widget.onUploadComplete(
        isAnim ? '' : uploadedUrl,
        isAnim ? uploadedUrl : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo "$fileName" subido con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de seguridad/red: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          _processFile(fileName: file.name, filePath: file.path);
        }
      },
      child: InkWell(
        onTap:
            _isUploading
                ? null
                : () async {
                  final result = await FilePicker.platform.pickFiles(
                    withData: true,
                    allowMultiple: false,
                  );

                  if (result != null && result.files.single.path != null) {
                    final file = result.files.single;
                    _processFile(
                      fileName: file.name,
                      filePath: file.path,
                      fileBytes: file.bytes,
                    );
                  } else if (result != null &&
                      result.files.single.bytes != null) {
                    // Web case: path is null, but bytes are available
                    final file = result.files.single;
                    _processFile(fileName: file.name, fileBytes: file.bytes);
                  }
                },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color:
                _isDragging
                    ? Colors.indigo.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDragging ? Colors.indigo : Colors.white10,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child:
                _isUploading
                    ? const CircularProgressIndicator()
                    : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Carga Segura',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Arrastra aquí para subir assets',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
