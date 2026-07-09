import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../theme/theme.dart';
import '../../../domain/ports/input/onboard_member_usecase_port.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../domain/value_objects/value_objects.dart';

class OwnerOnboardingScannerScreen extends StatefulWidget {
  const OwnerOnboardingScannerScreen({super.key});

  @override
  State<OwnerOnboardingScannerScreen> createState() => _OwnerOnboardingScannerScreenState();
}

class _OwnerOnboardingScannerScreenState extends State<OwnerOnboardingScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;
  bool _success = false;

  Future<void> _onboardUser(String code) async {
    if (code.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final onboardUseCase = GetIt.I<OnboardMemberUseCasePort>();
    final auth = AuthStateNotifier.instance;

    final result = await onboardUseCase.execute(
      identifier: code,
      gymId: auth.profile?.gymId ?? const GymId('unknown'),
      ownerId: UserId(auth.profile?.uid ?? ''),
    );

    setState(() {
      _isProcessing = false;
    });

    result.fold(
      (failure) => setState(() => _errorMessage = failure.message),
      (_) {
        setState(() => _success = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GymAppBar(
        title: 'Agregar Miembro',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildScannerPlaceholder(),
            const SizedBox(height: 40),
            Text(
              'O ingresa el código manual',
              style: QuantumTypography.label.copyWith(color: GymColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildManualInput(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBadge(),
            ],
            if (_success) ...[
              const SizedBox(height: 24),
              _buildSuccessState(),
            ],
            const SizedBox(height: 40),
            _buildRecentOnboardings(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: GymColors.primary.withValues(alpha: 0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Scanner View
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 80, color: GymColors.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Escaneando...',
                style: QuantumTypography.bodyMedium.copyWith(color: GymColors.textSecondary),
              ),
            ],
          ),
          
          // Scanner Animation
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: GymColors.primary, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: GymColors.primary.withValues(alpha: 0.3)),
          
          Positioned(
            top: 25,
            child: Container(
              width: 200,
              height: 2,
              color: GymColors.primary,
            ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 250, duration: 2000.ms, curve: Curves.easeInOut),
          ),
          
          // Scanner action placeholder
          const Positioned(
            bottom: 20,
            child: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: AB12CD',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              filled: true,
              fillColor: const Color(0xFF16162A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: GymButton(
            text: 'OK',
            onPressed: () => _onboardUser(_codeController.text),
            loading: _isProcessing,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GymColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: GymColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: GymColors.error, fontSize: 13)),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: GymColors.success, size: 60),
        const SizedBox(height: 12),
        Text(
          '¡Miembro agregado con éxito!',
          style: QuantumTypography.h3.copyWith(color: GymColors.success),
        ),
        Text(
          'Redirigiendo...',
          style: QuantumTypography.bodySmall.copyWith(color: GymColors.textSecondary),
        ),
      ],
    ).animate().scale();
  }

  Widget _buildRecentOnboardings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recientes', style: QuantumTypography.h3),
        const SizedBox(height: 16),
        _buildRecentItem('Juan Perez', 'Hace 5 min'),
        const SizedBox(height: 12),
        _buildRecentItem('Maria Garcia', 'Hace 1 hora'),
      ],
    );
  }

  Widget _buildRecentItem(String name, String time) {
    return GymCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: GymColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: GymColors.primary),
        ),
        title: Text(name, style: QuantumTypography.bodyLarge),
        subtitle: Text(time, style: QuantumTypography.bodySmall.copyWith(color: GymColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: GymColors.textSecondary),
      ),
    );
  }
}
