import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/app_flavor.dart';
import 'core/bootstrap.dart';
import 'src/infrastructure/config/di.dart';
import 'src/presentation/auth/bloc/auth_bloc.dart';
import 'src/presentation/theme/quantum_theme.dart';
import 'src/presentation/router/app_router.dart';
import 'src/application/use_cases/use_cases.dart';

/// Entry point por defecto para `flutter run` sin `-t` explícito (solo dev).
/// Los 4 builds publicados usan lib/main_client.dart, lib/main_staff.dart,
/// lib/main_owner.dart y lib/main_admin.dart.
void main() async {
  await bootstrap(AppFlavor.client);
  runApp(QuantumApp(router: AppRouter.build(AppFlavor.client)));
}

class QuantumApp extends StatelessWidget {
  final GoRouter router;

  const QuantumApp({super.key, required this.router});

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
        routerConfig: router,
      ),
    );
  }
}
