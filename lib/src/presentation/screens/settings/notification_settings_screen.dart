import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import 'bloc/settings_bloc.dart';
import '../../../domain/entities/app_settings.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;

        return Scaffold(
          backgroundColor: QuantumTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Notificaciones', style: QuantumTypography.h4),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildModernCard(
                icon: Icons.notifications_active_outlined,
                title: 'Alertas Generales',
                description: 'Habilita o deshabilita todas las notificaciones push de la aplicación.',
                value: settings.pushEnabled,
                onChanged: (val) => _update(context, settings.copyWith(pushEnabled: val)),
              ),
              const SizedBox(height: 32),
              Text(
                'QUÉ QUIERO RECIBIR',
                style: QuantumTypography.label.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                title: 'Recordatorios de Entreno',
                subtitle: 'Te avisamos antes de tu sesión programada',
                value: settings.trainingReminders,
                enabled: settings.pushEnabled,
                onChanged: (val) => _update(context, settings.copyWith(trainingReminders: val ?? false)),
              ),
              _buildOptionTile(
                title: 'Anuncios del Gimnasio',
                subtitle: 'Eventos, cambios de horario y noticias',
                value: settings.gymAnnouncements,
                enabled: settings.pushEnabled,
                onChanged: (val) => _update(context, settings.copyWith(gymAnnouncements: val ?? false)),
              ),
              _buildOptionTile(
                title: 'Alertas de Membresía',
                subtitle: 'Avisos de pago y estado de suscripción',
                value: settings.membershipAlerts,
                enabled: settings.pushEnabled,
                onChanged: (val) => _update(context, settings.copyWith(membershipAlerts: val ?? false)),
              ),
              const SizedBox(height: 32),
              _buildModernCard(
                icon: Icons.email_outlined,
                title: 'Reportes por Email',
                description: 'Recibe un resumen semanal de tu progreso en tu correo.',
                value: settings.emailEnabled,
                onChanged: (val) => _update(context, settings.copyWith(emailEnabled: val)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _update(BuildContext context, AppSettings settings) {
    context.read<SettingsBloc>().add(UpdateSettings(settings));
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [QuantumTheme.primary.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuantumTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: QuantumTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: QuantumTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: QuantumTypography.h4.copyWith(fontSize: 18)),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: QuantumTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: QuantumTypography.body.copyWith(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: QuantumTheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: enabled ? onChanged : null,
          title: Text(title, style: QuantumTypography.body.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: QuantumTypography.caption.copyWith(color: Colors.white38)),
          activeColor: QuantumTheme.primary,
          checkColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }
}
