import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../domain/ports/ports.dart';
import '../../domain/ports/input/manage_routine_usecase_port.dart';
import '../../application/use_cases/use_cases.dart';
import '../../application/services/admin_metrics_service.dart';
import '../../application/services/gamification_service.dart';
import '../../application/services/recovery_service.dart';
import '../../application/services/volume_tracking_service.dart';
import '../../application/services/nutrition_service.dart';
import '../adapters/firebase/firebase_adapters.dart';
import '../adapters/firebase/firebase_owner_member_repository.dart';
import '../adapters/local/local_exercise_repository.dart';
import '../adapters/local/exercise_media_factory.dart';
import '../adapters/cached_assignment_repository.dart';
import '../adapters/cached_routine_repository.dart';
import '../adapters/cached_check_in_repository.dart';
import '../adapters/cached_user_repository.dart';
import '../services/local_cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/rust_member_number_allocator.dart';
import '../../presentation/bloc/app_bloc.dart';
import '../../presentation/screens/settings/bloc/settings_bloc.dart';
import '../../presentation/routines/bloc/routine_bloc.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> configureDependencies() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // EXTERNAL SERVICES (Firebase)
  // ═══════════════════════════════════════════════════════════════════════════
  
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  
  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  }
  
  if (!getIt.isRegistered<FirebaseMessaging>()) {
    getIt.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  }

  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(() => http.Client());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPOSITORIES (Output Ports)
  // ═══════════════════════════════════════════════════════════════════════════
  
  if (!getIt.isRegistered<AuthRepositoryPort>()) {
    getIt.registerLazySingleton<AuthRepositoryPort>(
      () => FirebaseAuthRepository(getIt<FirebaseAuth>(), getIt<FirebaseFirestore>()),
    );
  }
  
  if (!getIt.isRegistered<UserRepositoryPort>()) {
    getIt.registerLazySingleton<UserRepositoryPort>(
      () => CachedUserRepository(
        FirebaseUserRepository(getIt<FirebaseFirestore>()),
        LocalCacheService.instance,
        ConnectivityService.instance,
      ),
    );
  }
  
  if (!getIt.isRegistered<GymRepositoryPort>()) {
    getIt.registerLazySingleton<GymRepositoryPort>(
      () => FirebaseGymRepository(getIt<FirebaseFirestore>()),
    );
  }
  
  // Media local de ejercicios (GIFs persistidos para uso sin internet)
  if (!getIt.isRegistered<ExerciseMediaPort>()) {
    getIt.registerLazySingleton<ExerciseMediaPort>(
      () => createExerciseMediaService(getIt<http.Client>()),
    );
  }

  if (!getIt.isRegistered<RoutineRepositoryPort>()) {
    getIt.registerLazySingleton<RoutineRepositoryPort>(
      () => CachedRoutineRepository(
        FirebaseRoutineRepository(getIt<FirebaseFirestore>()),
        LocalCacheService.instance,
        ConnectivityService.instance,
        media: getIt<ExerciseMediaPort>(),
      ),
    );
  }
  
  if (!getIt.isRegistered<AssignmentRepositoryPort>()) {
    getIt.registerLazySingleton<AssignmentRepositoryPort>(
      () => CachedAssignmentRepository(
        FirebaseAssignmentRepository(getIt<FirebaseFirestore>()),
        LocalCacheService.instance,
        ConnectivityService.instance,
      ),
    );
  }
  
  if (!getIt.isRegistered<CheckInRepositoryPort>()) {
    getIt.registerLazySingleton<CheckInRepositoryPort>(
      () => CachedCheckInRepository(
        FirebaseCheckInRepository(getIt<FirebaseFirestore>()),
        LocalCacheService.instance,
        ConnectivityService.instance,
      ),
    );
  }
  
  if (!getIt.isRegistered<SettingsRepositoryPort>()) {
    getIt.registerLazySingleton<SettingsRepositoryPort>(
      () => FirebaseSettingsRepository(
        getIt<FirebaseFirestore>(),
        () => getIt<FirebaseAuth>().currentUser?.uid ?? 'anonymous',
      ),
    );
  }

  if (!getIt.isRegistered<EmailServicePort>()) {
    getIt.registerLazySingleton<EmailServicePort>(
      () => FirebaseEmailService(getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<NotificationServicePort>()) {
    getIt.registerLazySingleton<NotificationServicePort>(
      () => FirebaseNotificationService(getIt<FirebaseFirestore>()),
    );
  }

  // Exercise Repository (Local)
  if (!getIt.isRegistered<ExerciseRepositoryPort>()) {
    getIt.registerLazySingleton<ExerciseRepositoryPort>(
      () => LocalExerciseRepository(),
    );
  }

  // Firebase Exercise Repository (for CRUD operations on exercises collection)
  if (!getIt.isRegistered<FirebaseExerciseRepository>()) {
    getIt.registerLazySingleton<FirebaseExerciseRepository>(
      () => FirebaseExerciseRepository(getIt<FirebaseFirestore>()),
    );
  }

  // Owner Member Repository (gym-scoped members + audit logs)
  if (!getIt.isRegistered<FirebaseOwnerMemberRepository>()) {
    getIt.registerLazySingleton<FirebaseOwnerMemberRepository>(
      () => FirebaseOwnerMemberRepository(getIt<FirebaseFirestore>()),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USE CASES (Input Ports)
  // ═══════════════════════════════════════════════════════════════════════════
  
  if (!getIt.isRegistered<EnsurePendingRegistrationUseCase>()) {
    getIt.registerFactory<EnsurePendingRegistrationUseCase>(
      () => EnsurePendingRegistrationUseCase(
        pendingRegistrationRepository: getIt<PendingRegistrationRepositoryPort>(),
        gymRepository: getIt<GymRepositoryPort>(),
      ),
    );
  }

  if (!getIt.isRegistered<RegisterUseCase>()) {
    getIt.registerFactory<RegisterUseCase>(
      () => RegisterUseCase(
        authRepository: getIt<AuthRepositoryPort>(),
        gymRepository: getIt<GymRepositoryPort>(),
        ensurePendingRegistrationUseCase: getIt<EnsurePendingRegistrationUseCase>(),
      ),
    );
  }
  
  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerFactory<LoginUseCase>(
      () => LoginUseCase(authRepository: getIt<AuthRepositoryPort>()),
    );
  }

  if (!getIt.isRegistered<GoogleLoginUseCase>()) {
    getIt.registerFactory<GoogleLoginUseCase>(
      () => GoogleLoginUseCase(
        authRepository: getIt<AuthRepositoryPort>(),
        ensurePendingRegistrationUseCase: getIt<EnsurePendingRegistrationUseCase>(),
      ),
    );
  }
  
  if (!getIt.isRegistered<CheckInUseCase>()) {
    getIt.registerFactory<CheckInUseCase>(
      () => CheckInUseCase(
        checkInRepository: getIt<CheckInRepositoryPort>(),
        userRepository: getIt<UserRepositoryPort>(),
      ),
    );
  }
  
  if (!getIt.isRegistered<ManageRoutineUseCasePort>()) {
    getIt.registerFactory<ManageRoutineUseCasePort>(
      () => ManageRoutineUseCase(
        userRepository: getIt<UserRepositoryPort>(),
        routineRepository: getIt<RoutineRepositoryPort>(),
      ),
    );
  }

  // Rutinas predefinidas del dataset (creación idempotente, no destructiva)
  if (!getIt.isRegistered<SeedRoutinesUseCase>()) {
    getIt.registerFactory<SeedRoutinesUseCase>(
      () => SeedRoutinesUseCase(
        manageRoutines: getIt<ManageRoutineUseCasePort>(),
      ),
    );
  }
  
  if (!getIt.isRegistered<GetDashboardDataUseCase>()) {
    getIt.registerFactory<GetDashboardDataUseCase>(
      () => GetDashboardDataUseCase(
        gymRepository: getIt<GymRepositoryPort>(),
        userRepository: getIt<UserRepositoryPort>(),
        checkInRepository: getIt<CheckInRepositoryPort>(),
        assignmentRepository: getIt<AssignmentRepositoryPort>(),
        routineRepository: getIt<RoutineRepositoryPort>(),
      ),
    );
  }

  if (!getIt.isRegistered<UpdateProfileUseCase>()) {
    getIt.registerFactory<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(getIt<AuthRepositoryPort>()),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // NEW REPOSITORIES (Recovery & Volume)
  // ═══════════════════════════════════════════════════════════════════════════

  if (!getIt.isRegistered<RecoveryRepositoryPort>()) {
    getIt.registerLazySingleton<RecoveryRepositoryPort>(
      () => FirebaseRecoveryRepository(getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<VolumeRepositoryPort>()) {
    getIt.registerLazySingleton<VolumeRepositoryPort>(
      () => FirebaseVolumeRepository(getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<NutritionRepositoryPort>()) {
    getIt.registerLazySingleton<NutritionRepositoryPort>(
      () => FirebaseNutritionRepository(getIt<FirebaseFirestore>()),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPLICATION SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  if (!getIt.isRegistered<AdminMetricsService>()) {
    getIt.registerFactory<AdminMetricsService>(
      () => AdminMetricsService(firestore: getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<GamificationService>()) {
    getIt.registerFactory<GamificationService>(
      () => GamificationService(firestore: getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<RecoveryService>()) {
    getIt.registerFactory<RecoveryService>(
      () => RecoveryService(getIt<RecoveryRepositoryPort>()),
    );
  }

  if (!getIt.isRegistered<NutritionService>()) {
    getIt.registerFactory<NutritionService>(
      () => NutritionService(getIt<NutritionRepositoryPort>()),
    );
  }

  if (!getIt.isRegistered<VolumeTrackingService>()) {
    getIt.registerFactory<VolumeTrackingService>(
      () => VolumeTrackingService(getIt<VolumeRepositoryPort>()),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENT USE CASES
  // ═══════════════════════════════════════════════════════════════════════════

  if (!getIt.isRegistered<GetClientProfileUseCase>()) {
    getIt.registerFactory<GetClientProfileUseCase>(
      () => GetClientProfileUseCase(
        assignmentRepository: getIt<AssignmentRepositoryPort>(),
        routineRepository: getIt<RoutineRepositoryPort>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTINE ASSIGNMENT USE CASES
  // ═══════════════════════════════════════════════════════════════════════════

  if (!getIt.isRegistered<AssignRoutineUseCase>()) {
    getIt.registerFactory<AssignRoutineUseCase>(
      () => AssignRoutineUseCase(
        userRepository: getIt<UserRepositoryPort>(),
        routineRepository: getIt<RoutineRepositoryPort>(),
        assignmentRepository: getIt<AssignmentRepositoryPort>(),
      ),
    );
  }

  if (!getIt.isRegistered<ImportRoutineFromQrUseCase>()) {
    getIt.registerFactory<ImportRoutineFromQrUseCase>(
      () => ImportRoutineFromQrUseCase(
        userRepository: getIt<UserRepositoryPort>(),
        routineRepository: getIt<RoutineRepositoryPort>(),
        assignmentRepository: getIt<AssignmentRepositoryPort>(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOCS - Consolidated to 4 main functions
  // ═══════════════════════════════════════════════════════════════════════════
  
  // AppBloc - Unified state management (replaces HomeBloc + ClientBloc)
  if (!getIt.isRegistered<AppBloc>()) {
    getIt.registerFactory<AppBloc>(
      () => AppBloc(getClientProfileUseCase: getIt<GetClientProfileUseCase>()),
    );
  }

  // RoutineBloc - Routine management
  if (!getIt.isRegistered<RoutineBloc>()) {
    getIt.registerFactory<RoutineBloc>(
      () => RoutineBloc(
        manageRoutineUseCase: getIt<ManageRoutineUseCasePort>(),
        seedRoutinesUseCase: getIt<SeedRoutinesUseCase>(),
      ),
    );
  }

  // SettingsBloc - App settings
  if (!getIt.isRegistered<SettingsBloc>()) {
    getIt.registerFactory<SettingsBloc>(
      () => SettingsBloc(getIt<SettingsRepositoryPort>()),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING REGISTRATION & ACCESS CODES
  // ═══════════════════════════════════════════════════════════════════════════

  if (!getIt.isRegistered<PendingRegistrationRepositoryPort>()) {
    getIt.registerLazySingleton<PendingRegistrationRepositoryPort>(
      () => FirebasePendingRegistrationRepository(getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<AccessCodeRepositoryPort>()) {
    getIt.registerLazySingleton<AccessCodeRepositoryPort>(
      () => FirebaseAccessCodeRepository(getIt<FirebaseFirestore>()),
    );
  }

  if (!getIt.isRegistered<MemberNumberAllocatorPort>()) {
    getIt.registerLazySingleton<MemberNumberAllocatorPort>(
      () => RustMemberNumberAllocator(
        httpClient: getIt<http.Client>(),
        firebaseAuth: getIt<FirebaseAuth>(),
      ),
    );
  }

  if (!getIt.isRegistered<ReviewRegistrationUseCase>()) {
    getIt.registerFactory<ReviewRegistrationUseCase>(
      () => ReviewRegistrationUseCase(
        registrationRepository: getIt<PendingRegistrationRepositoryPort>(),
        userRepository: getIt<UserRepositoryPort>(),
        memberNumberAllocator: getIt<MemberNumberAllocatorPort>(),
      ),
    );
  }
}

/// Register a singleton dependency
void registerSingleton<T extends Object>(T instance) {
  getIt.registerSingleton<T>(instance);
}

/// Register a lazy singleton
void registerLazySingleton<T extends Object>(T Function() factory) {
  getIt.registerLazySingleton<T>(factory);
}

/// Register a factory
void registerFactory<T extends Object>(T Function() factory) {
  getIt.registerFactory<T>(factory);
}

/// Get a registered dependency
T get<T extends Object>() => getIt<T>();

/// Check if a dependency is registered
bool isRegistered<T extends Object>() => getIt.isRegistered<T>();

/// Reset all registrations (for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

