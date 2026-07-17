import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';
import '../../../domain/ports/output/pending_registration_repository_port.dart';
import '../../../infrastructure/config/di.dart';
import '../../../infrastructure/adapters/firebase/firebase_gym_repository.dart';

/// Layout principal para la versión de Escritorio (Exclusivo Owner)
class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Row(
        children: [
          // Sidebar Lateral
          const _Sidebar(),

          // Área de Contenido Principal
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: QuantumColors.surface(),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.01, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(GoRouterState.of(context).matchedLocation),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  const _Sidebar();

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final auth = AuthStateNotifier.instance;
      final gymId = auth.profile?.gymId;
      if (gymId == null) return;

      if (getIt.isRegistered<PendingRegistrationRepositoryPort>()) {
        final repo = getIt<PendingRegistrationRepositoryPort>();
        final count = await repo.countPendingByGymId(gymId);
        if (mounted) {
          setState(() => _pendingCount = count);
        }
      }
    } catch (_) {
      // Silently fail - badge will just show 0
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: QuantumColors.cosmicBlack,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Panel
          _UserProfilePanel(
            onLogout: () async {
              final navigator = GoRouter.of(context);
              await AuthStateNotifier.instance.signOut();
              navigator.go('/login');
            },
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),

          // Navigation Links
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const _SidebarSectionTitle(title: 'MI GIMNASIO'),
                _SidebarItem(
                  icon: Icons.store_rounded,
                  label: 'Info del Gimnasio',
                  isSelected: location == '/owner/gym-info',
                  onTap: () => context.go('/owner/gym-info'),
                ),
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard Real-time',
                  isSelected: location == '/owner/dashboard',
                  onTap: () => context.go('/owner/dashboard'),
                ),
                const SizedBox(height: 24),
                const _SidebarSectionTitle(title: 'CORE MANAGEMENT'),
                _SidebarItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Gestión de Miembros',
                  isSelected: location == '/owner/members',
                  onTap: () => context.go('/owner/members'),
                ),
                _SidebarItem(
                  icon: Icons.badge_rounded,
                  label: 'Staff Profesional',
                  isSelected: location == '/owner/staff',
                  onTap: () => context.go('/owner/staff'),
                ),
                _SidebarBadgeItem(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Solicitudes Pendientes',
                  isSelected: location == '/owner/pending-registrations',
                  onTap: () => context.go('/owner/pending-registrations'),
                  badgeCount: _pendingCount,
                ),
                _SidebarItem(
                  icon: Icons.card_membership_rounded,
                  label: 'Planes de Membresía',
                  isSelected: location == '/owner/plans',
                  onTap: () => context.go('/owner/plans'),
                ),
                const SizedBox(height: 24),
                const _SidebarSectionTitle(title: 'GYM ENGINE'),
                _SidebarItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Constructor Ejercicios',
                  isSelected: location == '/owner/exercise-builder',
                  onTap: () => context.go('/owner/exercise-builder'),
                ),
                _SidebarItem(
                  icon: Icons.architecture_rounded,
                  label: 'Constructor Rutinas',
                  isSelected: location == '/owner/routine-builder',
                  onTap: () => context.go('/owner/routine-builder'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_view_week_rounded,
                  label: 'Constructor Programas',
                  isSelected: location == '/owner/program-builder',
                  onTap: () => context.go('/owner/program-builder'),
                ),
                _SidebarItem(
                  icon: Icons.shield_rounded,
                  label: 'Retención con IA',
                  isSelected: location == '/owner/retention',
                  onTap: () => context.go('/owner/retention'),
                ),
                _SidebarItem(
                  icon: Icons.monitor_rounded,
                  label: 'Kiosko de Rutinas',
                  isSelected: location == '/kiosk/routines',
                  onTap: () => context.go('/kiosk/routines'),
                ),
                const SizedBox(height: 24),
                const _SidebarSectionTitle(title: 'BUSINESS & FINANCES'),
                _SidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Dashboard BI',
                  isSelected: location == '/owner/dashboard-bi',
                  onTap: () => context.go('/owner/dashboard-bi'),
                ),
                _SidebarItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Punto de Venta',
                  isSelected: location == '/owner/pos-sales',
                  onTap: () => context.go('/owner/pos-sales'),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  isSelected: location == '/owner/pos-inventory',
                  onTap: () => context.go('/owner/pos-inventory'),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Conciliación Caja',
                  isSelected: location == '/owner/cash-close',
                  onTap: () => context.go('/owner/cash-close'),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 40),

          // Settings
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Configuración Gym',
            isSelected: location == '/owner/global-settings',
            onTap: () => context.go('/owner/global-settings'),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  final String title;
  const _SidebarSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title,
        style: QuantumTypography.caption.copyWith(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = QuantumColors.quantumBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? activeColor
                        : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: QuantumColors.matrixCyan,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _SidebarBadgeItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = QuantumColors.quantumBlue;
    final hasBadge = badgeCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : hasBadge
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? activeColor
                        : hasBadge
                        ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: QuantumColors.matrixCyan,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER PROFILE PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _UserProfilePanel extends StatefulWidget {
  final VoidCallback onLogout;

  const _UserProfilePanel({required this.onLogout});

  @override
  State<_UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends State<_UserProfilePanel> {
  bool _isExpanded = false;
  String _gymName = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadGymName();
  }

  Future<void> _loadGymName() async {
    final auth = AuthStateNotifier.instance;
    final gymId = auth.profile?.gymId?.value;
    if (gymId == null) return;

    try {
      if (getIt.isRegistered<FirebaseGymRepository>()) {
        final gym = await getIt<FirebaseGymRepository>().getGym(gymId);
        if (mounted && gym != null) {
          setState(() => _gymName = gym.name);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _gymName = 'Mi Gimnasio');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthStateNotifier.instance;
    final profile = auth.profile;
    final userName = profile?.displayName ?? 'Usuario';
    final userRole = profile?.role?.displayName ?? 'Owner';
    final initials = profile?.displayName.isNotEmpty == true 
        ? profile!.displayName.substring(0, 1).toUpperCase() 
        : 'U';

    return Column(
      children: [
        // Main Profile Card
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumColors.voidGray.withValues(
                alpha: _isExpanded ? 0.8 : 0.4,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _isExpanded
                        ? QuantumColors.quantumBlue.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
              ),
              boxShadow:
                  _isExpanded
                      ? [
                        BoxShadow(
                          color: QuantumColors.quantumBlue.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ]
                      : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with gradient
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            QuantumColors.quantumBlue,
                            QuantumColors.holoPurple,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: QuantumColors.quantumBlue.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: QuantumTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: QuantumColors.matrixCyan.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  userRole.toUpperCase(),
                                  style: QuantumTypography.caption.copyWith(
                                    color: QuantumColors.matrixCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Online indicator
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: QuantumColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: QuantumColors.success.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Expand Icon
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // Gym Name (always visible)
                if (!_isExpanded) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gymName,
                          style: QuantumTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expanded Menu
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: QuantumColors.voidGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Gym Name (in expanded mode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        color: QuantumColors.quantumBlue.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _gymName,
                          style: QuantumTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                // Quick Actions
                _QuickActionItem(
                  icon: Icons.person_rounded,
                  label: 'Mi Perfil',
                  onTap: () => context.push('/profile'),
                ),
                _QuickActionItem(
                  icon: Icons.settings_rounded,
                  label: 'Configuración',
                  onTap: () => context.go('/owner/global-settings'),
                ),
                _QuickActionItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Ayuda & Soporte',
                  onTap: () => context.push('/help-support'),
                ),
                const Divider(color: Colors.white10, height: 1),
                _QuickActionItem(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar Sesión',
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: QuantumTypography.bodySmall.copyWith(
                color: itemColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
