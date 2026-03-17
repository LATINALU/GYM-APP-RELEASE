import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

/// Layout principal para Super Admin (por encima de Owner)
/// Gestión global de gimnasios, dueños, reportes y facturación
class AdminSuperLayout extends StatelessWidget {
  final Widget child;
  const AdminSuperLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Row(
        children: [
          const _AdminSidebar(),
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

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Panel (Super Admin)
          _SuperAdminProfilePanel(
            onLogout: () async {
              await AuthStateNotifier.instance.signOut();
              if (context.mounted) context.go('/login');
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
                const _SectionTitle(title: 'PLATAFORMA'),
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard Global',
                  isSelected: location == '/admin/dashboard',
                  onTap: () => context.go('/admin/dashboard'),
                ),
                _NavItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Gestión de Gimnasios',
                  isSelected: location == '/admin/gyms',
                  onTap: () => context.go('/admin/gyms'),
                ),
                _NavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Gestión de Dueños',
                  isSelected: location == '/admin/owners',
                  onTap: () => context.go('/admin/owners'),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'TRAINING FORGE',
                  isSelected: location == '/admin/forge',
                  onTap: () => context.go('/admin/forge'),
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'REPORTES & ANALYTICS'),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Reportes Globales',
                  isSelected: location == '/admin/reports',
                  onTap: () => context.go('/admin/reports'),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Facturación & Planes',
                  isSelected: location == '/admin/billing',
                  onTap: () => context.go('/admin/billing'),
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'SISTEMA'),
                _NavItem(
                  icon: Icons.security_rounded,
                  label: 'Auditoría & Logs',
                  isSelected: location == '/admin/audit',
                  onTap: () => context.go('/admin/audit'),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Configuración Global',
                  isSelected: location == '/admin/settings',
                  onTap: () => context.go('/admin/settings'),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 40),

          // Settings
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Configuración Global',
            isSelected: location == '/admin/settings',
            onTap: () => context.go('/admin/settings'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFFFF6B35);

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
                        : (color ?? Colors.white.withValues(alpha: 0.4)),
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
                            : (color ?? Colors.white.withValues(alpha: 0.4)),
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
                    color: Color(0xFFFF6B35),
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
// SUPER ADMIN PROFILE PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _SuperAdminProfilePanel extends StatefulWidget {
  final VoidCallback onLogout;

  const _SuperAdminProfilePanel({required this.onLogout});

  @override
  State<_SuperAdminProfilePanel> createState() =>
      _SuperAdminProfilePanelState();
}

class _SuperAdminProfilePanelState extends State<_SuperAdminProfilePanel> {
  bool _isExpanded = false;
  static const Color _adminColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final auth = AuthStateNotifier.instance;
    final profile = auth.profile;
    final userName = profile?.displayName ?? 'Super Admin';
    final initials = profile?.displayName.isNotEmpty == true 
        ? profile!.displayName.substring(0, 1).toUpperCase() 
        : 'SA';

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
                        ? _adminColor.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
              ),
              boxShadow:
                  _isExpanded
                      ? [
                        BoxShadow(
                          color: _adminColor.withValues(alpha: 0.15),
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
                          colors: [_adminColor, Color(0xFFFF3D00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _adminColor.withValues(alpha: 0.3),
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
                                  color: _adminColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SUPER ADMIN',
                                  style: TextStyle(
                                    color: _adminColor,
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

                // Platform info (always visible)
                if (!_isExpanded) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Control Total de Plataforma',
                        style: QuantumTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
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
                // Platform info (in expanded mode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: _adminColor.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Control Total de Plataforma',
                        style: QuantumTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                // Quick Actions
                _AdminQuickAction(
                  icon: Icons.person_rounded,
                  label: 'Mi Perfil',
                  onTap: () => context.push('/profile'),
                ),
                _AdminQuickAction(
                  icon: Icons.settings_rounded,
                  label: 'Configuración',
                  onTap: () => context.go('/admin/settings'),
                ),
                _AdminQuickAction(
                  icon: Icons.help_outline_rounded,
                  label: 'Ayuda & Soporte',
                  onTap: () => context.push('/help-support'),
                ),
                const Divider(color: Colors.white10, height: 1),
                _AdminQuickAction(
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

class _AdminQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _AdminQuickAction({
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
