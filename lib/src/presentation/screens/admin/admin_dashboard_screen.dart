import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Dashboard Global del Super Admin
/// Muestra métricas de toda la plataforma: gimnasios, usuarios, ingresos
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuantumColors.backgroundStart.withValues(alpha: 0.5),
            QuantumColors.cosmicBlack,
          ],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: QuantumColors.quantumBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildUnavailableState(),
                ],
              ),
            ),
    );
  }

  Widget _buildUnavailableState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.white38,
            size: 56,
          ),
          SizedBox(height: 16),
          Text(
            'Métricas globales no disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'El dashboard global de super admin aún no está sincronizado con datos reales de la plataforma.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANEL SUPER ADMIN',
              style: QuantumTypography.h1.copyWith(
                fontSize: 36,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vista global de la plataforma GYM-APP',
              style: QuantumTypography.bodyLarge.copyWith(color: Colors.white38),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QuantumColors.quantumBlue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: QuantumColors.quantumBlue, size: 18),
              SizedBox(width: 8),
              Text('Super Admin', style: TextStyle(color: QuantumColors.quantumBlue, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
