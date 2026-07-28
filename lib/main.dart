import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase
import 'package:gym_app/firebase_options.dart';
import 'package:gym_app/core/auth/auth_state_notifier.dart';

// Quantum Architecture
import 'src/infrastructure/config/di.dart';
import 'src/presentation/auth/bloc/auth_bloc.dart';
import 'src/presentation/theme/quantum_theme.dart';
import 'src/presentation/router/app_router.dart';
import 'src/application/use_cases/use_cases.dart';
import 'src/infrastructure/services/local_cache_service.dart';
import 'src/infrastructure/services/connectivity_service.dart';
import 'src/domain/data/dataset_exercise_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Piloto Supabase (módulo Mediciones): config no-secreta por defecto en
  // .env.supabase.example, override local en .env.supabase (gitignored).
  await dotenv.load(fileName: '.env.supabase');

  // Initialize date formatting for Spanish
  await initializeDateFormatting('es_ES', null);

  // Initialize Hive for offline-first caching
  await Hive.initFlutter();
  await LocalCacheService.instance.init();
  await ConnectivityService.instance.init();

  // Initialize Firebase (real auth, Firestore, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check (Play Integrity on Android, Device Check on iOS).
  // En web requiere registrar un site key de ReCaptcha en la consola de
  // Firebase y pasarlo como ReCaptchaV3Provider — hasta entonces se omite.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  // Cargar el dataset de ejercicios (1,324 ejercicios con GIFs e
  // instrucciones en español) y fusionarlo con el catálogo estático
  final exercisesJson =
      await rootBundle.loadString('assets/data/exercises_dataset.json');
  DatasetExerciseCatalog.loadFromJsonString(exercisesJson);

  // Initialize DI (GetIt) — repos, use cases, adapters
  await configureDependencies();

  // App entrypoint always uses Firebase auth mode.
  // Mock mode is reserved for explicit test/dev entrypoints (e.g. main_admin).
  AuthStateNotifier.useMockAuth = false;

  // Apply Quantum dark system UI
  QuantumTheme.applySystemUI();

  runApp(const QuantumApp());
}

class QuantumApp extends StatelessWidget {
  const QuantumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Quantum BLoC providers (role-based auth system)
      providers: [
        BlocProvider(
          create:
              (_) => AuthBloc(
                loginUseCase: getIt<LoginUseCase>(),
                googleLoginUseCase: getIt<GoogleLoginUseCase>(),
                updateProfileUseCase: getIt<UpdateProfileUseCase>(),
              )..add(AuthCheckRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'QUANTUM GYM',
        debugShowCheckedModeBanner: false,
        theme: QuantumTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
