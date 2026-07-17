import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/quantum_colors.dart';

/// Reusable dialog to share a routine via QR code with a 10-minute expiration.
///
/// Works for any role: user, coach, or gym owner.
/// Call [ShareRoutineQrDialog.show] with the routine data.
class ShareRoutineQrDialog extends StatelessWidget {
  final String routineId;
  final String routineName;
  final String? description;
  final String difficulty;
  final int estimatedDuration;
  final List<Map<String, dynamic>> exercises;
  final String? gymId;
  final String? createdBy;

  const ShareRoutineQrDialog({
    super.key,
    required this.routineId,
    required this.routineName,
    this.description,
    required this.difficulty,
    this.estimatedDuration = 60,
    this.exercises = const [],
    this.gymId,
    this.createdBy,
  });

  /// Show the QR share dialog from any screen.
  static void show(
    BuildContext context, {
    required String routineId,
    required String routineName,
    String? description,
    required String difficulty,
    int estimatedDuration = 60,
    List<Map<String, dynamic>> exercises = const [],
    String? gymId,
    String? createdBy,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ShareRoutineQrDialog(
        routineId: routineId,
        routineName: routineName,
        description: description,
        difficulty: difficulty,
        estimatedDuration: estimatedDuration,
        exercises: exercises,
        gymId: gymId,
        createdBy: createdBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    final qrPayload = jsonEncode({
      'type': 'routine_import',
      'routineId': routineId,
      'gymId': gymId ?? '',
      'name': routineName,
      'difficulty': difficulty,
      'exercises': exercises,
      'estimatedDuration': estimatedDuration,
      'description': description ?? '',
      'createdBy': createdBy ?? '',
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    });

    return Dialog(
      backgroundColor: const Color(0xFF0D0D1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPARTIR RUTINA',
                  style: QuantumTypography.h3.copyWith(letterSpacing: 2),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Escanea con la app móvil para importar',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 240,
                gapless: true,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: QuantumColors.quantumBlue, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      routineName,
                      style: const TextStyle(
                        color: QuantumColors.quantumBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Expira en 10 minutos (${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')})',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'El código QR contiene toda la información de la rutina.\n'
              'Expira en 10 minutos por seguridad.\n'
              'Escanea desde la app móvil > Escáner > Importar rutina.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
