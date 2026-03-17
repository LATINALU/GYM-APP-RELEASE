import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../workout/minimal_workout_screen.dart';
import '../screens.dart'; // Barrel file por si acaso

/// Pantalla de inicio minimalista futurista
class MinimalHomeScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onStartWorkout;
  final VoidCallback? onNavigateToRoutines;
  final VoidCallback? onNavigateToStats;
  final VoidCallback? onNavigateToProfile;

  const MinimalHomeScreen({
    super.key,
    this.userName = 'Usuario',
    this.onStartWorkout,
    this.onNavigateToRoutines,
    this.onNavigateToStats,
    this.onNavigateToProfile,
  });

  @override
  State<MinimalHomeScreen> createState() => _MinimalHomeScreenState();
}

class _MinimalHomeScreenState extends State<MinimalHomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedRoutineIndex = 0;

  final List<String> _routineLabels = [
    'Push Day',
    'Pull Day',
    'Leg Day',
    'Core',
    'HIIT',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuantumColors.cosmicBlack,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex == 1 ? 0 : (_selectedNavIndex > 1 ? _selectedNavIndex - 1 : 0), // Hack temporal: 0=Home, 1=Stats(index 2), 2=Profile(index 3). Workout es push.
          children: [
            // 0. HOME CONTENT
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildMetricsGrid(),
                        const SizedBox(height: 40),
                        _buildDailyProgress(),
                        const SizedBox(height: 40),
                        _buildQuickRoutine(),
                        const SizedBox(height: 40),
                        _buildNextWorkout(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // 1. STATS CONTENT (Placeholder)
            const _PlaceholderScreen(title: 'STATISTICS', icon: Icons.analytics_outlined),

            // 2. PROFILE CONTENT (Placeholder)
            const _PlaceholderScreen(title: 'PROFILE', icon: Icons.person_outline),
          ],
        ),
      ),
      
      // Navegación inferior holográfica
      bottomNavigationBar: HolographicNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          if (index == 1) {
            // Navegar a Workout Screen
            Navigator.of(context).push(
                QuantumPageTransitions.slideUp(
                    page: MinimalWorkoutScreen(
                        onBack: () => Navigator.pop(context),
                        onComplete: () => Navigator.pop(context),
                    ),
                ),
            );
          } else {
             setState(() => _selectedNavIndex = index);
          }
        },
        items: const [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          NavigationItem(
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Workout',
          ),
          NavigationItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Stats',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),

      // FAB holográfico
      floatingActionButton: FloatingActionHologram(
        icon: Icons.play_arrow,
        onPressed: () {
            // Navegación directa a entrenamiento
            Navigator.of(context).push(
                QuantumPageTransitions.slideUp(
                    page: MinimalWorkoutScreen(
                        onBack: () => Navigator.pop(context),
                        onComplete: () => Navigator.pop(context),
                    ),
                ),
            );
            widget.onStartWorkout?.call();
        },
        label: 'START',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return FadeInWidget(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'QUANTUM',
                      style: QuantumTypography.h4.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3,
                        color: QuantumColors.quantumBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GYM',
                      style: QuantumTypography.h4.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$greeting, ${widget.userName}',
                  style: QuantumTypography.body.copyWith(
                    color: QuantumColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: QuantumColors.quantumBlue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: QuantumColors.voidGray,
                child: const Icon(
                  Icons.person,
                  color: QuantumColors.quantumBlue,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: const [
          DataMatrixCard(
            title: 'Heart Rate',
            value: '72',
            unit: 'BPM',
            icon: Icons.favorite_border,
            accentColor: QuantumColors.matrixCyan,
          ),
          DataMatrixCard(
            title: 'Calories',
            value: '480',
            unit: 'KCAL',
            icon: Icons.local_fire_department_outlined,
            accentColor: QuantumColors.quantumBlue,
          ),
          DataMatrixCard(
            title: 'Workout Time',
            value: '45',
            unit: 'MIN',
            icon: Icons.timer_outlined,
            accentColor: QuantumColors.deepSpaceBlue,
          ),
          DataMatrixCard(
            title: 'Streak',
            value: '28',
            unit: 'DAYS',
            icon: Icons.star_outline,
            accentColor: QuantumColors.holoPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: QuantumTypography.h4.copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: QuantumColors.matrixCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: QuantumColors.matrixCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '75%',
                  style: QuantumTypography.data.copyWith(
                    color: QuantumColors.matrixCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const QuantumProgressBar(
            progress: 0.75,
            label: 'Goal: 60 min workout',
            height: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRoutine() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Routine',
                style: QuantumTypography.h4.copyWith(fontSize: 18),
              ),
              GestureDetector(
                onTap: widget.onNavigateToRoutines,
                child: Text(
                  'See all',
                  style: QuantumTypography.bodySmall.copyWith(
                    color: QuantumColors.quantumBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_routineLabels.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _routineLabels.length - 1 ? 12 : 0,
                  ),
                  child: MinimalExerciseChip(
                    label: _routineLabels[index],
                    isSelected: _selectedRoutineIndex == index,
                    onTap: () {
                      setState(() => _selectedRoutineIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWorkout() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: QuantumColors.quantumBlue.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Imagen de Fondo (Anatomía/Muscular)
              Positioned.fill(
                child: Image.network(
                  'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=2070&auto=format&fit=crop', // Imagen de gimnasio oscura/neon
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: QuantumColors.voidGray,
                  ),
                ),
              ),
              
              // 2. Overlay Gradiente (Para legibilidad y estilo)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        QuantumColors.cosmicBlack.withValues(alpha: 0.9),
                        QuantumColors.cosmicBlack.withValues(alpha: 0.7),
                        QuantumColors.cosmicBlack.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 3. Efecto Glass Brillante (Borde)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Contenido Clickable
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                     Navigator.of(context).push(
                        QuantumPageTransitions.slideUp(
                            page: MinimalWorkoutScreen(
                                onBack: () => Navigator.pop(context),
                                onComplete: () => Navigator.pop(context),
                            ),
                        ),
                    );
                    widget.onStartWorkout?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: QuantumColors.quantumBlue,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: QuantumColors.quantumBlue.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'NEXT WORKOUT',
                                    style: QuantumTypography.caption.copyWith(
                                      color: QuantumColors.cosmicBlack,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'CHEST DAY',
                                  style: QuantumTypography.h2.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    shadows: [
                                      Shadow(
                                        color: QuantumColors.quantumBlue.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: QuantumColors.nebulaWhite,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Iconos de estadísticas
                        const Row(
                          children: [
                            _GlassStat(icon: Icons.timer_outlined, value: '45 min'),
                            SizedBox(width: 16),
                            _GlassStat(icon: Icons.fitness_center, value: '8 Exercises'),
                            SizedBox(width: 16),
                            _GlassStat(icon: Icons.local_fire_department, value: '320 Kcal', color: QuantumColors.error),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QuantumColors.quantumBlue.withValues(alpha: 0.1),
              border: Border.all(
                color: QuantumColors.quantumBlue.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon, 
              size: 64, 
              color: QuantumColors.quantumBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title, 
            style: QuantumTypography.h2.copyWith(
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'COMING SOON', 
            style: QuantumTypography.label.copyWith(
              color: QuantumColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _GlassStat({required this.icon, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? QuantumColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: QuantumTypography.bodySmall.copyWith(
            color: QuantumColors.nebulaWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
