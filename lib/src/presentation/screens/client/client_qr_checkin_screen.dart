import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/theme.dart';
import '../../theme/gym_widgets.dart';

class ClientQrCheckinScreen extends StatefulWidget {
  const ClientQrCheckinScreen({super.key});

  @override
  State<ClientQrCheckinScreen> createState() => _ClientQrCheckinScreenState();
}

class _ClientQrCheckinScreenState extends State<ClientQrCheckinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  String? get _qrPassData {
    final userId = AuthStateNotifier.instance.profile?.uid;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return 'QUANTUM_$userId';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: GymAppBar(
        title: 'Check-in QR',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: QuantumColors.surface(opacity: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: QuantumColors.subtleBorder),
            ),
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                color: QuantumColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _showHelpDialog(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildQrCard(),
              const SizedBox(height: 40),
              _buildInstructions(),
              const SizedBox(height: 40),
              _buildHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    final qrPassData = _qrPassData;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: QuantumColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: QuantumColors.subtleBorder),
        boxShadow: QuantumColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Tu Pase de Acceso',
            style: QuantumTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acerca el código al lector en la entrada',
            style: TextStyle(color: QuantumColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 40),
          if (qrPassData == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: QuantumColors.surface(opacity: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: QuantumColors.subtleBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo generar el QR de acceso',
                    style: QuantumTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión nuevamente para obtener tu pase.',
                    style: TextStyle(
                      color: QuantumColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: QuantumColors.quantumBlue.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrPassData,
                      version: QrVersions.auto,
                      size: 220.0,
                      gapless: false,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + (220 * _scanLineAnimation.value),
                        child: Container(
                          width: 220,
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: QuantumColors.quantumBlue.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [
                                QuantumColors.quantumBlue.withValues(alpha: 0),
                                QuantumColors.quantumBlue,
                                QuantumColors.quantumBlue.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: QuantumColors.surface(opacity: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: QuantumColors.subtleBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: QuantumColors.matrixCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'Válido con tu cuenta activa',
                  style: TextStyle(
                    color: QuantumColors.matrixCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo funciona?',
          style: QuantumTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildInstructionStep(
          icon: Icons.qr_code_scanner,
          text: 'Abre esta pantalla al llegar al gimnasio.',
        ),
        _buildInstructionStep(
          icon: Icons.sensors,
          text: 'Coloca tu pantalla frente al escáner de la entrada.',
        ),
        _buildInstructionStep(
          icon: Icons.check_circle_outline,
          text: 'Escucha el pitido y entra a entrenar.',
        ),
      ],
    );
  }

  Widget _buildInstructionStep({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QuantumColors.surface(opacity: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuantumColors.subtleBorder),
            ),
            child: Icon(icon, color: QuantumColors.quantumBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: QuantumColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(opacity: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuantumColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QuantumColors.holoPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: QuantumColors.holoPurple.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: QuantumColors.holoPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Problemas con el código?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Asegúrate de tener el brillo al máximo.',
                  style: TextStyle(
                    color: QuantumColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showHelpDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: QuantumColors.holoPurple.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Ayuda',
              style: TextStyle(
                color: QuantumColors.holoPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: QuantumColors.subtleBorder),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: QuantumColors.quantumBlue,
            ),
            const SizedBox(width: 12),
            Text(
              'Ayuda con QR',
              style: QuantumTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpItem(
              '1.',
              'Asegúrate de tener el brillo de pantalla al máximo.',
            ),
            const SizedBox(height: 8),
            _helpItem('2.', 'Limpia la pantalla de tu dispositivo.'),
            const SizedBox(height: 8),
            _helpItem(
              '3.',
              'Acerca el QR al escáner a una distancia de 10-15 cm.',
            ),
            const SizedBox(height: 8),
            _helpItem(
              '4.',
              'Si el problema persiste, contacta a recepción.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: QuantumColors.surface(opacity: 0.5),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: QuantumColors.quantumBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: QuantumColors.textSecondary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
