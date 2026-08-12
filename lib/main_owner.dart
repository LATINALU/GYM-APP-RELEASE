import 'package:flutter/material.dart';

import 'core/app_flavor.dart';
import 'core/bootstrap.dart';
import 'main.dart' show QuantumApp;
import 'src/presentation/router/app_router.dart';

/// App publicada para dueños de gimnasio. También es el target de la build
/// de escritorio (flutter build windows -t lib/main_owner.dart).
/// Build Android: flutter build apk --flavor owner -t lib/main_owner.dart
void main() async {
  await bootstrap(AppFlavor.owner);
  runApp(QuantumApp(router: AppRouter.build(AppFlavor.owner)));
}
