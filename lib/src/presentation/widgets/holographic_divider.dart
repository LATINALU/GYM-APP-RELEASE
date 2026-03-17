import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

/// Divisor holográfico con gradiente brillante
class HolographicDivider extends StatelessWidget {
  final double thickness;
  final double glowIntensity;
  final double? width;
  final EdgeInsets? margin;

  const HolographicDivider({
    super.key,
    this.thickness = 1,
    this.glowIntensity = 0.5,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: thickness,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            QuantumColors.quantumBlue.withOpacity(0.3 * glowIntensity),
            QuantumColors.quantumBlue.withOpacity(0.6 * glowIntensity),
            QuantumColors.quantumBlue.withOpacity(0.3 * glowIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: QuantumColors.quantumBlue.withOpacity(0.2 * glowIntensity),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

/// Divisor vertical holográfico
class HolographicVerticalDivider extends StatelessWidget {
  final double thickness;
  final double glowIntensity;
  final double? height;

  const HolographicVerticalDivider({
    super.key,
    this.thickness = 1,
    this.glowIntensity = 0.5,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      height: height ?? 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            QuantumColors.quantumBlue.withOpacity(0.3 * glowIntensity),
            QuantumColors.quantumBlue.withOpacity(0.6 * glowIntensity),
            QuantumColors.quantumBlue.withOpacity(0.3 * glowIntensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
