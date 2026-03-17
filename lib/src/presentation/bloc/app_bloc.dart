import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../application/use_cases/client/get_client_profile_usecase.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS - Unified App Events
// ═══════════════════════════════════════════════════════════════════════════

abstract class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => [];
}

class LoadAppData extends AppEvent {
  final UserId userId;
  final GymId gymId;
  const LoadAppData({required this.userId, required this.gymId});
  @override
  List<Object?> get props => [userId, gymId];
}

class RefreshAppData extends AppEvent {
  final UserId userId;
  final GymId gymId;
  const RefreshAppData({required this.userId, required this.gymId});
  @override
  List<Object?> get props => [userId, gymId];
}

class WorkoutCompleted extends AppEvent {
  final WorkoutSession session;
  const WorkoutCompleted(this.session);
  @override
  List<Object?> get props => [session];
}

// ═══════════════════════════════════════════════════════════════════════════
// STATES - Unified App State
// ═══════════════════════════════════════════════════════════════════════════

abstract class AppState extends Equatable {
  const AppState();
  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {}

class AppLoading extends AppState {}

class AppLoaded extends AppState {
  // User & Fitness Profile
  final UserFitnessProfile? fitnessProfile;
  
  // Workout Data
  final List<WorkoutSession> recentSessions;
  final WorkoutPlan? assignedPlan;
  
  // Stats
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final int workoutsThisWeek;
  final double weeklyVolume;
  final Map<String, double> muscleVolumeMap;
  final Map<String, PersonalRecord> personalRecords;
  final List<int> weeklyFrequency;

  const AppLoaded({
    this.fitnessProfile,
    this.recentSessions = const [],
    this.assignedPlan,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.workoutsThisWeek = 0,
    this.weeklyVolume = 0,
    this.muscleVolumeMap = const {},
    this.personalRecords = const {},
    this.weeklyFrequency = const [],
  });

  // Convenience getters
  WorkoutDay? get todaysWorkout => assignedPlan?.todaysWorkout;
  int get estimatedCalories => recentSessions.isNotEmpty 
      ? recentSessions.first.estimatedCalories 
      : 0;

  @override
  List<Object?> get props => [
    fitnessProfile,
    recentSessions,
    assignedPlan,
    currentStreak,
    longestStreak,
    totalWorkouts,
    workoutsThisWeek,
    weeklyVolume,
    muscleVolumeMap,
    personalRecords,
    weeklyFrequency,
  ];

  AppLoaded copyWith({
    UserFitnessProfile? fitnessProfile,
    List<WorkoutSession>? recentSessions,
    WorkoutPlan? assignedPlan,
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    int? workoutsThisWeek,
    double? weeklyVolume,
    Map<String, double>? muscleVolumeMap,
    Map<String, PersonalRecord>? personalRecords,
    List<int>? weeklyFrequency,
  }) {
    return AppLoaded(
      fitnessProfile: fitnessProfile ?? this.fitnessProfile,
      recentSessions: recentSessions ?? this.recentSessions,
      assignedPlan: assignedPlan ?? this.assignedPlan,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      workoutsThisWeek: workoutsThisWeek ?? this.workoutsThisWeek,
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      muscleVolumeMap: muscleVolumeMap ?? this.muscleVolumeMap,
      personalRecords: personalRecords ?? this.personalRecords,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
    );
  }
}

class AppError extends AppState {
  final String message;
  const AppError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════
// BLOC - Unified App BLoC
// ═══════════════════════════════════════════════════════════════════════════

class AppBloc extends Bloc<AppEvent, AppState> {
  final GetClientProfileUseCase _getClientProfileUseCase;

  AppBloc({required GetClientProfileUseCase getClientProfileUseCase})
      : _getClientProfileUseCase = getClientProfileUseCase,
        super(AppInitial()) {
    on<LoadAppData>(_onLoadAppData);
    on<RefreshAppData>(_onRefreshAppData);
    on<WorkoutCompleted>(_onWorkoutCompleted);
  }

  Future<void> _onLoadAppData(LoadAppData event, Emitter<AppState> emit) async {
    emit(AppLoading());
    final result = await _getClientProfileUseCase.execute(event.userId, event.gymId);
    result.fold(
      (failure) => emit(AppError(failure.message)),
      (data) {
        // Calculate weekly frequency as List<int> from List<Map>
        final weeklyFreq = data.weeklyFrequency.map((e) => (e['count'] as int? ?? 0)).toList();
        
        emit(AppLoaded(
          fitnessProfile: data.fitnessProfile,
          recentSessions: data.recentSessions,
          assignedPlan: data.assignedPlan,
          currentStreak: data.fitnessProfile.currentStreak,
          longestStreak: data.fitnessProfile.longestStreak,
          totalWorkouts: data.fitnessProfile.totalWorkouts,
          workoutsThisWeek: data.recentSessions.where((s) => 
            s.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
          ).length,
          weeklyVolume: data.totalVolume,
          muscleVolumeMap: data.muscleVolumeMap,
          personalRecords: data.fitnessProfile.personalRecords,
          weeklyFrequency: weeklyFreq,
        ));
      },
    );
  }

  Future<void> _onRefreshAppData(RefreshAppData event, Emitter<AppState> emit) async {
    // Keep current state while refreshing
    final currentState = state;
    final result = await _getClientProfileUseCase.execute(event.userId, event.gymId);
    result.fold(
      (failure) {
        // On error, keep current state
        if (currentState is AppLoaded) {
          emit(currentState);
        } else {
          emit(AppError(failure.message));
        }
      },
      (data) {
        // Calculate weekly frequency as List<int> from List<Map>
        final weeklyFreq = data.weeklyFrequency.map((e) => (e['count'] as int? ?? 0)).toList();
        
        emit(AppLoaded(
          fitnessProfile: data.fitnessProfile,
          recentSessions: data.recentSessions,
          assignedPlan: data.assignedPlan,
          currentStreak: data.fitnessProfile.currentStreak,
          longestStreak: data.fitnessProfile.longestStreak,
          totalWorkouts: data.fitnessProfile.totalWorkouts,
          workoutsThisWeek: data.recentSessions.where((s) => 
            s.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
          ).length,
          weeklyVolume: data.totalVolume,
          muscleVolumeMap: data.muscleVolumeMap,
          personalRecords: data.fitnessProfile.personalRecords,
          weeklyFrequency: weeklyFreq,
        ));
      },
    );
  }

  void _onWorkoutCompleted(WorkoutCompleted event, Emitter<AppState> emit) {
    if (state is! AppLoaded) return;
    final currentState = state as AppLoaded;

    // Optimistic update: increment stats
    emit(currentState.copyWith(
      totalWorkouts: currentState.totalWorkouts + 1,
      workoutsThisWeek: currentState.workoutsThisWeek + 1,
      currentStreak: currentState.currentStreak + 1,
    ));
  }
}
