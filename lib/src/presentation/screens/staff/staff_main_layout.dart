import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class StaffMainLayout extends StatelessWidget {
  final Widget child;
  const StaffMainLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/staff/home')) return 0;
    if (location.startsWith('/staff/qr-scanner')) return 1;
    if (location.startsWith('/staff/routine-management')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('staffHome');
        break;
      case 1:
        context.goNamed('staffQrScanner');
        break;
      case 2:
        context.goNamed('staffRoutineManagement');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    final navItems = const [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Inicio',
      ),
      NavigationItem(
        icon: Icons.qr_code_scanner_outlined,
        activeIcon: Icons.qr_code_scanner,
        label: 'Escanear',
      ),
      NavigationItem(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: 'Rutinas',
      ),
    ];

    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: Stack(
        children: [
          Container(color: QuantumColors.cosmicBlack),
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HolographicNavigationBar(
              currentIndex: selectedIndex,
              items: navItems,
              onTap: (index) => _onItemTapped(index, context),
            ),
          ),
        ],
      ),
    );
  }
}
