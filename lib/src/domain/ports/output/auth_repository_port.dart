import '../../../../core/types/typedefs.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';

/// Auth credentials for login
class AuthCredentials {
  final Email email;
  final String password;

  const AuthCredentials({
    required this.email,
    required this.password,
  });
}

/// Auth result after successful authentication
class AuthResult {
  final User user;
  final String token;

  const AuthResult({
    required this.user,
    required this.token,
  });
}

/// Output Port - Auth Repository Interface
abstract class AuthRepositoryPort {
  /// Login with email and password
  FutureResult<AuthResult> login(AuthCredentials credentials);

  /// Register new user
  FutureResult<AuthResult> register({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    GymId? gymId,
    double? weight,
    double? height,
    String? fitnessGoal,
  });

  FutureResult<AuthResult> signInWithGoogle({
    GymCode? gymCode,
  });

  FutureResult<AuthResult> provisionUser({
    required Email email,
    required String password,
    required PersonName name,
    required GymRole role,
    required GymId gymId,
    PhoneNumber? phone,
  });

  /// Logout current user
  FutureVoidResult logout();

  /// Get current authenticated user
  FutureResult<User?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Send password reset email
  FutureVoidResult sendPasswordReset(Email email);

  /// Change password
  FutureVoidResult changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update user profile data
  FutureVoidResult updateProfile(User user);

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;
}
