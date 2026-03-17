import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/ports/output/settings_repository_port.dart';

// EVENTS
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateSettings extends SettingsEvent {
  final AppSettings settings;
  const UpdateSettings(this.settings);
  @override
  List<Object?> get props => [settings];
}

// STATES
abstract class SettingsState extends Equatable {
  final AppSettings settings;
  const SettingsState(this.settings);
  @override
  List<Object?> get props => [settings];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial() : super(const AppSettings());
}

class SettingsLoading extends SettingsState {
  const SettingsLoading(super.settings);
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(super.settings);
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(super.settings, this.message);
  @override
  List<Object?> get props => [settings, message];
}

// BLOC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepositoryPort _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading(state.settings));
    try {
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(state.settings, e.toString()));
    }
  }

  Future<void> _onUpdateSettings(UpdateSettings event, Emitter<SettingsState> emit) async {
    // Optimistic update
    final previousSettings = state.settings;
    emit(SettingsLoaded(event.settings));
    
    try {
      await _repository.saveSettings(event.settings);
    } catch (e) {
      emit(SettingsError(previousSettings, e.toString()));
    }
  }
}
