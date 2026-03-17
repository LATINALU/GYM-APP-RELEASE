import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Firebase
import 'package:gym_app/firebase_options.dart';
import 'package:gym_app/core/auth/auth_state_notifier.dart';

// Quantum legacy providers (mantiene funcionalidad real)
import 'package:gym_app/utillities/Providers/Auth%20Providers/FirebaseServices.dart';

// Quantum Architecture
import 'src/infrastructure/config/di.dart';
import 'src/presentation/auth/bloc/auth_bloc.dart';
import 'src/presentation/theme/quantum_theme.dart';
import 'src/presentation/router/app_router.dart';
import 'src/application/use_cases/use_cases.dart';

FirebaseServices firebaseServices = FirebaseServices();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize date formatting for Spanish
  await initializeDateFormatting('es_ES', null);

  // Initialize Firebase (real auth, Firestore, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return MultiProvider(
      // Quantum legacy providers (for Views/ functional screens)
      providers: [
        ChangeNotifierProvider<FirebaseServices>(
          create: (_) => firebaseServices,
        ),
      ],
      child: MultiBlocProvider(
        // Quantum BLoC providers (role-based auth system)
        providers: [
          BlocProvider(
            create:
                (_) => AuthBloc(
                  loginUseCase: getIt<LoginUseCase>(),
                  updateProfileUseCase: getIt<UpdateProfileUseCase>(),
                )..add(AuthCheckRequested()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Quantum',
          debugShowCheckedModeBanner: false,
          theme: QuantumTheme.darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
