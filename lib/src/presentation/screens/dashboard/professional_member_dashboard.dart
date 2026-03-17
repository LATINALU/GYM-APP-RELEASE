/// MEMBER DASHBOARD SCREEN - Dashboard principal profesional
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/gym_widgets.dart';
import '../home/training_dashboard_screen.dart';
import '../screens.dart';

class ProfessionalMemberDashboard extends StatefulWidget {
  const ProfessionalMemberDashboard({super.key});

  @override
  State<ProfessionalMemberDashboard> createState() => _ProfessionalMemberDashboardState();
}

class _ProfessionalMemberDashboardState extends State<ProfessionalMemberDashboard> 
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _pulseController;

  // Legacy dashboard state
  final _memberData = _MemberData(
    name: 'Carlos',
    lastName: 'Rodríguez',
    membershipType: 'Premium',
    membershipStatus: 'active',
    membershipDaysRemaining: 25,
    totalDays: 30,
    points: 1250,
    checkInsThisMonth: 18,
    nextClass: NextClass(
      name: 'Spinning Pro',
      time: '18:00',
      instructor: 'María López',
      spotsAvailable: 4,
    ),
    occupancy: GymOccupancy(
      total: 0.45,
      weights: 0.72,
      cardio: 0.38,
      stretching: 0.15,
    ),
    notifications: 3,
    imageUrl: null,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return const TrainingDashboardScreen();
  }

  Widget _buildSectionHeader({required String title, required String actionText, required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFF00E0FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Inicio'),
            _buildNavItem(1, Icons.calendar_month_rounded, 'Clases'),
            _buildMainQRAction(),
            _buildNavItem(3, Icons.analytics_rounded, 'Progreso'),
            _buildNavItem(4, Icons.person_rounded, 'Perfil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentNavIndex = index);
        _handleNavigation(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF00E0FF) : Colors.white24,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white24,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainQRAction() {
    return GestureDetector(
      onTap: () => _navigateTo('/qr-checkin'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, ${_memberData.name}! 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getGreetingMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        _buildTodayGoal(),
      ],
    );
  }

  Widget _buildTodayGoal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFE53935), size: 22),
          const SizedBox(width: 8),
          Text(
            '${_memberData.checkInsThisMonth}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            '/20',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Mi QR',
        color: const Color(0xFF00E0FF),
        route: '/qr-checkin',
      ),
      _QuickAction(
        icon: Icons.event_available_rounded,
        label: 'Clases',
        color: const Color(0xFF8B5CF6),
        route: '/gym-classes',
        badge: '3',
      ),
      _QuickAction(
        icon: Icons.payments_rounded,
        label: 'Pagar',
        color: const Color(0xFF00FFE0),
        route: '/payment',
      ),
      _QuickAction(
        icon: Icons.stars_rounded,
        label: 'Puntos',
        color: Colors.amber.shade400,
        route: '/rewards',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) => _buildQuickActionItem(action)).toList(),
    );
  }

  Widget _buildQuickActionItem(_QuickAction action) {
    return GestureDetector(
      onTap: () => _navigateTo(action.route),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Icon(action.icon, color: action.color, size: 28),
              ),
              if (action.badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      action.badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.label,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    final progress = 1 - (_memberData.membershipDaysRemaining / _memberData.totalDays);
    final isExpiringSoon = _memberData.membershipDaysRemaining <= 7;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Membresía ${_memberData.membershipType}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        'ID: GYM-2024-001',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFE0).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FFE0).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'ACTIVA',
                  style: TextStyle(color: Color(0xFF00FFE0), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isExpiringSoon ? Colors.orange : const Color(0xFF00FFE0),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: (isExpiringSoon ? Colors.orange : const Color(0xFF00FFE0)).withValues(alpha: 0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_memberData.membershipDaysRemaining} días restantes',
                style: TextStyle(color: isExpiringSoon ? Colors.orange[200] : Colors.white70, fontSize: 13),
              ),
              ElevatedButton(
                onPressed: () => _navigateTo('/renew'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  elevation: 0,
                ),
                child: const Text('RENOVAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard() {
    final nextClass = _memberData.nextClass!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E0FF), Color(0xFF0066FF)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nextClass.time.split(':')[0],
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  ':${nextClass.time.split(':')[1]}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextClass.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      nextClass.instructor,
                      style: const TextStyle(fontSize: 14, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: nextClass.spotsAvailable <= 5 ? Colors.orange.withValues(alpha: 0.1) : const Color(0xFF00FFE0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${nextClass.spotsAvailable} cupos',
                  style: TextStyle(
                    color: nextClass.spotsAvailable <= 5 ? Colors.orange : const Color(0xFF00FFE0),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RESERVADO',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard() {
    final occupancy = _memberData.occupancy;
    final occupancyColor = occupancy.total > 0.7 ? Colors.redAccent : (occupancy.total > 0.4 ? Colors.orangeAccent : const Color(0xFF00FFE0));
    final occupancyPercent = (occupancy.total * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: occupancy.total,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$occupancyPercent%',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: occupancyColor),
                      ),
                      Text(
                        _getOccupancyLabel(occupancy.total),
                        style: const TextStyle(fontSize: 10, color: Colors.white24),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildOccupancyBar('Zona Pesas', occupancy.weights, const Color(0xFFE53935)),
                    const SizedBox(height: 16),
                    _buildOccupancyBar('Cardio', occupancy.cardio, const Color(0xFF00E0FF)),
                    const SizedBox(height: 16),
                    _buildOccupancyBar('Estiramientos', occupancy.stretching, const Color(0xFF00FFE0)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyBar(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('${(val * 100).toInt()}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: val.clamp(0, 1),
              child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDeepStatCard(
            icon: Icons.directions_run_rounded,
            color: const Color(0xFF00E0FF),
            label: 'Visitas mes',
            value: '${_memberData.checkInsThisMonth}',
            subtitle: '+3 vs anterior',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDeepStatCard(
            icon: Icons.emoji_events_rounded,
            color: Colors.amber.shade400,
            label: 'Racha actual',
            value: '5 días',
            subtitle: '¡Sigue así!',
          ),
        ),
      ],
    );
  }

  Widget _buildDeepStatCard({required IconData icon, required Color color, required String label, required String value, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 30),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_memberData.points} puntos',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nivel Oro • 250 pts para Platino',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _navigateTo('/rewards'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              elevation: 0,
            ),
            child: const Text('CANJEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡Buen día! ¿Listo para entrenar?';
    if (hour < 18) return '¡Buenas tardes! El gym te espera';
    return '¡Buenas noches! Nunca es tarde para entrenar';
  }

  String _getOccupancyLabel(double percentage) {
    if (percentage <= 0.3) return 'Tranquilo';
    if (percentage <= 0.5) return 'Normal';
    if (percentage <= 0.7) return 'Moderado';
    return 'Ocupado';
  }

  void _navigateTo(String route) {
    HapticFeedback.lightImpact();
    // Implement navigation based on route
    switch (route) {
      case '/qr':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MembershipCardScreen(),
        ));
        break;
      case '/qr-checkin':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ClientQrCheckinScreen(),
        ));
        break;
      case '/classes':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ClassScheduleScreen(),
        ));
        break;
      case '/gym-classes':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GymClassesScreen(),
        ));
        break;
      case '/rewards':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const LoyaltyRewardsScreen(),
        ));
        break;
      case '/occupancy':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GymOccupancyScreen(),
        ));
        break;
      case '/membership':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MembershipStatusScreen(),
        ));
        break;
      case '/renew':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MembershipPlansScreen(isUpgrade: true),
        ));
        break;
      case '/payment':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💳 Módulo de pagos próximamente'),
            backgroundColor: Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home - ya estamos aquí
        break;
      case 1: // Clases
        _navigateTo('/gym-classes');
        break;
      case 2: // QR
        _navigateTo('/qr-checkin');
        break;
      case 3: // Progreso
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ProgressScreen(),
        ));
        break;
      case 4: // Perfil
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ));
        break;
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class _MemberData {
  final String name;
  final String lastName;
  final String membershipType;
  final String membershipStatus;
  final int membershipDaysRemaining;
  final int totalDays;
  final int points;
  final int checkInsThisMonth;
  final NextClass? nextClass;
  final GymOccupancy occupancy;
  final int notifications;
  final String? imageUrl;

  _MemberData({
    required this.name,
    required this.lastName,
    required this.membershipType,
    required this.membershipStatus,
    required this.membershipDaysRemaining,
    required this.totalDays,
    required this.points,
    required this.checkInsThisMonth,
    this.nextClass,
    required this.occupancy,
    this.notifications = 0,
    this.imageUrl,
  });
}

class NextClass {
  final String name;
  final String time;
  final String instructor;
  final int spotsAvailable;

  NextClass({
    required this.name,
    required this.time,
    required this.instructor,
    required this.spotsAvailable,
  });
}

class GymOccupancy {
  final double total;
  final double weights;
  final double cardio;
  final double stretching;

  GymOccupancy({
    required this.total,
    required this.weights,
    required this.cardio,
    this.stretching = 0,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final String? badge;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.badge,
  });
}
