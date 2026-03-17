import '../../entities/app_settings.dart';

abstract class SettingsRepositoryPort {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
