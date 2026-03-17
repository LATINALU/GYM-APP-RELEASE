import '../../domain/entities/app_settings.dart';
import '../../domain/ports/output/settings_repository_port.dart';
import 'insforge_client.dart';

/// InsForge implementation of SettingsRepositoryPort
class InsForgeSettingsRepository implements SettingsRepositoryPort {
  final InsForgeClient _client;

  InsForgeSettingsRepository(this._client);

  @override
  Future<AppSettings> getSettings() async {
    try {
      final userId = _client.currentUserId;
      if (userId == null) return const AppSettings();

      final response = await _client.from('app_settings', query: 'user_id=eq.$userId&select=*');
      if (!response.isSuccess || response.dataList.isEmpty) {
        return const AppSettings();
      }

      final data = response.firstItem!;
      final settingsData = data['settings_data'] as Map<String, dynamic>? ?? {};

      return AppSettings(
        themeMode: data['theme'] as String? ?? 'dark',
        language: data['language'] as String? ?? 'es',
        biometricEnabled: data['biometric_enabled'] as bool? ?? false,
        pushEnabled: settingsData['pushEnabled'] as bool? ?? true,
        emailEnabled: settingsData['emailEnabled'] as bool? ?? true,
        trainingReminders: settingsData['trainingReminders'] as bool? ?? true,
        gymAnnouncements: settingsData['gymAnnouncements'] as bool? ?? true,
        membershipAlerts: settingsData['membershipAlerts'] as bool? ?? true,
      );
    } catch (e) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final userId = _client.currentUserId;
      if (userId == null) return;

      final data = {
        'user_id': userId,
        'theme': settings.themeMode,
        'language': settings.language,
        'biometric_enabled': settings.biometricEnabled,
        'notifications_enabled': settings.pushEnabled,
        'settings_data': {
          'pushEnabled': settings.pushEnabled,
          'emailEnabled': settings.emailEnabled,
          'trainingReminders': settings.trainingReminders,
          'gymAnnouncements': settings.gymAnnouncements,
          'membershipAlerts': settings.membershipAlerts,
        },
      };

      // Upsert
      final response = await _client.insert('app_settings', data);
      if (response.isConflict) {
        await _client.update('app_settings', data, 'user_id=eq.$userId');
      }
    } catch (_) {}
  }
}
