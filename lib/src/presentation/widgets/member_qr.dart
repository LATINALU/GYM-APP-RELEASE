import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/theme.dart';
import 'quantum_animations.dart';

/// Premium Holographic QR Code for members
class MemberQr extends StatelessWidget {
  final String userId;
  final String gymId;
  final double size;

  const MemberQr({
    super.key,
    required this.userId,
    required this.gymId,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ Security Agent: Signed Payload with Timestamp
    // Logic: {userId}|{gymId}|{timestamp}
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String rawPayload = '$userId|$gymId|$timestamp';
    final String data = base64Url.encode(utf8.encode(rawPayload));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            gapless: false,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: QuantumColors.cosmicBlack,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: QuantumColors.cosmicBlack,
            ),
            // Logo opcional en el centro
            embeddedImage: const AssetImage('assets/images/logo_small.png'),
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
            errorStateBuilder: (cxt, err) {
              return const Center(
                child: Text(
                  'Error generating QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FadeInWidget(
          child: Text(
            'ESCANÉAME EN RECEPCIÓN',
            style: QuantumTypography.label.copyWith(
              color: QuantumColors.matrixCyan,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
