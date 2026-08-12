import 'package:flutter/material.dart';

import 'core/app_flavor.dart';
import 'core/bootstrap.dart';
import 'main.dart' show QuantumApp;
import 'src/presentation/router/app_router.dart';

/// Herramienta interna de super-admin (gestión de toda la plataforma:
/// gimnasios, dueños, facturación, auditoría). NO se publica en tiendas.
/// Build: flutter build apk --flavor admin -t lib/main_admin.dart
void main() async {
  await bootstrap(AppFlavor.admin);
  runApp(QuantumApp(router: AppRouter.build(AppFlavor.admin)));
}
