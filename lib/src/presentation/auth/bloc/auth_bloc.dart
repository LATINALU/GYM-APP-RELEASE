import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../../../application/use_cases/use_cases.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS
// ═══════════════════════════════════════════════════════════════════════════

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

class LogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class RegisterGymRequested extends AuthEvent {
  final String gymName;
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  const RegisterGymRequested({
    required this.gymName,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
}

class UpdateProfileRequested extends AuthEvent {
  final User user;
  const UpdateProfileRequested(this.user);
  @override
  List<Object?> get props => [user];
}

// ═══════════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════════

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final UserProfile profile;
  const Authenticated({required this.user, required this.profile});
  @override
  List<Object?> get props => [user, profile];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════
// BLOC
// ═══════════════════════════════════════════════════════════════════════════

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthStateNotifier _authStateNotifier = AuthStateNotifier.instance;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _loginUseCase = loginUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);

    // Listen to profile changes in the global notifier
    _authStateNotifier.addListener(_syncWithNotifier);
  }

  void _syncWithNotifier() {
    if (_authStateNotifier.isAuthenticated &&
        _authStateNotifier.profile != null) {
      // Mapping from AuthStateNotifier profile to a dummy User object for Bloc
      // In production, we'd fetch the full User entity
      add(AuthCheckRequested());
    } else if (!_authStateNotifier.isAuthenticated) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _loginUseCase.execute(
      LoginCommand(email: event.email, password: event.password),
    );

    await result.fold(
      (failure) async => emit(AuthFailure(_mapFailureToMessage(failure))),
      (_) async {
        await _authStateNotifier.refreshProfile();
        add(AuthCheckRequested());
      },
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_authStateNotifier.isAuthenticated &&
        _authStateNotifier.profile != null) {
      final profile = _authStateNotifier.profile!;
      emit(
        Authenticated(
          user: User.restore(
            id: UserId(profile.uid),
            email: Email(profile.email),
            name: PersonName(firstName: profile.displayName, lastName: ''),
            role: profile.role ?? const GymRole.client(),
            gymId: profile.gymId ?? GymId.generate(),
            createdAt: DateTime.now(),
            weight: profile.weight,
            height: profile.height,
            fitnessGoal: profile.fitnessGoal,
            membershipStatus:
                profile.membershipStatus ?? MembershipStatus.pending,
            membershipExpiresAt: profile.membershipExpiresAt,
          ),
          profile: profile,
        ),
      );
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authStateNotifier.signOut();
    emit(Unauthenticated());
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _updateProfileUseCase.execute(event.user);

    result.fold((failure) => emit(AuthFailure(_mapFailureToMessage(failure))), (
      _,
    ) async {
      // Force refresh the local state
      await _authStateNotifier.refreshProfile();
      add(AuthCheckRequested());
    });
  }

  String _mapFailureToMessage(dynamic failure) {
    // SECURITY: Limit technical detail in UI error messages
    return 'Credenciales inválidas o error de conexión. Inténtalo de nuevo.';
  }

  @override
  Future<void> close() {
    _authStateNotifier.removeListener(_syncWithNotifier);
    return super.close();
  }
}
