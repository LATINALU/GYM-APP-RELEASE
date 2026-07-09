import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ayuda & Soporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de ayuda',
                  style: QuantumTypography.h1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Encuentra respuestas rápidas y vías de contacto para resolver incidencias operativas.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 24),
                _SupportCard(
                  icon: Icons.email_outlined,
                  title: 'Soporte por correo',
                  description: 'support@gym-app.com',
                  ctaLabel: 'Copiar correo',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correo copiado: support@gym-app.com'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SupportCard(
                  icon: Icons.schedule_rounded,
                  title: 'Horario de soporte',
                  description: 'Lunes a viernes de 09:00 a 18:00 (GMT-6)',
                ),
                const SizedBox(height: 24),
                Text(
                  'Preguntas frecuentes',
                  style: QuantumTypography.h3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const _FaqTile(
                  title: '¿Cómo restablezco la contraseña de un usuario?',
                  content:
                      'Desde login, usa “¿Olvidaste tu contraseña?” y sigue el flujo de recuperación por correo.',
                ),
                const _FaqTile(
                  title: '¿Qué hago si un cobro aparece como pendiente?',
                  content:
                      'Revisa el método de pago registrado y vuelve a intentar el cobro desde Finanzas & Suscripciones.',
                ),
                const _FaqTile(
                  title: '¿Dónde reporto un bug de plataforma?',
                  content:
                      'Envía evidencia (pantalla, gymId y pasos) al correo de soporte para priorización técnica.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onTap;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: QuantumColors.quantumBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          if (ctaLabel != null)
            TextButton(onPressed: onTap, child: Text(ctaLabel!)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String content;

  const _FaqTile({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ExpansionTile(
        iconColor: QuantumColors.quantumBlue,
        collapsedIconColor: Colors.white60,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(content, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
