import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import 'bloc/settings_bloc.dart';
import '../../../domain/entities/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            title: Text('Ajustes', style: QuantumTypography.h4),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              _buildSectionHeader('NOTIFICACIONES'),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Notificaciones Push',
                subtitle: 'Alertas en tiempo real en tu dispositivo',
                value: settings.pushEnabled,
                onChanged: (val) => _update(context, settings.copyWith(pushEnabled: val)),
                icon: Icons.notifications_active_outlined,
              ),
              _buildActionTile(
                title: 'Preferencias de Contenido',
                subtitle: 'Elige qué quieres recibir',
                onTap: () => context.push('/settings/notifications'),
                icon: Icons.tune_rounded,
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('APARIENCIA & LENGUAJE'),
              const SizedBox(height: 16),
              _buildActionTile(
                title: 'Modo de Tema',
                subtitle: settings.themeMode == 'dark' ? 'Oscuro Cuántico' : 'Claro',
                onTap: () => _showThemePicker(context, settings),
                icon: Icons.dark_mode_outlined,
              ),
              _buildActionTile(
                title: 'Idioma',
                subtitle: settings.language == 'es' ? 'Español' : 'English',
                onTap: () => _showLanguagePicker(context, settings),
                icon: Icons.language_rounded,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('SEGURIDAD'),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Biometría',
                subtitle: 'FaceID / Huella dactilar para entrar',
                value: settings.biometricEnabled,
                onChanged: (val) => _update(context, settings.copyWith(biometricEnabled: val)),
                icon: Icons.fingerprint_rounded,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('DATOS & PRIVACIDAD'),
              const SizedBox(height: 16),
              _buildActionTile(
                title: 'Cache de Entrenamiento',
                subtitle: 'Limpiar datos locales (124 MB)',
                onTap: () {},
                icon: Icons.cleaning_services_outlined,
              ),
              _buildActionTile(
                title: 'Política de Privacidad',
                onTap: () {},
                icon: Icons.privacy_tip_outlined,
              ),
              _buildActionTile(
                title: 'Eliminar mi cuenta',
                onTap: () => _showDeleteConfirmation(context),
                icon: Icons.delete_forever_outlined,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  void _update(BuildContext context, AppSettings settings) {
    context.read<SettingsBloc>().add(UpdateSettings(settings));
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: QuantumTypography.label.copyWith(
        color: QuantumTheme.primary.withValues(alpha: 0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: QuantumTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: QuantumTheme.primary, size: 22),
        title: Text(title, style: QuantumTypography.body.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: QuantumTypography.caption.copyWith(color: Colors.white38)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: QuantumTheme.primary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: QuantumTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: color ?? Colors.white70, size: 22),
        title: Text(title, style: QuantumTypography.body.copyWith(fontWeight: FontWeight.bold, color: color)),
        subtitle: subtitle != null ? Text(subtitle, style: QuantumTypography.caption.copyWith(color: Colors.white38)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppSettings settings) {
    // Boilerplate for bottom sheet picker
  }

  void _showLanguagePicker(BuildContext context, AppSettings settings) {
    // Boilerplate for bottom sheet picker
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: QuantumTheme.surface,
        title: const Text('¿Eliminar cuenta?'),
        content: const Text('Esta acción es irreversible y perderás todo tu historial de entrenamiento.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {}, 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}
