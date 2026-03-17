import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class ClientQrScreen extends StatelessWidget {
  const ClientQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mi Código QR',
          style: QuantumTypography.h3.copyWith(color: Colors.white),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String? userId;
          if (state is Authenticated) {
            userId = state.user.id.value;
          }

          if (userId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: QuantumColors.primary.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: userId,
                    version: QrVersions.auto,
                    size: 250.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Presenta este código en recepción',
                  style: QuantumTypography.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El staff lo escaneará para registrar tu visita',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 60),
                _buildSecurityTip(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityTip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: QuantumColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este código es personal e intransferible.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
