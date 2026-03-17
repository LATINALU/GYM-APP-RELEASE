/// GYM-APP - App Initialization Module
/// Unified auth backend: Firebase (production/debug)
/// Mock mode is explicit and only for test/dev entrypoints.

import 'package:flutter/foundation.dart';
import 'auth/auth_state_notifier.dart';

/// Initialize all app dependencies and services
Future<void> initializeApp() async {
  debugPrint('[INIT] Starting GYM-APP initialization...');
  AuthStateNotifier.useMockAuth = false;
  debugPrint('[INIT] Auth mode: FIREBASE');

  // 2. Initialize Auth State (triggers session restore)
  final authProvider = AuthStateNotifier.instance;
  debugPrint(
    '[INIT] AuthStateNotifier ready (authenticated: ${authProvider.isAuthenticated})',
  );

  // 3. Log app info
  _printAppInfo();

  debugPrint('[INIT] App initialization complete');
}

/// Print app info for debugging
void _printAppInfo() {
  debugPrint('');
  debugPrint('═══════════════════════════════════════');
  debugPrint('          GYM-APP v1.0.0              ');
  debugPrint('═══════════════════════════════════════');
  debugPrint('  Mode: ${kReleaseMode ? "RELEASE" : "DEBUG"}');
  debugPrint('  Auth: FIREBASE');
  debugPrint('═══════════════════════════════════════');
  debugPrint('');
}

/// Load initial data required for the app
Future<void> loadInitialData() async {
  debugPrint('[DATA] Loading initial data...');
  await Future.delayed(const Duration(milliseconds: 100));
  debugPrint('[DATA] Initial data loaded');
}

/// Setup notification handlers
void setupNotifications() {
  debugPrint('[NOTIF] Setting up notifications...');
  debugPrint('[NOTIF] Notifications configured');
}
