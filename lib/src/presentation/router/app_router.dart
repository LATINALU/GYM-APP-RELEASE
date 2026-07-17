import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../auth/pages/login_screen.dart';
import '../auth/pages/forgot_password_screen.dart';
import '../auth/pages/register_screen.dart';
import '../screens/admin/admin_super_layout.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_gyms_live_screen.dart';
import '../screens/admin/admin_owners_live_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_billing_screen.dart';
import '../screens/admin/admin_audit_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_exercise_library_screen.dart';
import '../screens/owner/admin_layout.dart';
import '../screens/owner/gym_info_screen.dart';
import '../screens/owner/membership_plans_screen.dart';
import '../screens/owner/owner_exercise_library_screen.dart';
import '../screens/owner/exercise_atlas_screen.dart';
import '../screens/owner/training_forge_screen.dart';
import '../screens/owner/bi_dashboard_screen.dart';
import '../screens/owner/pos_inventory_screen.dart';
import '../screens/owner/pos_sales_screen.dart';
import '../screens/owner/enhanced_cash_reconciliation_screen.dart';
import '../screens/owner/exercise_builder_screen.dart';
import '../screens/owner/program_builder_screen.dart';
import '../screens/owner/simple_routine_builder_screen.dart';
import '../screens/owner/finance_subscriptions_screen.dart';
import '../screens/owner/staff_management_screen.dart';
import '../screens/owner/global_settings_screen.dart';
import '../screens/owner/retention_panel_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/bloc/settings_bloc.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/support/help_support_screen.dart';
import '../../infrastructure/config/di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/owner/owner_member_wizard_screen.dart';
import '../screens/owner/pending_registrations_screen.dart';
import '../screens/client/client_qr_pass_screen.dart';
import '../screens/client/routine_selection_screen.dart';
import '../screens/client/routine_import_scanner_screen.dart';
import '../screens/workout/manual_log_screen.dart';
import '../screens/kiosk/kiosk_routine_screen.dart';
import '../screens/screens.dart' hide MembershipPlansScreen;
import '../../domain/entities/entities.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GYM-APP FUNCTIONAL VIEWS (real working screens)
// ═══════════════════════════════════════════════════════════════════════════
// Legacy views removed - keeping only the active architecture

/// Application Router with role-based redirection
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: AuthStateNotifier.instance,
    redirect: _handleRedirect,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        builder:
            (context, state) => BlocProvider(
              create: (context) => getIt<SettingsBloc>()..add(LoadSettings()),
              child: const SettingsScreen(),
            ),
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notificationSettings',
            builder:
                (context, state) => BlocProvider(
                  create:
                      (context) => getIt<SettingsBloc>()..add(LoadSettings()),
                  child: const NotificationSettingsScreen(),
                ),
          ),
        ],
      ),
      GoRoute(
        path: '/help-support',
        name: 'helpSupport',
        builder: (context, state) => const HelpSupportScreen(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // ADMIN ROUTES (Super Admin Shell)
      // ═══════════════════════════════════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) => AdminSuperLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/gyms',
            name: 'adminGyms',
            builder: (context, state) => const AdminGymsLiveScreen(),
          ),
          GoRoute(
            path: '/admin/owners',
            name: 'adminOwners',
            builder: (context, state) => const AdminOwnersLiveScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            name: 'adminReports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/billing',
            name: 'adminBilling',
            builder: (context, state) => const AdminBillingScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            name: 'adminAudit',
            builder: (context, state) => const AdminAuditScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'adminSettings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/exercises',
            name: 'adminExercises',
            builder: (context, state) => const AdminExerciseLibraryScreen(),
          ),
          GoRoute(
            path: '/admin/forge',
            name: 'adminForge',
            builder: (context, state) => const TrainingForgeScreen(),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // OWNER ROUTES (PC Optimized Shell)
      // ═══════════════════════════════════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/owner/dashboard',
            name: 'ownerDashboard',
            builder: (context, state) => const OwnerDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/atlas',
            name: 'ownerAtlas',
            builder: (context, state) => const ExerciseAtlasScreen(),
          ),
          GoRoute(
            path: '/owner/exercise-builder',
            name: 'ownerExerciseBuilder',
            builder: (context, state) => const ExerciseBuilderScreen(),
          ),
          GoRoute(
            path: '/owner/routine-builder',
            name: 'ownerRoutineBuilder',
            builder: (context, state) => const SimpleRoutineBuilderScreen(),
          ),
          GoRoute(
            path: '/owner/program-builder',
            name: 'ownerProgramBuilder',
            builder: (context, state) => const ProgramBuilderScreen(),
          ),
          GoRoute(
            path: '/owner/finance',
            name: 'ownerFinance',
            builder: (context, state) => const FinanceSubscriptionsScreen(),
          ),
          GoRoute(
            path: '/owner/staff',
            name: 'ownerStaff',
            builder: (context, state) => const StaffManagementScreen(),
          ),
          GoRoute(
            path: '/owner/dashboard-bi',
            name: 'ownerBI',
            builder: (context, state) => const BiDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/global-settings',
            name: 'ownerSettings',
            builder: (context, state) => const GlobalSettingsScreen(),
          ),
          GoRoute(
            path: '/owner/retention',
            name: 'ownerRetention',
            builder: (context, state) => const RetentionPanelScreen(),
          ),
          GoRoute(
            path: '/owner/members',
            name: 'ownerMembers',
            builder: (context, state) => const OwnerMembersScreen(),
          ),
          GoRoute(
            path: '/owner/cash-close',
            name: 'ownerCashClose',
            builder:
                (context, state) => const EnhancedCashReconciliationScreen(),
          ),
          GoRoute(
            path: '/owner/pos-sales',
            name: 'ownerPosSales',
            builder: (context, state) => const PosSalesScreen(),
          ),
          GoRoute(
            path: '/owner/pos-inventory',
            name: 'ownerPosInventory',
            builder: (context, state) => const PosInventoryScreen(),
          ),
          GoRoute(
            path: '/owner/gym-info',
            name: 'ownerGymInfo',
            builder: (context, state) => const GymInfoScreen(),
          ),
          GoRoute(
            path: '/owner/plans',
            name: 'ownerPlans',
            builder: (context, state) => const MembershipPlansScreen(),
          ),
          GoRoute(
            path: '/owner/exercises',
            name: 'ownerExercises',
            builder: (context, state) => const OwnerExerciseLibraryScreen(),
          ),
          GoRoute(
            path: '/owner/pending-registrations',
            name: 'ownerPendingRegistrations',
            builder: (context, state) {
              final auth = AuthStateNotifier.instance;
              return PendingRegistrationsScreen(
                gymId: auth.profile?.gymId?.value ?? '',
                currentUserId: auth.profile?.uid ?? '',
              );
            },
          ),
          GoRoute(
            path: '/owner/forge',
            name: 'ownerForge',
            builder: (context, state) => const TrainingForgeScreen(),
          ),
        ],
      ),

      // Full-screen Owner Routes (No Sidebar)
      GoRoute(
        path: '/owner/add-member',
        name: 'ownerAddMember',
        builder: (context, state) => const OwnerMemberWizardScreen(),
      ),

      // Kiosk Mode (Full-screen, no sidebar, for desktop stations at gym)
      GoRoute(
        path: '/kiosk/routines',
        name: 'kioskRoutines',
        builder: (context, state) => KioskRoutineScreen(
          gymId: state.uri.queryParameters['gymId'],
        ),
      ),

      // Staff Routes (with bottom navigation shell)
      ShellRoute(
        builder: (context, state, child) => StaffMainLayout(child: child),
        routes: [
          GoRoute(
            path: '/staff/home',
            name: 'staffHome',
            builder: (context, state) => const StaffHomeScreen(),
          ),
          GoRoute(
            path: '/staff/qr-scanner',
            name: 'staffQrScanner',
            builder: (context, state) => const StaffQrScannerScreen(),
          ),
          GoRoute(
            path: '/staff/routine-management',
            name: 'staffRoutineManagement',
            builder: (context, state) => const RoutineManagementScreen(),
          ),
        ],
      ),

      // Client Routes (Mobile Optimized Shell)
      ShellRoute(
        builder: (context, state, child) => ClientMainLayout(child: child),
        routes: [
          GoRoute(
            path: '/client/home',
            name: 'clientHome',
            builder: (context, state) => const TrainingDashboardScreen(),
          ),
          GoRoute(
            path: '/client/routine',
            name: 'clientRoutine',
            builder: (context, state) => const RoutineSelectionScreen(),
          ),
          GoRoute(
            path: '/client/qr-checkin',
            name: 'clientQrCheckin',
            builder: (context, state) => const ClientQrCheckinScreen(),
          ),
          GoRoute(
            path: '/client/analytics',
            name: 'clientAnalytics',
            builder: (context, state) => const ClientAnalyticsDashboardScreen(),
          ),
        ],
      ),

      // Standalone Client Routes (No Bottom Nav)
      GoRoute(
        path: '/client/qr',
        name: 'clientQr',
        builder: (context, state) => const ClientQrScreen(),
      ),
      GoRoute(
        path: '/client/import-routine',
        name: 'clientImportRoutine',
        builder: (context, state) => const RoutineImportScannerScreen(),
      ),
      GoRoute(
        path: '/classes/gym-classes',
        name: 'gymClasses',
        builder: (context, state) => const GymClassesScreen(),
      ),
      GoRoute(
        path: '/client/digital-pass',
        name: 'clientDigitalPass',
        builder: (context, state) {
          final auth = AuthStateNotifier.instance;
          return ClientQrPassScreen(
            userId: auth.profile?.uid ?? 'unknown',
            userName: auth.profile?.displayName ?? 'Usuario',
          );
        },
      ),

      // Muscle Heatmap (standalone, no bottom nav)
      GoRoute(
        path: '/client/muscle-heatmap',
        name: 'clientMuscleHeatmap',
        builder: (context, state) => const ClientMuscleHeatmapScreen(),
      ),

      // New Client Features (Integrated into Shell if needed, or standalone)
      GoRoute(
        path: '/client/nutrition',
        name: 'clientNutrition',
        builder: (context, state) => const NutritionTrackingScreen(),
      ),
      GoRoute(
        path: '/client/measurements',
        name: 'clientMeasurements',
        builder: (context, state) => const BodyMeasurementsScreen(),
      ),
      GoRoute(
        path: '/client/recovery',
        name: 'clientRecovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/client/volume',
        name: 'clientVolume',
        builder: (context, state) => const VolumeTrackingScreen(),
      ),
      GoRoute(
        path: '/client/notifications',
        name: 'clientNotifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/client/achievements',
        name: 'clientAchievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/client/workout-analytics',
        name: 'clientWorkoutAnalytics',
        builder: (context, state) => const WorkoutAnalyticsScreen(),
      ),
      GoRoute(
        path: '/client/timer',
        name: 'clientTimer',
        builder: (context, state) => const TrainingTimerScreen(),
      ),
      GoRoute(
        path: '/client/community',
        name: 'clientCommunity',
        builder: (context, state) => const CommunityFeedScreen(),
      ),
      GoRoute(
        path: '/client/leaderboard',
        name: 'clientLeaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // Active workout routes
      GoRoute(
        path: '/client/daily-workout',
        name: 'clientDailyWorkout',
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/client/manual-log',
        name: 'clientManualLog',
        builder: (context, state) => const ManualLogScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder:
            (context, state) =>
                OnboardingScreen(onComplete: () => context.go('/client/home')),
      ),

      // Root Route (redirects based on auth state via _handleRedirect)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const _SplashScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Página no encontrada: ${state.uri}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    'Volver al inicio',
                    style: TextStyle(color: Color(0xFF00E0FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  /// Handle authentication and role-based redirects
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final auth = AuthStateNotifier.instance;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password';

    if (auth.isLoading) return null;
    if (!auth.isAuthenticated) return isAuthRoute ? null : '/login';

    final profile = auth.profile;
    if (profile == null || !profile.hasValidClaims) {
      if (state.matchedLocation == '/') return null;
      return '/';
    }

    if (isAuthRoute || state.matchedLocation == '/') {
      return _getHomeRouteForRole(profile.role!);
    }

    if (!_canAccessRoute(profile.role!, state.matchedLocation)) {
      return _getHomeRouteForRole(profile.role!);
    }

    // New Protection: Mandatory QR Pass for pending clients
    final isPendingClient =
        profile.role?.type == GymRoleType.client &&
        (profile.membershipStatus == MembershipStatus.pending ||
            profile.gymId?.value == 'orphan-gym');

    if (isPendingClient && state.matchedLocation != '/client/digital-pass') {
      return '/client/digital-pass';
    }

    return null;
  }

  static String _getHomeRouteForRole(dynamic role) {
    if (role is GymRole) {
      switch (role.type) {
        case GymRoleType.admin:
          return '/admin/dashboard';
        case GymRoleType.owner:
          return '/owner/dashboard';
        case GymRoleType.employee:
          return '/staff/home';
        case GymRoleType.client:
          return '/client/home';
      }
    }

    final roleString = role.toString().toLowerCase();
    if (roleString.contains('admin') || roleString.contains('administrador')) {
      return '/admin/dashboard';
    }
    if (roleString.contains('owner') || roleString.contains('dueño')) {
      return '/owner/dashboard';
    }
    if (roleString.contains('employee') ||
        roleString.contains('staff') ||
        roleString.contains('empleado')) {
      return '/staff/home';
    }
    return '/client/home';
  }

  static bool _canAccessRoute(dynamic role, String location) {
    if (role is! GymRole) return false;
    // Admin can access everything
    if (role.type == GymRoleType.admin) return true;
    // Kiosk requiere sesión de staff/owner: las reglas de Firestore no
    // permiten leer rutinas sin autenticación, y una estación pública no
    // debe quedar con acceso al resto del panel
    if (location.startsWith('/kiosk')) {
      return role.type == GymRoleType.owner ||
          role.type == GymRoleType.employee;
    }
    if (location.startsWith('/admin')) return role.type == GymRoleType.admin;
    if (location.startsWith('/owner')) return role.type == GymRoleType.owner;
    if (location.startsWith('/staff')) {
      return role.type == GymRoleType.owner ||
          role.type == GymRoleType.employee;
    }
    if (location.startsWith('/client')) return role.type == GymRoleType.client;
    return true;
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder:
                  (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF6366F1),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'QUANTUM GYM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
