import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/ports/output/auth_repository_port.dart';
import '../../domain/ports/output/gym_repository_port.dart';
import '../../domain/ports/output/user_repository_port.dart';
import '../../domain/ports/output/exercise_repository_port.dart';
import '../../domain/ports/output/routine_repository_port.dart';
import '../../domain/ports/output/check_in_repository_port.dart';
import '../../domain/ports/output/access_code_repository_port.dart';
import '../../domain/ports/output/pending_registration_repository_port.dart';
import '../../domain/ports/output/settings_repository_port.dart';
import '../../domain/ports/output/nutrition_repository_port.dart';
import '../../domain/ports/output/recovery_repository_port.dart';
import '../../domain/ports/output/volume_repository_port.dart';
import '../../domain/ports/output/measurement_repository_port.dart';
import 'insforge.dart';

/// InsForge Service Locator
/// Initializes all InsForge services and provides them to the app
/// This replaces the Firebase-based service locator
class InsForgeServiceLocator {
  static final InsForgeServiceLocator _instance = InsForgeServiceLocator._();
  static InsForgeServiceLocator get instance => _instance;

  InsForgeServiceLocator._();

  late final InsForgeClient _client;
  late final InsForgeAuthRepository _authRepository;
  late final InsForgeGymRepository _gymRepository;
  late final InsForgeUserRepository _userRepository;
  late final InsForgeExerciseRepository _exerciseRepository;
  late final InsForgeRoutineRepository _routineRepository;
  late final InsForgeCheckInRepository _checkInRepository;
  late final InsForgeAccessCodeRepository _accessCodeRepository;
  late final InsForgePendingRegistrationRepository _pendingRegistrationRepository;
  late final InsForgeMembershipPlanRepository _membershipPlanRepository;
  late final InsForgeMeasurementRepository _measurementRepository;
  late final InsForgeSettingsRepository _settingsRepository;
  late final InsForgeNutritionRepository _nutritionRepository;
  late final InsForgeRecoveryRepository _recoveryRepository;
  late final InsForgeVolumeRepository _volumeRepository;
  late final InsForgeStorageService _storageService;

  bool _initialized = false;

  /// Initialize all InsForge services
  Future<void> initialize() async {
    if (_initialized) return;

    final baseUrl = dotenv.env['INSFORGE_API_URL'] ?? 'http://localhost:7130';
    final postgrestUrl = dotenv.env['INSFORGE_POSTGREST_URL'] ?? 'http://localhost:5430';

    debugPrint('[InsForge] Initializing with baseUrl: $baseUrl, postgrest: $postgrestUrl');

    // Initialize HTTP client
    _client = InsForgeClient.initialize(
      baseUrl: baseUrl,
      postgrestUrl: postgrestUrl,
    );

    // Restore persisted tokens (if user was previously logged in)
    await _client.restoreTokens();

    // Initialize all repositories
    _authRepository = InsForgeAuthRepository(_client);
    _gymRepository = InsForgeGymRepository(_client);
    _userRepository = InsForgeUserRepository(_client);
    _exerciseRepository = InsForgeExerciseRepository(_client);
    _routineRepository = InsForgeRoutineRepository(_client);
    _checkInRepository = InsForgeCheckInRepository(_client);
    _accessCodeRepository = InsForgeAccessCodeRepository(_client);
    _pendingRegistrationRepository = InsForgePendingRegistrationRepository(_client);
    _membershipPlanRepository = InsForgeMembershipPlanRepository(_client);
    _measurementRepository = InsForgeMeasurementRepository(_client);
    _settingsRepository = InsForgeSettingsRepository(_client);
    _nutritionRepository = InsForgeNutritionRepository(_client);
    _recoveryRepository = InsForgeRecoveryRepository(_client);
    _volumeRepository = InsForgeVolumeRepository(_client);
    _storageService = InsForgeStorageService(_client);

    _initialized = true;
    debugPrint('[InsForge] All services initialized successfully');
  }

  // ═══════════════════════════════════════════════════════════════════
  // GETTERS (typed as domain port interfaces)
  // ═══════════════════════════════════════════════════════════════════

  InsForgeClient get client => _client;

  AuthRepositoryPort get authRepository => _authRepository;
  InsForgeAuthRepository get authRepositoryImpl => _authRepository;

  GymRepositoryPort get gymRepository => _gymRepository;
  InsForgeGymRepository get gymRepositoryImpl => _gymRepository;

  UserRepositoryPort get userRepository => _userRepository;
  InsForgeUserRepository get userRepositoryImpl => _userRepository;

  ExerciseRepositoryPort get exerciseRepository => _exerciseRepository;
  InsForgeExerciseRepository get exerciseRepositoryImpl => _exerciseRepository;

  RoutineRepositoryPort get routineRepository => _routineRepository;
  InsForgeRoutineRepository get routineRepositoryImpl => _routineRepository;

  CheckInRepositoryPort get checkInRepository => _checkInRepository;
  InsForgeCheckInRepository get checkInRepositoryImpl => _checkInRepository;

  AccessCodeRepositoryPort get accessCodeRepository => _accessCodeRepository;
  InsForgeAccessCodeRepository get accessCodeRepositoryImpl => _accessCodeRepository;

  PendingRegistrationRepositoryPort get pendingRegistrationRepository => _pendingRegistrationRepository;
  InsForgePendingRegistrationRepository get pendingRegistrationRepositoryImpl => _pendingRegistrationRepository;

  InsForgeMembershipPlanRepository get membershipPlanRepository => _membershipPlanRepository;

  MeasurementRepositoryPort get measurementRepository => _measurementRepository;
  InsForgeMeasurementRepository get measurementRepositoryImpl => _measurementRepository;

  SettingsRepositoryPort get settingsRepository => _settingsRepository;
  InsForgeSettingsRepository get settingsRepositoryImpl => _settingsRepository;

  NutritionRepositoryPort get nutritionRepository => _nutritionRepository;
  InsForgeNutritionRepository get nutritionRepositoryImpl => _nutritionRepository;

  RecoveryRepositoryPort get recoveryRepository => _recoveryRepository;
  InsForgeRecoveryRepository get recoveryRepositoryImpl => _recoveryRepository;

  VolumeRepositoryPort get volumeRepository => _volumeRepository;
  InsForgeVolumeRepository get volumeRepositoryImpl => _volumeRepository;

  InsForgeStorageService get storageService => _storageService;

  /// Check if user is currently authenticated
  bool get isAuthenticated => _client.isAuthenticated;

  /// Dispose all services
  void dispose() {
    _authRepository.dispose();
    _client.dispose();
  }
}
