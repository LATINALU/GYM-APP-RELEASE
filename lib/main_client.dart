import 'package:flutter/material.dart';

import 'core/app_flavor.dart';
import 'core/bootstrap.dart';
import 'main.dart' show QuantumApp;
import 'src/presentation/router/app_router.dart';

/// App publicada para clientes/socios del gimnasio.
/// Build: flutter build apk --flavor client -t lib/main_client.dart
void main() async {
  await bootstrap(AppFlavor.client);
  runApp(QuantumApp(router: AppRouter.build(AppFlavor.client)));
}
