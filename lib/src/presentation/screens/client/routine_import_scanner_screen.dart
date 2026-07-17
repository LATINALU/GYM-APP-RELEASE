import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/theme.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../application/use_cases/client/import_routine_from_qr_usecase.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../infrastructure/config/di.dart';

/// Escáner de QR de rutinas para clientes.
/// Lee el payload `routine_import` (generado por el kiosko o por
/// "Compartir QR" en Training Forge), muestra un preview y, al confirmar,
/// auto-asigna la rutina al cliente vía [ImportRoutineFromQrUseCase].
class RoutineImportScannerScreen extends StatefulWidget {
  const RoutineImportScannerScreen({super.key});

  @override
  State<RoutineImportScannerScreen> createState() =>
      _RoutineImportScannerScreenState();
}

class _RoutineImportScannerScreenState
    extends State<RoutineImportScannerScreen> {
  bool _isProcessing = false;
  String? _lastScannedCode;
  final TextEditingController _manualCodeController = TextEditingController();

  bool get _cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_isProcessing || code.trim().isEmpty) return;
    if (code == _lastScannedCode) return;
    _lastScannedCode = code;

    final parseResult = ImportRoutineFromQrUseCase.parsePayload(code);
    parseResult.fold(
      (failure) => _showErrorDialog(failure.message),
      (preview) => _showPreviewSheet(code, preview),
    );
  }

  Future<void> _confirmImport(String rawPayload) async {
    final uid = AuthStateNotifier.instance.profile?.uid;
    if (uid == null) {
      _showErrorDialog('No se pudo resolver tu usuario. Vuelve a iniciar sesión.');
      return;
    }

    setState(() => _isProcessing = true);

    final result = await getIt<ImportRoutineFromQrUseCase>().execute(
      rawPayload: rawPayload,
      clientId: UserId(uid),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    result.fold(
      (failure) => _showErrorDialog(failure.message),
      (imported) => _showSuccessDialog(imported.message),
    );
  }

  void _showPreviewSheet(String rawPayload, RoutineImportPreview preview) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => _RoutineImportPreviewSheet(
        preview: preview,
        onConfirm: () {
          Navigator.pop(ctx);
          _confirmImport(rawPayload);
        },
      ),
    ).whenComplete(() {
      // Permitir re-escanear el mismo código si canceló el preview
      if (!_isProcessing) _lastScannedCode = null;
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: QuantumColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: QuantumColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Rutina importada!',
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Volver a la pantalla anterior (Entrenamiento) para ver el plan
              Navigator.of(context).pop(true);
            },
            child: const Text('Ver mi plan',
                style: TextStyle(color: QuantumColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo importar',
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _lastScannedCode = null);
            },
            child:
                const Text('Cerrar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Importar Rutina',
          style: QuantumTypography.h3.copyWith(color: Colors.white),
        ),
      ),
      body: _cameraAvailable ? _buildCameraScanner() : _buildManualEntry(),
    );
  }

  Widget _buildCameraScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              final rawValue = barcode.rawValue;
              if (rawValue != null && rawValue.isNotEmpty) {
                _processCode(rawValue);
                break;
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isProcessing
                    ? QuantumColors.success
                    : QuantumColors.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 32,
          right: 32,
          child: Text(
            'Apunta al QR del kiosko o del coach',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: QuantumColors.success),
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: QuantumColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Escáner de cámara no disponible en esta plataforma.\n'
              'Pega el contenido del código QR:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Container(
              width: 340,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: QuantumColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: QuantumColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _manualCodeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contenido del QR...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: QuantumColors.primary),
                    onPressed: () => _processCode(_manualCodeController.text),
                  ),
                ),
                onSubmitted: _processCode,
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: QuantumColors.success),
            ],
          ],
        ),
      ),
    );
  }
}

/// Preview de la rutina antes de confirmar la importación.
class _RoutineImportPreviewSheet extends StatelessWidget {
  final RoutineImportPreview preview;
  final VoidCallback onConfirm;

  const _RoutineImportPreviewSheet({
    required this.preview,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              preview.name,
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            if (preview.description != null) ...[
              const SizedBox(height: 8),
              Text(
                preview.description!,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.speed_rounded,
                  label: preview.difficulty,
                ),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${preview.estimatedDuration} min',
                ),
                _InfoChip(
                  icon: Icons.fitness_center_rounded,
                  label: '${preview.exercises.length} ejercicios',
                ),
              ],
            ),
            if (preview.exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: preview.exercises.length,
                  itemBuilder: (_, i) {
                    final ex = preview.exercises[i];
                    final name = ex['exerciseName'] as String? ?? 'Ejercicio';
                    final sets = ex['sets'] ?? 3;
                    final reps = ex['reps'] ?? '10-12';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: Colors.white38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$sets × $reps',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: QuantumColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onConfirm,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Importar a mi plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: QuantumColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: QuantumColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: QuantumColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
