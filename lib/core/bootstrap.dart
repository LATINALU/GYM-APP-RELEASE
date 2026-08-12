import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../firebase_options.dart';
import '../src/infrastructure/config/di.dart';
import '../src/infrastructure/config/presentation_di.dart';
import '../src/infrastructure/services/local_cache_service.dart';
import '../src/infrastructure/services/connectivity_service.dart';
import '../src/domain/data/dataset_exercise_catalog.dart';
import '../src/presentation/theme/quantum_theme.dart';
import 'app_flavor.dart';
import 'auth/auth_state_notifier.dart';

/// Shared startup sequence for the 4 published apps (client/staff/owner/admin).
/// Each `lib/main_<flavor>.dart` entry point awaits this before `runApp()`.
Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Piloto Supabase self-hosted: config no-secreta por defecto en
  // .env.supabase.example, override local en .env.supabase (gitignored).
  await dotenv.load(fileName: '.env.supabase');

  await initializeDateFormatting('es_ES', null);

  await Hive.initFlutter();
  await LocalCacheService.instance.init();
  await ConnectivityService.instance.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check (Play Integrity on Android, Device Check on iOS).
  // En web requiere registrar un site key de ReCaptcha en la consola de
  // Firebase y pasarlo como ReCaptchaV3Provider — hasta entonces se omite.
  // En desktop (Windows/macOS/Linux, target del flavor owner) tampoco hay
  // provider de Play Integrity/Device Check disponible — se omite también.
  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!kIsWeb && isMobile) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  // Cargar el dataset de ejercicios (1,324 ejercicios con GIFs e
  // instrucciones en español) y fusionarlo con el catálogo estático.
  final exercisesJson = await rootBundle.loadString(
    'assets/data/exercises_dataset.json',
  );
  DatasetExerciseCatalog.loadFromJsonString(exercisesJson);

  // Initialize DI (GetIt) — repos, use cases, adapters (rol-agnóstico).
  await configureCoreDependencies();

  // BLoCs de presentación: settings es compartido, AppBloc es solo cliente.
  registerSharedBlocs();
  if (flavor == AppFlavor.client) {
    registerClientBlocs();
  }

  // Las 4 apps publicadas siempre corren contra el backend real.
  // El modo mock queda reservado para tests.
  AuthStateNotifier.useMockAuth = false;

  QuantumTheme.applySystemUI();
}
