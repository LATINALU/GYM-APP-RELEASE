import '../../application/use_cases/use_cases.dart';
import '../../domain/ports/ports.dart';
import '../../presentation/bloc/app_bloc.dart';
import '../../presentation/screens/settings/bloc/settings_bloc.dart';
import 'di.dart';

/// Registro de BLoCs de presentación — separado de [configureCoreDependencies]
/// porque cada flavor solo necesita un subconjunto (a diferencia de los
/// repos/casos de uso/servicios, que son idénticos en las 4 apps).

/// La pantalla /settings es compartida por las 4 apps publicadas.
void registerSharedBlocs() {
  if (!getIt.isRegistered<SettingsBloc>()) {
    getIt.registerFactory<SettingsBloc>(
      () => SettingsBloc(getIt<SettingsRepositoryPort>()),
    );
  }
}

/// AppBloc alimenta el shell y el home del cliente (rachas, entrenos, etc.).
void registerClientBlocs() {
  if (!getIt.isRegistered<AppBloc>()) {
    getIt.registerFactory<AppBloc>(
      () => AppBloc(getClientProfileUseCase: getIt<GetClientProfileUseCase>()),
    );
  }
}
