import 'package:equatable/equatable.dart';

/// AppSettings Entity - Handles user preferences and configuration
class AppSettings extends Equatable {
  // Notification Toggles
  final bool pushEnabled;
  final bool emailEnabled;
  final bool trainingReminders;
  final bool gymAnnouncements;
  final bool membershipAlerts;

  // Appearance
  final String themeMode; // system, light, dark
  final String language;

  // Security
  final bool biometricEnabled;

  const AppSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.trainingReminders = true,
    this.gymAnnouncements = true,
    this.membershipAlerts = true,
    this.themeMode = 'dark',
    this.language = 'es',
    this.biometricEnabled = false,
  });

  AppSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? trainingReminders,
    bool? gymAnnouncements,
    bool? membershipAlerts,
    String? themeMode,
    String? language,
    bool? biometricEnabled,
  }) {
    return AppSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      trainingReminders: trainingReminders ?? this.trainingReminders,
      gymAnnouncements: gymAnnouncements ?? this.gymAnnouncements,
      membershipAlerts: membershipAlerts ?? this.membershipAlerts,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
        pushEnabled,
        emailEnabled,
        trainingReminders,
        gymAnnouncements,
        membershipAlerts,
        themeMode,
        language,
        biometricEnabled,
      ];
}
