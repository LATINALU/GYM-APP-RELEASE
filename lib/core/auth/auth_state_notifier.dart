import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart' as sb;

import '../../src/domain/entities/entities.dart';
import '../../src/domain/value_objects/value_objects.dart';

/// Authentication state notifier for router integration
/// Implements ChangeNotifier to work with go_router's refreshListenable
///
/// Backend modes:
/// - **Firebase mode** (default): real auth against FirebaseAuth + Firestore
/// - **Supabase mode** (`useSupabaseAuth = true`): real auth against
///   Supabase Auth (GoTrue) + `public.gym_members`/`public.admins` — Fase 4
///   del plan de migración Firebase->Supabase. A diferencia de los demás
///   flags `USE_SUPABASE_*` (uno por módulo, pueden convivir), este es un
///   corte único: una sesión es Firebase o es Supabase, nunca ambas a la
///   vez, por eso vive como el mismo tipo de toggle estático que
///   `useMockAuth` en vez de leerse por adaptador.
/// - **Mock mode** (explicit): hardcoded credentials for test/dev entrypoints
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier._internal() {
    _initialize();
  }

  static final AuthStateNotifier _instance = AuthStateNotifier._internal();
  static AuthStateNotifier get instance => _instance;

  /// Set to true only in tests/dev explicit entrypoints.
  /// This flag is never auto-enabled as a fallback.
  static bool useMockAuth = false;

  /// Corte de Auth a Supabase (Fase 4). Default false = sigue en Firebase
  /// Auth hasta que se decida activarlo (requiere el hook de GoTrue ya
  /// desplegado en el VPS, ver supabase/migrations/0009_*).
  static bool useSupabaseAuth = false;

  // Lazy: en modo mock (tests) nunca se accede y no exige Firebase.initializeApp().
  late final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final sb.SupabaseClient _supabase = GetIt.I<sb.SupabaseClient>();
  StreamSubscription<fb.User?>? _firebaseAuthSubscription;
  StreamSubscription<sb.AuthState>? _supabaseAuthSubscription;

  bool _isAuthenticated = false;
  UserProfile? _profile;
  bool _isLoading = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserProfile? get profile => _profile;
  String? get userId => _profile?.uid;

  // Quick role checks
  bool get isAdmin => _profile?.role?.type == GymRoleType.admin;
  bool get isOwner => _profile?.role?.type == GymRoleType.owner;
  bool get isStaff => _profile?.role?.type == GymRoleType.employee;
  bool get isClient => _profile?.role?.type == GymRoleType.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // MOCK MODE
  // ═══════════════════════════════════════════════════════════════════════════
  // Mock credentials were intentionally removed.
  // In explicit mock mode, only manual profile injection via `login(UserProfile)`
  // is allowed for test/dev entrypoints.

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _initialize() {
    if (kReleaseMode && useMockAuth) {
      debugPrint(
        '[Auth] Mock auth is disabled in release. Forcing Firebase mode.',
      );
      useMockAuth = false;
    }

    if (useMockAuth) {
      debugPrint(
        '[Auth] Explicit MOCK mode enabled (credential login disabled).',
      );
      _isAuthenticated = false;
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (useSupabaseAuth) {
      debugPrint('[Auth] AuthStateNotifier initialized in SUPABASE mode.');
      _initSupabaseAuth();
      return;
    }

    debugPrint('[Auth] AuthStateNotifier initialized in FIREBASE mode.');
    _initFirebaseAuth();
  }

  void _initFirebaseAuth() {
    _isLoading = true;
    notifyListeners();

    _firebaseAuthSubscription?.cancel();
    _firebaseAuthSubscription = _firebaseAuth.authStateChanges().listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          _isAuthenticated = false;
          _profile = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        try {
          _profile = await _resolveProfile(firebaseUser);
          _isAuthenticated = true;
        } catch (e) {
          debugPrint('[Auth] Failed to resolve Firebase profile: $e');
          _isAuthenticated = false;
          _profile = null;
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object error) {
        debugPrint('[Auth] Firebase auth stream error: $error');
        _isAuthenticated = false;
        _profile = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _initSupabaseAuth() {
    _isLoading = true;
    notifyListeners();

    _supabaseAuthSubscription?.cancel();
    _supabaseAuthSubscription = _supabase.auth.onAuthStateChange.listen(
      (state) async {
        final supabaseUser = state.session?.user;
        if (supabaseUser == null) {
          _isAuthenticated = false;
          _profile = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        try {
          _profile = await _resolveSupabaseProfile(supabaseUser);
          _isAuthenticated = true;
        } catch (e) {
          debugPrint('[Auth] Failed to resolve Supabase profile: $e');
          _isAuthenticated = false;
          _profile = null;
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object error) {
        debugPrint('[Auth] Supabase auth stream error: $error');
        _isAuthenticated = false;
        _profile = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<UserProfile> _resolveProfile(fb.User firebaseUser) async {
    final idTokenResult = await firebaseUser.getIdTokenResult(true);
    final claims = idTokenResult.claims ?? const <String, dynamic>{};

    final claimGymId = claims['gymId']?.toString();
    GymRole? role = _parseRole(claims['role']);
    String? gymId = claimGymId;
    Map<String, dynamic>? userData;

    if (claimGymId != null && role != null) {
      final nestedDoc =
          await _firestore
              .collection('gyms')
              .doc(claimGymId)
              .collection('${role.type.name}s')
              .doc(firebaseUser.uid)
              .get();
      if (nestedDoc.exists && nestedDoc.data() != null) {
        userData = nestedDoc.data();
      }
    }

    if (userData == null) {
      final rootDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (rootDoc.exists && rootDoc.data() != null) {
        userData = rootDoc.data();
      }
    }

    if (userData != null) {
      role ??= _parseRole(userData['role']);
      gymId ??= userData['gymId']?.toString();
    }

    return UserProfile(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? userData?['email']?.toString() ?? '',
      displayName: _resolveDisplayName(firebaseUser, userData),
      role: role,
      gymId: gymId != null && gymId.isNotEmpty ? GymId(gymId) : null,
      photoUrl: firebaseUser.photoURL ?? userData?['photoUrl']?.toString(),
      weight: _parseDouble(userData?['weight']),
      height: _parseDouble(userData?['height']),
      fitnessGoal: userData?['fitnessGoal']?.toString(),
      membershipStatus: _parseMembershipStatus(userData?['membershipStatus']),
      membershipExpiresAt: _parseDateTime(userData?['membershipExpiresAt']),
    );
  }

  /// Equivalente Supabase de [_resolveProfile]. A diferencia de Firebase, acá
  /// no hace falta decodificar el JWT para leer app_role/gym_id — se
  /// consulta directo `gym_members` (o `admins` si no está ahí), que es
  /// justamente el mismo patrón que en Firebase YA terminaba usándose en la
  /// práctica: ningún archivo del repo llamó nunca `setCustomUserClaims`,
  /// así que el camino de "leer claims del token" jamás tuvo datos reales —
  /// el doc-lookup era, de hecho, el único camino que funcionaba.
  Future<UserProfile> _resolveSupabaseProfile(sb.User supabaseUser) async {
    final memberRow = await _supabase
        .from('gym_members')
        .select()
        .eq('id', supabaseUser.id)
        .maybeSingle();

    if (memberRow != null) {
      return UserProfile(
        uid: supabaseUser.id,
        email: memberRow['email']?.toString() ?? supabaseUser.email ?? '',
        displayName: _resolveDisplayNameFromRow(memberRow, supabaseUser),
        role: _parseRole(memberRow['role']),
        gymId: memberRow['gym_id'] != null
            ? GymId(memberRow['gym_id'].toString())
            : null,
        photoUrl: _supabaseAvatarUrl(supabaseUser),
        weight: _parseDouble(memberRow['weight']),
        height: _parseDouble(memberRow['height']),
        fitnessGoal: memberRow['fitness_goal']?.toString(),
        membershipStatus: _parseMembershipStatus(memberRow['membership_status']),
        membershipExpiresAt: _parseDateTime(memberRow['membership_expires_at']),
      );
    }

    final adminRow = await _supabase
        .from('admins')
        .select()
        .eq('id', supabaseUser.id)
        .maybeSingle();

    return UserProfile(
      uid: supabaseUser.id,
      email: adminRow?['email']?.toString() ?? supabaseUser.email ?? '',
      displayName: _resolveDisplayNameFromIdentity(supabaseUser),
      role: adminRow != null ? const GymRole.admin() : null,
      gymId: null,
      photoUrl: _supabaseAvatarUrl(supabaseUser),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN (Firebase + Supabase + explicit Mock mode)
  // ═══════════════════════════════════════════════════════════════════════════

  bool validateCredentials(String email, String password) {
    if (kReleaseMode && useMockAuth) {
      return false;
    }
    // Firebase/Supabase credentials require server-side validation.
    return true;
  }

  Future<void> loginWithCredentials(String email, String password) async {
    if (kReleaseMode && useMockAuth) {
      throw Exception('Mock auth is disabled in release builds');
    }

    if (useMockAuth) {
      throw Exception(
        'Mock credentials are disabled. Use Firebase auth or login(UserProfile) in explicit test/dev entrypoints.',
      );
    }

    if (useSupabaseAuth) {
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        final supabaseUser = response.user;
        if (supabaseUser == null) {
          throw Exception('Credenciales inválidas');
        }

        _profile = await _resolveSupabaseProfile(supabaseUser);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        debugPrint(
          '[Auth] Supabase login successful: ${_profile?.displayName} (${_profile?.role})',
        );
      } on sb.AuthException catch (e) {
        debugPrint('[Auth] Supabase login failed: ${e.message}');
        throw Exception('Credenciales inválidas');
      } catch (e) {
        debugPrint('[Auth] Supabase login failed: $e');
        throw Exception('Credenciales inválidas');
      }
      return;
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Credenciales inválidas');
      }

      _profile = await _resolveProfile(firebaseUser);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      debugPrint(
        '[Auth] Firebase login successful: ${_profile?.displayName} (${_profile?.role})',
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[Auth] Firebase login failed: ${e.code}');
      throw Exception('Credenciales inválidas');
    } catch (e) {
      debugPrint('[Auth] Firebase login failed: $e');
      throw Exception('Credenciales inválidas');
    }
  }

  Future<void> refreshProfile() async {
    if (useMockAuth) {
      debugPrint('[Auth] Mock: Refreshing profile (no-op)');
      return;
    }

    if (useSupabaseAuth) {
      try {
        final supabaseUser = _supabase.auth.currentUser;
        if (supabaseUser == null) {
          _isAuthenticated = false;
          _profile = null;
          notifyListeners();
          return;
        }

        _profile = await _resolveSupabaseProfile(supabaseUser);
        _isAuthenticated = true;
        notifyListeners();
      } catch (e) {
        debugPrint('[Auth] Error refreshing Supabase profile: $e');
      }
      return;
    }

    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        _isAuthenticated = false;
        _profile = null;
        notifyListeners();
        return;
      }

      _profile = await _resolveProfile(firebaseUser);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] Error refreshing Firebase profile: $e');
    }
  }

  void login(UserProfile profile) {
    if (kReleaseMode) {
      throw UnsupportedError(
        'Direct profile login is not available in release builds.',
      );
    }
    _isAuthenticated = true;
    _profile = profile;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!useMockAuth) {
      try {
        if (useSupabaseAuth) {
          await _supabase.auth.signOut();
        } else {
          await _firebaseAuth.signOut();
        }
      } catch (e) {
        debugPrint('[Auth] Logout error: $e');
      }
    }

    debugPrint('[Auth] Signing out');
    _isAuthenticated = false;
    _profile = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  GymRole? _parseRole(dynamic rawRole) {
    if (rawRole == null) return null;

    if (rawRole is Map<String, dynamic>) {
      rawRole = rawRole['type'];
    }

    if (rawRole is! String || rawRole.trim().isEmpty) return null;

    switch (rawRole.trim().toLowerCase()) {
      case 'admin':
        return const GymRole.admin();
      case 'owner':
      case 'dueño':
        return const GymRole.owner();
      case 'employee':
      case 'staff':
      case 'empleado':
        return const GymRole.employee();
      case 'client':
      case 'cliente':
        return const GymRole.client();
      default:
        return null;
    }
  }

  MembershipStatus? _parseMembershipStatus(dynamic rawStatus) {
    if (rawStatus == null) return null;

    final normalized = rawStatus.toString().trim().toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'pendiente':
        return MembershipStatus.pending;
      case 'approved':
      case 'active':
      case 'aprobado':
      case 'activo':
        return MembershipStatus.approved;
      case 'rejected':
      case 'expired':
      case 'rejected_review':
      case 'rechazado':
      case 'vencido':
        return MembershipStatus.rejected;
      default:
        return null;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  String _resolveDisplayName(
    fb.User firebaseUser,
    Map<String, dynamic>? userData,
  ) {
    if (userData != null) {
      final direct = userData['displayName']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;

      final firstName = userData['firstName']?.toString().trim();
      final lastName = userData['lastName']?.toString().trim();
      final fullName = [
        if (firstName != null && firstName.isNotEmpty) firstName,
        if (lastName != null && lastName.isNotEmpty) lastName,
      ].join(' ');
      if (fullName.isNotEmpty) return fullName;

      final legacyFirstName = userData['FirstName']?.toString().trim();
      final legacyLastName = userData['LastName']?.toString().trim();
      final legacyFullName = [
        if (legacyFirstName != null && legacyFirstName.isNotEmpty)
          legacyFirstName,
        if (legacyLastName != null && legacyLastName.isNotEmpty) legacyLastName,
      ].join(' ');
      if (legacyFullName.isNotEmpty) return legacyFullName;
    }

    final firebaseDisplayName = firebaseUser.displayName?.trim();
    if (firebaseDisplayName != null && firebaseDisplayName.isNotEmpty) {
      return firebaseDisplayName;
    }

    final email = firebaseUser.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Usuario';
  }

  String _resolveDisplayNameFromRow(
    Map<String, dynamic> row,
    sb.User supabaseUser,
  ) {
    final firstName = row['first_name']?.toString().trim();
    final lastName = row['last_name']?.toString().trim();
    final fullName = [
      if (firstName != null && firstName.isNotEmpty) firstName,
      if (lastName != null && lastName.isNotEmpty) lastName,
    ].join(' ');
    if (fullName.isNotEmpty) return fullName;

    return _resolveDisplayNameFromIdentity(supabaseUser);
  }

  String _resolveDisplayNameFromIdentity(sb.User supabaseUser) {
    final metadataName =
        supabaseUser.userMetadata?['full_name']?.toString().trim();
    if (metadataName != null && metadataName.isNotEmpty) {
      return metadataName;
    }

    final email = supabaseUser.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Usuario';
  }

  String? _supabaseAvatarUrl(sb.User supabaseUser) {
    final value = supabaseUser.userMetadata?['avatar_url'];
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }
}

/// Simple user profile holder for router decisions
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final GymRole? role;
  final GymId? gymId;
  final String? photoUrl;
  // Fitness data
  final double? weight; // in kg
  final double? height; // in cm
  final String? fitnessGoal; // e.g., "Weight Loss", "Muscle Gain"
  final MembershipStatus? membershipStatus;
  final DateTime? membershipExpiresAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role,
    this.gymId,
    this.photoUrl,
    this.weight,
    this.height,
    this.fitnessGoal,
    this.membershipStatus,
    this.membershipExpiresAt,
  });

  bool get hasValidClaims {
    if (role == null) return false;
    if (role!.type == GymRoleType.admin) return true;
    return gymId != null;
  }

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, role: $role, gymId: $gymId)';
}
