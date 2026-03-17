/// InsForge Infrastructure Layer
/// Complete backend integration replacing Firebase with InsForge (PostgREST + JWT)
///
/// Architecture:
///   Flutter App → InsForgeClient → PostgREST API → PostgreSQL
///   Flutter App → InsForgeClient → InsForge Auth API → JWT tokens
///   Flutter App → InsForgeClient → InsForge Storage → S3/Local files

export 'insforge_client.dart';
export 'insforge_service_locator.dart';
export 'insforge_auth_repository.dart';
export 'insforge_gym_repository.dart';
export 'insforge_user_repository.dart';
export 'insforge_exercise_repository.dart';
export 'insforge_routine_repository.dart';
export 'insforge_checkin_repository.dart';
export 'insforge_access_code_repository.dart';
export 'insforge_pending_registration_repository.dart';
export 'insforge_membership_plan_repository.dart';
export 'insforge_measurement_repository.dart';
export 'insforge_settings_repository.dart';
export 'insforge_nutrition_repository.dart';
export 'insforge_recovery_repository.dart';
export 'insforge_volume_repository.dart';
export 'insforge_storage_service.dart';
