import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/ports/output/settings_repository_port.dart';

class FirebaseSettingsRepository implements SettingsRepositoryPort {
  final FirebaseFirestore _firestore;
  final String Function() _getUserId;

  FirebaseSettingsRepository(this._firestore, this._getUserId);

  DocumentReference get _settingsDoc => _firestore
      .collection('users_settings')
      .doc(_getUserId());

  @override
  Future<AppSettings> getSettings() async {
    final doc = await _settingsDoc.get();
    if (!doc.exists || doc.data() == null) {
      return const AppSettings(); // Default settings
    }
    
    final data = doc.data() as Map<String, dynamic>;
    return AppSettings(
      pushEnabled: data['pushEnabled'] ?? true,
      emailEnabled: data['emailEnabled'] ?? true,
      trainingReminders: data['trainingReminders'] ?? true,
      gymAnnouncements: data['gymAnnouncements'] ?? true,
      membershipAlerts: data['membershipAlerts'] ?? true,
      themeMode: data['themeMode'] ?? 'dark',
      language: data['language'] ?? 'es',
      biometricEnabled: data['biometricEnabled'] ?? false,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsDoc.set({
      'pushEnabled': settings.pushEnabled,
      'emailEnabled': settings.emailEnabled,
      'trainingReminders': settings.trainingReminders,
      'gymAnnouncements': settings.gymAnnouncements,
      'membershipAlerts': settings.membershipAlerts,
      'themeMode': settings.themeMode,
      'language': settings.language,
      'biometricEnabled': settings.biometricEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
