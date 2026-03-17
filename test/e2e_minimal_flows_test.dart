import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/auth/auth_state_notifier.dart';
import 'package:gym_app/core/errors/failures.dart';
import 'package:gym_app/core/types/typedefs.dart';
import 'package:gym_app/src/application/use_cases/use_cases.dart';
import 'package:gym_app/src/domain/entities/workout_plan.dart';
import 'package:gym_app/src/presentation/auth/bloc/auth_bloc.dart';
import 'package:gym_app/src/presentation/auth/pages/login_screen.dart';
import 'package:gym_app/src/presentation/bloc/app_bloc.dart';
import 'package:gym_app/src/presentation/screens/client/routine_selection_screen.dart';
import 'package:gym_app/src/presentation/screens/owner/finance_subscriptions_screen.dart';

class _StubAppBloc extends AppBloc {
  _StubAppBloc(AppState initialState)
    : super(getClientProfileUseCase: null as dynamic) {
    emit(initialState);
  }
}

class _NoopLoginUseCase extends LoginUseCase {
  _NoopLoginUseCase() : super(authRepository: null as dynamic);

  @override
  FutureResult<LoginResult> execute(LoginCommand command) async {
    return left(const ServerFailure(message: 'Test sin autenticación remota'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AuthStateNotifier.instance.signOut();
  });

  tearDown(() async {
    await AuthStateNotifier.instance.signOut();
  });

  testWidgets('E2E mínimo - render de login', (tester) async {
    final authBloc = AuthBloc(
      loginUseCase: _NoopLoginUseCase(),
      updateProfileUseCase: null as dynamic,
    )..add(AuthCheckRequested());

    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Iniciar Sesión'), findsWidgets);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('E2E mínimo - rutina abre clientDailyWorkout', (tester) async {
    final bloc = _StubAppBloc(
      AppLoaded(assignedPlan: WorkoutPlan.beginnerFullBody()),
    );

    addTearDown(bloc.close);

    final router = GoRouter(
      initialLocation: '/routine',
      routes: [
        GoRoute(
          path: '/routine',
          builder: (context, state) {
            return BlocProvider<AppBloc>.value(
              value: bloc,
              child: const RoutineSelectionScreen(),
            );
          },
        ),
        GoRoute(
          path: '/client/daily-workout',
          name: 'clientDailyWorkout',
          builder: (context, state) {
            return const Scaffold(
              body: Center(child: Text('WORKOUT_SCREEN_TEST')),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTINUAR SESIÓN').first);
    await tester.pumpAndSettle();

    expect(find.text('WORKOUT_SCREEN_TEST'), findsOneWidget);
  });

  testWidgets('E2E mínimo - pago muestra estado controlado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FinanceSubscriptionsScreen())),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Control de Cobros'), findsOneWidget);

    final hasErrorBanner =
        find
            .textContaining('No se pudieron cargar los datos financieros')
            .evaluate()
            .isNotEmpty;
    final hasEmptyPayments =
        find
            .text('No hay cobros para el filtro seleccionado.')
            .evaluate()
            .isNotEmpty;

    expect(hasErrorBanner || hasEmptyPayments, isTrue);
  });
}
