import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../bloc/app_bloc.dart';
import '../../../infrastructure/config/di.dart';


class ClientMainLayout extends StatefulWidget {
  final Widget child;
  const ClientMainLayout({super.key, required this.child});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/client/home')) return 0;
    if (location.startsWith('/client/routine')) return 1;
    if (location.startsWith('/client/qr-checkin') || location.startsWith('/client/digital-pass')) return 2;
    if (location.startsWith('/client/analytics')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('clientHome');
        break;
      case 1:
        context.goNamed('clientRoutine');
        break;
      case 2:
        context.goNamed('clientDigitalPass');
        break;
      case 3:
        context.goNamed('clientAnalytics');
        break;
      case 4:
        context.push('/profile');
        break;
    }
  }

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      label: 'Hub',
    ),
    NavigationItem(
      icon: Icons.fitness_center_rounded,
      activeIcon: Icons.fitness_center_rounded,
      label: 'Entreno',
    ),
    NavigationItem(
      icon: Icons.qr_code_2_rounded,
      activeIcon: Icons.qr_code_2_rounded,
      label: 'Acceso',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Stats',
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return BlocProvider<AppBloc>(
      create: (context) {
        final bloc = getIt<AppBloc>();
        // Auto-load app data when the layout is created
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          bloc.add(LoadAppData(
            userId: authState.user.id,
            gymId: authState.user.gymId,
          ));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: QuantumColors.cosmicBlack,
        body: Stack(
          children: [
            // Background Gradient to avoid white flashes
            Container(color: QuantumColors.cosmicBlack),
            
            // Main Content
            widget.child,

            // Holographic Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HolographicNavigationBar(
                currentIndex: selectedIndex,
                items: _navItems,
                onTap: (index) => _onItemTapped(index, context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
