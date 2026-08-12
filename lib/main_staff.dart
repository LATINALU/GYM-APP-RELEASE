import 'package:flutter/material.dart';

import 'core/app_flavor.dart';
import 'core/bootstrap.dart';
import 'main.dart' show QuantumApp;
import 'src/presentation/router/app_router.dart';

/// App publicada para trabajadores/staff del gimnasio.
/// Build: flutter build apk --flavor staff -t lib/main_staff.dart
void main() async {
  await bootstrap(AppFlavor.staff);
  runApp(QuantumApp(router: AppRouter.build(AppFlavor.staff)));
}
