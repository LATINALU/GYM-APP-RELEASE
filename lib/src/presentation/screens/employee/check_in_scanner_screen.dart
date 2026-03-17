import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../../application/use_cases/use_cases.dart';
import '../../../domain/ports/input/check_in_usecase_port.dart';
import '../../../domain/value_objects/value_objects.dart';
import 'package:get_it/get_it.dart';

class CheckInScannerScreen extends StatefulWidget {
  const CheckInScannerScreen({super.key});

  @override
  State<CheckInScannerScreen> createState() => _CheckInScannerScreenState();
}

class _CheckInScannerScreenState extends State<CheckInScannerScreen> {
  bool _isProcessing = false;
  final TextEditingController _codeController = TextEditingController();

  Future<void> _processCode(String rawValue) async {
    if (_isProcessing || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final String qrPayload = rawValue;
      final checkInUseCase = GetIt.I<CheckInUseCase>();
      
      final result = await checkInUseCase.checkIn(CheckInCommand(
        clientId: UserId(''),
        qrPayload: qrPayload, 
      ));

      result.fold(
        (failure) {
          _showResult(
            success: false,
            message: failure.message,
            title: 'ERROR DE ACCESO',
          );
        },
        (checkIn) {
          _showResult(
            success: true,
            message: 'Check-in registrado exitosamente',
            title: 'ACCESO PERMITIDO',
          );
        },
      );
    } catch (e) {
      _showResult(
        success: false,
        message: 'Código QR inválido',
        title: 'ERROR',
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult({required bool success, required String title, required String message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: success ? Colors.green.shade900 : Colors.red.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: (success ? Colors.green : Colors.red).withValues(alpha: 0.5),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: QuantumTypography.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: QuantumTypography.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: success ? Colors.green.shade900 : Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('CONTINUAR ESCANEANDO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        title: const Text('CHECK-IN SCANNER'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(color: QuantumColors.matrixCyan.withValues(alpha: 0.1)),
            ),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: QuantumColors.quantumBlue, width: 2),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          QuantumColors.quantumBlue.withValues(alpha: 0.1),
                          QuantumColors.quantumBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(color: QuantumColors.quantumBlue),
                          )
                        : Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 100,
                            color: QuantumColors.quantumBlue.withValues(alpha: 0.5),
                          ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    kIsWeb 
                        ? 'Escáner no disponible en Web.\nIngresa el código manualmente:'
                        : 'Coloca el código QR del cliente frente a la cámara',
                    textAlign: TextAlign.center,
                    style: QuantumTypography.body.copyWith(color: QuantumColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 350,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: QuantumColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Código QR o ID del cliente...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: QuantumColors.quantumBlue),
                          onPressed: () => _processCode(_codeController.text),
                        ),
                      ),
                      onSubmitted: _processCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScannerButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QuantumColors.voidGray,
        border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: QuantumColors.quantumBlue),
        onPressed: onPressed,
        iconSize: 32,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
