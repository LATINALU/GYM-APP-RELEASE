import 'package:flutter/material.dart';
import '../../theme/quantum_colors.dart';

/// Configuración Global - Super Admin
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _activeSection = 0;
  bool _maintenanceMode = false;
  bool _newRegistrations = true;
  bool _emailNotifications = true;
  bool _autoSuspend = true;
  int _trialDays = 14;
  int _maxLoginAttempts = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QuantumColors.backgroundStart.withValues(alpha: 0.5), QuantumColors.cosmicBlack],
        ),
      ),
      child: Row(
        children: [
          // Sub-menu lateral
          Container(
            width: 250,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuración', style: QuantumTypography.h3.copyWith(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 32),
                _sectionItem(0, 'General', Icons.tune_rounded),
                _sectionItem(1, 'Seguridad', Icons.security_rounded, isCritical: true),
                _sectionItem(2, 'Planes & Límites', Icons.card_membership_rounded),
                _sectionItem(3, 'Notificaciones', Icons.notifications_none_rounded),
                _sectionItem(4, 'Mantenimiento', Icons.build_rounded, isCritical: _maintenanceMode),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: _buildActiveSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionItem(int index, String label, IconData icon, {bool isCritical = false}) {
    bool isSelected = _activeSection == index;
    return InkWell(
      onTap: () => setState(() => _activeSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF6B35) : Colors.white24, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              )),
            ),
            if (isCritical) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeSection) {
      case 0: return _buildGeneralSection();
      case 1: return _buildSecuritySection();
      case 2: return _buildPlansSection();
      case 3: return _buildNotificationsSection();
      case 4: return _buildMaintenanceSection();
      default: return _buildGeneralSection();
    }
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuración General', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        const Text('Ajustes globales de la plataforma GYM-APP', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildSettingCard('Nombre de la Plataforma', 'GYM-APP', Icons.edit_rounded),
        _buildSettingCard('Versión', 'v2.0.0-beta', Icons.info_outline_rounded),
        _buildSettingCard('Zona Horaria', 'America/Mexico_City (UTC-6)', Icons.access_time_rounded),
        _buildSettingCard('Idioma por Defecto', 'Español (es-MX)', Icons.language_rounded),
        _buildToggleSetting('Permitir Nuevos Registros', _newRegistrations, (v) => setState(() => _newRegistrations = v)),
        _buildSliderSetting('Días de Prueba Gratuita', _trialDays, 7, 30, (v) => setState(() => _trialDays = v.round())),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seguridad', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        const Text('Configuración de seguridad y acceso', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildSliderSetting('Máximo Intentos de Login', _maxLoginAttempts, 3, 10, (v) => setState(() => _maxLoginAttempts = v.round())),
        _buildToggleSetting('Auto-suspender por impago', _autoSuspend, (v) => setState(() => _autoSuspend = v)),
        _buildSettingCard('Política de Contraseñas', 'Mínimo 6 caracteres', Icons.lock_outline_rounded),
        _buildSettingCard('Sesión Máxima', '24 horas', Icons.timer_rounded),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zona de Peligro', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Resetear todas las sesiones activas', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _confirmResetSessions(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Ejecutar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Planes & Límites', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        const Text('Configuración de planes y límites por tier', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildSettingCard('Plan Trial', '14 días, 50 miembros, 1 staff', Icons.hourglass_bottom_rounded),
        _buildSettingCard('Plan Básico', '\$999/mes, 200 miembros, 5 staff', Icons.star_outline_rounded),
        _buildSettingCard('Plan Premium', '\$2,499/mes, 500 miembros, 15 staff', Icons.star_half_rounded),
        _buildSettingCard('Plan Enterprise', '\$4,999/mes, Ilimitado', Icons.star_rounded),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notificaciones', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        const Text('Configuración de notificaciones del sistema', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildToggleSetting('Notificaciones por Email', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
        _buildSettingCard('Email de Soporte', 'soporte@gym-app.com', Icons.email_outlined),
        _buildSettingCard('Alertas de Seguridad', 'Inmediatas', Icons.notification_important_rounded),
        _buildSettingCard('Reportes Automáticos', 'Semanales (Lunes 8:00 AM)', Icons.schedule_rounded),
      ],
    );
  }

  Widget _buildMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mantenimiento', style: QuantumTypography.h2.copyWith(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 8),
        const Text('Modo mantenimiento y herramientas del sistema', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildToggleSetting('Modo Mantenimiento', _maintenanceMode, (v) => setState(() => _maintenanceMode = v)),
        if (_maintenanceMode)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 12),
                Text('La plataforma está en modo mantenimiento. Los usuarios no pueden acceder.', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
              ],
            ),
          ),
        _buildSettingCard('Última Actualización', '2025-02-10 08:00', Icons.update_rounded),
        _buildSettingCard('Base de Datos', 'Firestore (Healthy)', Icons.storage_rounded),
        _buildSettingCard('Caché', '2.4 GB usado', Icons.cached_rounded),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _confirmClearCache(context),
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: const Text('Limpiar Caché Global'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            foregroundColor: const Color(0xFFF59E0B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildToggleSetting(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF6B35),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String title, int value, int min, int max, ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.surface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$value', style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF6B35),
              inactiveTrackColor: Colors.white10,
              thumbColor: const Color(0xFFFF6B35),
              overlayColor: const Color(0xFFFF6B35).withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetSessions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Resetear sesiones?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Todos los usuarios serán desconectados y deberán iniciar sesión nuevamente.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesiones reseteadas. Todos los usuarios deben reingresar.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuantumColors.surface(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Limpiar caché global?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se eliminará la caché local de todos los dispositivos. Los datos se recargarán desde Firestore.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caché global limpiada correctamente'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}
