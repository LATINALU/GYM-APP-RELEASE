import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/theme.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../infrastructure/config/di.dart';
import '../../../domain/ports/output/check_in_repository_port.dart';
import '../../../domain/ports/output/user_repository_port.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';

// Conditional import - mobile_scanner only works on mobile platforms
// ignore_for_file: undefined_hidden_name

/// Staff QR Scanner Screen for check-in validation
class StaffQrScannerScreen extends StatefulWidget {
  const StaffQrScannerScreen({super.key});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String? _lastScannedCode;
  String? _userName;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_isProcessing || code.isEmpty) return;
    if (code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
      _userName = null;
      _errorMessage = null;
    });

    try {
      // Validar formato del QR
      if (!code.startsWith('QUANTUM_')) {
        throw Exception('QR inválido');
      }

      final userId = code.replaceFirst('QUANTUM_', '');

      // Verificar que el usuario existe via repository
      final userRepo = getIt<UserRepositoryPort>();
      final userResult = await userRepo.findByIdGlobal(UserId(userId));

      final user = userResult.fold(
        (failure) => throw Exception(failure.message),
        (user) => user,
      );

      // Verificar membresía activa
      if (user.membershipStatus != MembershipStatus.approved) {
        throw Exception('Membresía no activa');
      }

      // Registrar check-in via repository
      final auth = AuthStateNotifier.instance;
      final registeredById = auth.profile?.uid;

      if (registeredById == null) {
        throw Exception('No se pudo resolver el usuario actual');
      }

      final checkInRepo = getIt<CheckInRepositoryPort>();

      // Verificar check-in activo
      final activeResult = await checkInRepo.findActiveByClient(UserId(userId));
      final activeCheckIn = activeResult.fold(
        (failure) => throw Exception(failure.message),
        (checkIn) => checkIn,
      );

      if (activeCheckIn != null) {
        throw Exception('El cliente ya tiene un check-in activo');
      }

      // Crear check-in
      final checkIn = CheckIn.create(
        clientId: UserId(userId),
        registeredById: UserId(registeredById),
        notes: 'qr_scan',
      );

      final saveResult = await checkInRepo.save(checkIn);
      saveResult.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );

      if (mounted) {
        setState(() {
          _userName = user.name.fullName;
          _isProcessing = false;
        });

        _showSuccessDialog();

        // Auto-reset después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _userName = null;
              _lastScannedCode = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isProcessing = false;
        });

        _showErrorDialog();

        // Auto-reset después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
              _lastScannedCode = null;
            });
          }
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.check_circle,
                color: QuantumColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Check-in exitoso!',
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _userName ?? 'Cliente registrado correctamente',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
                _lastScannedCode = null;
              });
            },
            child: const Text('Continuar', style: TextStyle(color: QuantumColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error en check-in',
              style: QuantumTypography.h3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
                _lastScannedCode = null;
              });
            },
            child: const Text('Cerrar', style: TextStyle(color: Colors.redAccent)),
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
          'Escanear QR',
          style: QuantumTypography.h3.copyWith(color: Colors.white),
        ),
      ),
      body: kIsWeb ? _buildWebScanner() : _buildMobileScanner(),
    );
  }

  Widget _buildMobileScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? rawValue = barcode.rawValue;
              if (rawValue != null && rawValue.isNotEmpty) {
                _processCode(rawValue);
                break;
              }
            }
          },
        ),
        // Overlay with scan frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isProcessing ? QuantumColors.success : QuantumColors.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Processing indicator
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: QuantumColors.success),
            ),
          ),
        // Manual entry fallback
        Positioned(
          bottom: 32,
          left: 32,
          right: 32,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: QuantumColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: QuantumColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _manualCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'O ingresa el código manualmente...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: QuantumColors.primary),
                        onPressed: () => _processCode(_manualCodeController.text),
                      ),
                    ),
                    onSubmitted: _processCode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebScanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? QuantumColors.success : QuantumColors.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          QuantumColors.primary.withValues(alpha: 0.1),
                          QuantumColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: QuantumColors.success,
                            ),
                          )
                        : Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 80,
                            color: QuantumColors.primary.withValues(alpha: 0.5),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              kIsWeb 
                  ? 'Escáner de cámara no disponible en Web.\nIngresa el código manualmente:'
                  : 'Coloca el código QR del cliente en el marco',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (kIsWeb) ...[
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: QuantumColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuantumColors.primary.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _manualCodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Código del cliente...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: QuantumColors.primary),
                      onPressed: () => _processCode(_manualCodeController.text),
                    ),
                  ),
                  onSubmitted: _processCode,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
