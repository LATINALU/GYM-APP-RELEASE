import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'src/presentation/theme/quantum_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENTRY POINT - No Firebase, no login, no internet needed
// ═══════════════════════════════════════════════════════════════════════════
void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QUANTUM GYM - DEMO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DemoShell(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME MODE (Feature #3: toggle dark/light)
// ═══════════════════════════════════════════════════════════════════════════
enum DemoThemeMode { dark, highContrast }

extension DemoThemeColors on DemoThemeMode {
  Color get background => this == DemoThemeMode.highContrast ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A12);
  Color get surface => this == DemoThemeMode.highContrast ? const Color(0xFFF5F5F5) : const Color(0xFF0D0D1A);
  Color get cardBg => this == DemoThemeMode.highContrast ? const Color(0xFFEEEEEE) : const Color(0xFF151725);
  Color get primaryText => this == DemoThemeMode.highContrast ? const Color(0xFF1A1A2E) : Colors.white;
  Color get secondaryText => this == DemoThemeMode.highContrast ? const Color(0xFF555555) : Colors.white54;
  Color get tertiaryText => this == DemoThemeMode.highContrast ? const Color(0xFF888888) : Colors.white38;
  Color get subtleText => this == DemoThemeMode.highContrast ? const Color(0xFFAAAAAA) : Colors.white24;
  Color get borderC => this == DemoThemeMode.highContrast ? const Color(0xFFCCCCCC) : Colors.white;
  Color get accent => this == DemoThemeMode.highContrast ? const Color(0xFF0D47A1) : QuantumColors.quantumBlue;
  Color get accent2 => this == DemoThemeMode.highContrast ? const Color(0xFF0277BD) : QuantumColors.matrixCyan;
  Color get errorC => this == DemoThemeMode.highContrast ? const Color(0xFFC62828) : Colors.redAccent;
  Color get successC => this == DemoThemeMode.highContrast ? const Color(0xFF2E7D32) : Colors.greenAccent;
}

// ═══════════════════════════════════════════════════════════════════════════
// MOCK DATA - Routines & Exercises
// ═══════════════════════════════════════════════════════════════════════════
final _mockRoutines = <Map<String, dynamic>>[
  {
    'id': 'r1',
    'name': 'Push Day - Pecho y Hombros',
    'description': 'Rutina de empuje enfocada en pectorales y deltoides',
    'difficulty': 'Intermedio',
    'estimatedDuration': 65,
    'exercises': [
      {'exerciseId': 'e1', 'exerciseName': 'Press de Banca', 'muscleGroup': 'Pecho', 'sets': 4, 'reps': '8-10', 'restSeconds': 90},
      {'exerciseId': 'e2', 'exerciseName': 'Press Militar', 'muscleGroup': 'Hombros', 'sets': 3, 'reps': '10-12', 'restSeconds': 75},
      {'exerciseId': 'e3', 'exerciseName': 'Press Inclinado Mancuernas', 'muscleGroup': 'Pecho', 'sets': 3, 'reps': '10-12', 'restSeconds': 75},
      {'exerciseId': 'e4', 'exerciseName': 'Elevaciones Laterales', 'muscleGroup': 'Hombros', 'sets': 4, 'reps': '12-15', 'restSeconds': 60},
      {'exerciseId': 'e5', 'exerciseName': 'Extensiones de Tríceps', 'muscleGroup': 'Tríceps', 'sets': 3, 'reps': '12-15', 'restSeconds': 60},
    ],
  },
  {
    'id': 'r2',
    'name': 'Pull Day - Espalda y Bíceps',
    'description': 'Rutina de tracción para dorsal y bíceps',
    'difficulty': 'Intermedio',
    'estimatedDuration': 70,
    'exercises': [
      {'exerciseId': 'e6', 'exerciseName': 'Dominadas', 'muscleGroup': 'Espalda', 'sets': 4, 'reps': '6-10', 'restSeconds': 90},
      {'exerciseId': 'e7', 'exerciseName': 'Remo con Barra', 'muscleGroup': 'Espalda', 'sets': 4, 'reps': '8-10', 'restSeconds': 90},
      {'exerciseId': 'e8', 'exerciseName': 'Curl con Barra', 'muscleGroup': 'Bíceps', 'sets': 3, 'reps': '10-12', 'restSeconds': 60},
      {'exerciseId': 'e9', 'exerciseName': 'Curl Martillo', 'muscleGroup': 'Bíceps', 'sets': 3, 'reps': '12-15', 'restSeconds': 60},
    ],
  },
  {
    'id': 'r3',
    'name': 'Leg Day - Piernas Completas',
    'description': 'Entrenamiento de tren inferior completo',
    'difficulty': 'Avanzado',
    'estimatedDuration': 80,
    'exercises': [
      {'exerciseId': 'e10', 'exerciseName': 'Sentadilla', 'muscleGroup': 'Piernas', 'sets': 4, 'reps': '6-8', 'restSeconds': 120},
      {'exerciseId': 'e11', 'exerciseName': 'Peso Muerto Rumano', 'muscleGroup': 'Piernas', 'sets': 4, 'reps': '8-10', 'restSeconds': 90},
      {'exerciseId': 'e12', 'exerciseName': 'Prensa de Piernas', 'muscleGroup': 'Piernas', 'sets': 3, 'reps': '10-12', 'restSeconds': 75},
      {'exerciseId': 'e13', 'exerciseName': 'Elevación de Gemelos', 'muscleGroup': 'Piernas', 'sets': 4, 'reps': '15-20', 'restSeconds': 45},
    ],
  },
  {
    'id': 'r4',
    'name': 'Full Body Express',
    'description': 'Rutina completa de cuerpo entero en 45 min',
    'difficulty': 'Principiante',
    'estimatedDuration': 45,
    'exercises': [
      {'exerciseId': 'e14', 'exerciseName': 'Sentadilla Goblet', 'muscleGroup': 'Cuerpo Completo', 'sets': 3, 'reps': '12-15', 'restSeconds': 60},
      {'exerciseId': 'e15', 'exerciseName': 'Flexiones', 'muscleGroup': 'Pecho', 'sets': 3, 'reps': '10-15', 'restSeconds': 45},
      {'exerciseId': 'e16', 'exerciseName': 'Remo con Mancuerna', 'muscleGroup': 'Espalda', 'sets': 3, 'reps': '10-12', 'restSeconds': 60},
      {'exerciseId': 'e17', 'exerciseName': 'Plancha', 'muscleGroup': 'Abdominales', 'sets': 3, 'reps': '30-60s', 'restSeconds': 30},
    ],
  },
  {
    'id': 'r5',
    'name': 'Core & Abs Destructor',
    'description': 'Abdominales y core intenso',
    'difficulty': 'Intermedio',
    'estimatedDuration': 30,
    'exercises': [
      {'exerciseId': 'e18', 'exerciseName': 'Crunches', 'muscleGroup': 'Abdominales', 'sets': 4, 'reps': '15-20', 'restSeconds': 30},
      {'exerciseId': 'e19', 'exerciseName': 'Elevación de Piernas', 'muscleGroup': 'Abdominales', 'sets': 3, 'reps': '12-15', 'restSeconds': 30},
      {'exerciseId': 'e20', 'exerciseName': 'Russian Twists', 'muscleGroup': 'Abdominales', 'sets': 3, 'reps': '20-30', 'restSeconds': 30},
      {'exerciseId': 'e21', 'exerciseName': 'Plancha Lateral', 'muscleGroup': 'Abdominales', 'sets': 3, 'reps': '30-45s', 'restSeconds': 30},
    ],
  },
  {
    'id': 'r6',
    'name': 'Cardio HIIT Quema Grasa',
    'description': 'Alta intensidad para máxima quema calórica',
    'difficulty': 'Avanzado',
    'estimatedDuration': 25,
    'exercises': [
      {'exerciseId': 'e22', 'exerciseName': 'Burpees', 'muscleGroup': 'Cardio', 'sets': 5, 'reps': '15', 'restSeconds': 30},
      {'exerciseId': 'e23', 'exerciseName': 'Mountain Climbers', 'muscleGroup': 'Cardio', 'sets': 4, 'reps': '30s', 'restSeconds': 20},
      {'exerciseId': 'e24', 'exerciseName': 'Jumping Jacks', 'muscleGroup': 'Cardio', 'sets': 4, 'reps': '40', 'restSeconds': 20},
      {'exerciseId': 'e25', 'exerciseName': 'High Knees', 'muscleGroup': 'Cardio', 'sets': 4, 'reps': '30s', 'restSeconds': 20},
    ],
  },
];

// (exercises data embedded in routines for demo)

const _muscleGroups = ['Todos', 'Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Piernas', 'Glúteos', 'Abdominales', 'Cardio', 'Cuerpo Completo'];
const _difficulties = ['Todos', 'Principiante', 'Intermedio', 'Avanzado'];

// ═══════════════════════════════════════════════════════════════════════════
// DEMO SHELL - Role switcher + navigation
// ═══════════════════════════════════════════════════════════════════════════
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  DemoThemeMode _themeMode = DemoThemeMode.dark;
  int _currentRole = 0; // 0=Cliente, 1=Dueño, 2=Coach/Staff
  int _currentTab = 0;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == DemoThemeMode.dark ? DemoThemeMode.highContrast : DemoThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _themeMode;
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with role switcher + theme toggle
            _buildTopBar(t),
            // Role tabs
            _buildRoleTabs(t),
            // Content
            Expanded(
              child: _buildContent(t),
            ),
            // Bottom nav (role-specific)
            _buildBottomNav(t),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DemoThemeMode t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.borderC.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.accent, t.accent2]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'QUANTUM GYM',
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DEMO',
                  style: TextStyle(color: t.accent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Offline indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.successC.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: t.successC),
                    const SizedBox(width: 4),
                    Text('Offline OK', style: TextStyle(color: t.successC, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Theme toggle (Feature #3)
              IconButton(
                onPressed: _toggleTheme,
                icon: Icon(
                  t == DemoThemeMode.highContrast ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: t.accent,
                ),
                tooltip: 'Toggle tema',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs(DemoThemeMode t) {
    final roles = ['Cliente', 'Dueño', 'Coach'];
    final icons = [Icons.person_rounded, Icons.business_rounded, Icons.sports_rounded];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final selected = _currentRole == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _currentRole = i; _currentTab = 0; }),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? t.accent.withValues(alpha: 0.15) : t.borderC.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? t.accent.withValues(alpha: 0.5) : t.borderC.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[i], color: selected ? t.accent : t.tertiaryText, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      roles[i],
                      style: TextStyle(
                        color: selected ? t.primaryText : t.secondaryText,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent(DemoThemeMode t) {
    switch (_currentRole) {
      case 0:
        return _buildClientView(t);
      case 1:
        return _buildOwnerView(t);
      case 2:
        return _buildCoachView(t);
      default:
        return _buildClientView(t);
    }
  }

  Widget _buildBottomNav(DemoThemeMode t) {
    final navItems = switch (_currentRole) {
      0 => const [('Hub', Icons.grid_view_rounded), ('Entreno', Icons.fitness_center_rounded), ('QR', Icons.qr_code_2_rounded), ('Stats', Icons.analytics_outlined)],
      1 => const [('Dashboard', Icons.dashboard_rounded), ('Miembros', Icons.people_alt_rounded), ('Rutinas', Icons.architecture_rounded), ('Gym', Icons.store_rounded)],
      _ => const [('Inicio', Icons.home_rounded), ('Escanear', Icons.qr_code_scanner_rounded), ('Rutinas', Icons.fitness_center_rounded)],
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.borderC.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (i) {
          final selected = _currentTab == i;
          return GestureDetector(
            onTap: () => setState(() => _currentTab = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(navItems[i].$2, color: selected ? t.accent : t.tertiaryText, size: 24),
                const SizedBox(height: 4),
                Text(
                  navItems[i].$1,
                  style: TextStyle(
                    color: selected ? t.accent : t.tertiaryText,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENTE VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildClientView(DemoThemeMode t) {
    switch (_currentTab) {
      case 0:
        return _clientHome(t);
      case 1:
        return _clientRoutines(t);
      case 2:
        return _clientQr(t);
      case 3:
        return _clientStats(t);
      default:
        return _clientHome(t);
    }
  }

  Widget _clientHome(DemoThemeMode t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [t.accent, t.accent2]),
                ),
                child: const Center(child: Text('C', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Hola, Carlos!', style: TextStyle(color: t.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Es hora de entrenar 💪', style: TextStyle(color: t.secondaryText, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick actions
          Row(
            children: [
              _buildActionCard(t, 'Acceso QR', Icons.qr_code, [t.accent, t.accent2]),
              const SizedBox(width: 8),
              _buildActionCard(t, 'Historial', Icons.analytics_outlined, [Colors.purple, t.accent2]),
              const SizedBox(width: 8),
              _buildActionCard(t, 'Rutinas', Icons.bolt_rounded, [t.accent2, t.accent]),
            ],
          ),
          const SizedBox(height: 24),
          // Current routine card
          Text('TU PLAN ACTUAL', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.accent, t.accent2]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    const Text('4 DÍAS / SEMANA', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('PUSH PULL LEGS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Rutina de hipertrofia dividida en 4 días', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('CONTINUAR SESIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          Text('TUS ESTADÍSTICAS', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(t, '12', 'Sesiones', Icons.fitness_center),
              const SizedBox(width: 8),
              _buildStatCard(t, '4.5h', 'Tiempo total', Icons.timer),
              const SizedBox(width: 8),
              _buildStatCard(t, '8,420', 'Calorías', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clientRoutines(DemoThemeMode t) {
    return _RoutineBrowser(
      themeMode: t,
      routines: _mockRoutines,
      title: 'DESCUBRIR RUTINAS',
      showShareQr: true,
    );
  }

  Widget _clientQr(DemoThemeMode t) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    final payload = jsonEncode({
      'type': 'client_checkin',
      'userId': 'demo-client-001',
      'gymId': 'demo-gym',
      'userName': 'Carlos Demo',
      'membershipStatus': 'approved',
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('PASE DIGITAL', style: TextStyle(color: t.primaryText, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Muestra este QR en recepción', style: TextStyle(color: t.secondaryText, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: QrImageView(data: payload, version: QrVersions.auto, size: 200, gapless: true),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.errorC.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.errorC.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: t.errorC, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Expira en 10 min (${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')})',
                  style: TextStyle(color: t.errorC, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientStats(DemoThemeMode t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANALYTICS', style: TextStyle(color: t.primaryText, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildStatCardBig(t, '12', 'Sesiones esta semana', Icons.fitness_center, t.accent),
          const SizedBox(height: 12),
          _buildStatCardBig(t, '4h 32min', 'Tiempo total', Icons.timer, t.accent2),
          const SizedBox(height: 12),
          _buildStatCardBig(t, '8,420 kcal', 'Calorías quemadas', Icons.local_fire_department, Colors.orange),
          const SizedBox(height: 12),
          _buildStatCardBig(t, '+15%', 'Progreso vs semana anterior', Icons.trending_up, t.successC),
          const SizedBox(height: 24),
          Text('GRUPOS MUSCULARES ENTRENADOS', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          ...['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Bíceps'].map((mg) => _buildMuscleBar(t, mg, (mg.length * 17) % 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DUEÑO VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOwnerView(DemoThemeMode t) {
    switch (_currentTab) {
      case 0:
        return _ownerDashboard(t);
      case 1:
        return _ownerMembers(t);
      case 2:
        return _ownerRoutines(t);
      case 3:
        return _ownerGymInfo(t);
      default:
        return _ownerDashboard(t);
    }
  }

  Widget _ownerDashboard(DemoThemeMode t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMAND CENTER', style: TextStyle(color: t.primaryText, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Gaia AI: Online', style: TextStyle(color: t.accent2, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          // KPIs
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(t, '142', 'Membresías Activas', Icons.people_rounded, t.accent),
              _buildKpiCard(t, r'$18,450', 'Ingresos del Mes', Icons.attach_money_rounded, t.successC),
              _buildKpiCard(t, '87', 'Accesos 24h', Icons.login_rounded, t.accent2),
              _buildKpiCard(t, '3.2%', 'Churn Rate', Icons.trending_down, t.errorC),
            ],
          ),
          const SizedBox(height: 24),
          // Quick actions
          Text('ACCIONES RÁPIDAS', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(t, 'Gestión de Miembros', Icons.people),
              _buildActionChip(t, 'Crear Rutina', Icons.architecture),
              _buildActionChip(t, 'Accesos', Icons.door_front_door),
              _buildActionChip(t, 'Reportes', Icons.assessment),
              _buildActionChip(t, 'Membresías', Icons.card_membership),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerMembers(DemoThemeMode t) {
    final members = [
      {'name': 'Carlos Ruiz', 'email': 'carlos@email.com', 'status': 'Activo', 'plan': 'Premium', 'since': 'Ene 2025'},
      {'name': 'María González', 'email': 'maria@email.com', 'status': 'Activo', 'plan': 'Estándar', 'since': 'Mar 2025'},
      {'name': 'Juan Pérez', 'email': 'juan@email.com', 'status': 'Pendiente', 'plan': 'Estándar', 'since': 'Jul 2025'},
      {'name': 'Ana Torres', 'email': 'ana@email.com', 'status': 'Activo', 'plan': 'Premium', 'since': 'Dic 2024'},
      {'name': 'Luis Martín', 'email': 'luis@email.com', 'status': 'Vencido', 'plan': 'Estándar', 'since': 'Ago 2024'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (ctx, i) {
        final m = members[i];
        final statusColor = m['status'] == 'Activo' ? t.successC : m['status'] == 'Pendiente' ? Colors.orange : t.errorC;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [t.accent, t.accent2])),
                child: Center(child: Text(m['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['name']!, style: TextStyle(color: t.primaryText, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(m['email']!, style: TextStyle(color: t.tertiaryText, fontSize: 12)),
                    Text('${m['plan']} · Desde ${m['since']}', style: TextStyle(color: t.subtleText, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(m['status']!, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ownerRoutines(DemoThemeMode t) {
    return _RoutineBrowser(
      themeMode: t,
      routines: _mockRoutines,
      title: 'TRAINING FORGE',
      showShareQr: true,
      showEdit: true,
    );
  }

  Widget _ownerGymInfo(DemoThemeMode t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INFO DEL GIMNASIO', style: TextStyle(color: t.primaryText, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildInfoCard(t, 'Nombre', 'Quantum Fitness Center'),
          _buildInfoCard(t, 'Dirección', 'Av. Reforma 1234, CDMX'),
          _buildInfoCard(t, 'Teléfono', '+52 55 1234 5678'),
          _buildInfoCard(t, 'Membresías activas', '142'),
          _buildInfoCard(t, 'Plan', 'Premium Owner'),
          _buildInfoCard(t, 'Horario', '5:00 AM - 11:00 PM'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COACH/STAFF VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoachView(DemoThemeMode t) {
    switch (_currentTab) {
      case 0:
        return _coachHome(t);
      case 1:
        return _coachScanner(t);
      case 2:
        return _coachRoutines(t);
      default:
        return _coachHome(t);
    }
  }

  Widget _coachHome(DemoThemeMode t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [t.accent, t.accent2]), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.sports, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, Entrenador', style: TextStyle(color: t.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Panel de entrenador', style: TextStyle(color: t.secondaryText, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats
          Row(
            children: [
              _buildStatCard(t, '23', 'Check-ins hoy', Icons.login),
              const SizedBox(width: 8),
              _buildStatCard(t, '45', 'Clientes activos', Icons.people),
              const SizedBox(width: 8),
              _buildStatCard(t, '6', 'Rutinas asignadas', Icons.fitness_center),
            ],
          ),
          const SizedBox(height: 24),
          // Quick actions
          Text('ACCIONES RÁPIDAS', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(t, 'Escanear QR', Icons.qr_code_scanner),
              _buildActionChip(t, 'Asignar Rutina', Icons.assignment),
              _buildActionChip(t, 'Gestionar Rutinas', Icons.fitness_center),
              _buildActionChip(t, 'Ver Clientes', Icons.people),
            ],
          ),
          const SizedBox(height: 24),
          // Recent check-ins
          Text('CHECK-INS RECIENTES', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          ...['Carlos Ruiz - 14:32', 'María González - 14:15', 'Ana Torres - 13:48', 'Pedro Ramírez - 12:30'].map((ci) => _buildCheckInItem(t, ci)),
        ],
      ),
    );
  }

  Widget _coachScanner(DemoThemeMode t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: t.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: t.accent.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.qr_code_scanner_rounded, size: 100, color: t.accent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text('ESCANEAR QR', style: TextStyle(color: t.primaryText, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Escanea el pase digital del cliente', style: TextStyle(color: t.secondaryText, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: const Text('Abrir Cámara'),
            style: ElevatedButton.styleFrom(backgroundColor: t.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _coachRoutines(DemoThemeMode t) {
    return _RoutineBrowser(
      themeMode: t,
      routines: _mockRoutines,
      title: 'GESTIÓN DE RUTINAS',
      showShareQr: true,
      showEdit: true,
      showDuplicate: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionCard(DemoThemeMode t, String label, IconData icon, List<Color> gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => LinearGradient(colors: gradient).createShader(b),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: t.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(DemoThemeMode t, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: t.accent, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: t.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: t.tertiaryText, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardBig(DemoThemeMode t, String value, String label, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: t.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: t.secondaryText, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(DemoThemeMode t, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: TextStyle(color: t.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: t.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActionChip(DemoThemeMode t, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: t.accent, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: t.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DemoThemeMode t, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: t.secondaryText, fontSize: 14)),
          Text(value, style: TextStyle(color: t.primaryText, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMuscleBar(DemoThemeMode t, String muscle, int percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(muscle, style: TextStyle(color: t.secondaryText, fontSize: 12)),
              Text('$percent%', style: TextStyle(color: t.accent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: t.borderC.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(t.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInItem(DemoThemeMode t, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.login, color: t.successC, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: t.primaryText, fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROUTINE BROWSER - Reusable widget with filters + share QR
// Features: #1 Muscle group filters, #2 QR with 10-min expiry, Share QR
// ═══════════════════════════════════════════════════════════════════════════
class _RoutineBrowser extends StatefulWidget {
  final DemoThemeMode themeMode;
  final List<Map<String, dynamic>> routines;
  final String title;
  final bool showShareQr;
  final bool showEdit;
  final bool showDuplicate;

  const _RoutineBrowser({
    required this.themeMode,
    required this.routines,
    required this.title,
    this.showShareQr = false,
    this.showEdit = false,
    this.showDuplicate = false,
  });

  @override
  State<_RoutineBrowser> createState() => _RoutineBrowserState();
}

class _RoutineBrowserState extends State<_RoutineBrowser> {
  String _searchQuery = '';
  String _selectedDifficulty = 'Todos';
  String _selectedMuscleGroup = 'Todos';

  @override
  Widget build(BuildContext context) {
    final t = widget.themeMode;
    var filtered = widget.routines.where((r) {
      if (_selectedDifficulty != 'Todos' && r['difficulty'] != _selectedDifficulty) return false;
      if (_selectedMuscleGroup != 'Todos') {
        final exercises = r['exercises'] as List;
        final hasMuscle = exercises.any((ex) {
          final mg = (ex['muscleGroup'] ?? '').toString().toLowerCase();
          return mg.contains(_selectedMuscleGroup.toLowerCase());
        });
        if (!hasMuscle) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        final desc = (r['description'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase()) && !desc.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.title, style: TextStyle(color: t.primaryText, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ),
        // Search bar
        _buildSearch(t),
        // Muscle group filters (Feature #1)
        _buildMuscleFilters(t),
        // Difficulty filters
        _buildDifficultyFilters(t),
        const SizedBox(height: 8),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} rutinas', style: TextStyle(color: t.tertiaryText, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
        // Grid
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(t)
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildRoutineCard(t, filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSearch(DemoThemeMode t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: t.borderC.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.borderC.withValues(alpha: 0.08)),
        ),
        child: TextField(
          style: TextStyle(color: t.primaryText, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar rutina...',
            hintStyle: TextStyle(color: t.tertiaryText, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: t.tertiaryText, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  Widget _buildMuscleFilters(DemoThemeMode t) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _muscleGroups.length,
        itemBuilder: (ctx, i) {
          final mg = _muscleGroups[i];
          final selected = _selectedMuscleGroup == mg;
          return GestureDetector(
            onTap: () => setState(() => _selectedMuscleGroup = mg),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? t.accent.withValues(alpha: 0.15) : t.borderC.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? t.accent.withValues(alpha: 0.5) : t.borderC.withValues(alpha: 0.05)),
              ),
              child: Text(
                mg,
                style: TextStyle(
                  color: selected ? t.accent : t.tertiaryText,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilters(DemoThemeMode t) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _difficulties.length,
        itemBuilder: (ctx, i) {
          final d = _difficulties[i];
          final selected = _selectedDifficulty == d;
          return GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = d),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? t.accent2.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? t.accent2.withValues(alpha: 0.4) : Colors.transparent),
              ),
              child: Text(
                d,
                style: TextStyle(
                  color: selected ? t.accent2 : t.tertiaryText,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineCard(DemoThemeMode t, Map<String, dynamic> routine) {
    final exercises = routine['exercises'] as List;
    final diffColor = _getDiffColor(t, routine['difficulty'] as String);

    return Container(
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: t.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.fitness_center, color: t.accent, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    routine['name'] as String,
                    style: TextStyle(color: t.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Popup menu with Share QR
                if (widget.showShareQr || widget.showEdit || widget.showDuplicate)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: t.tertiaryText, size: 18),
                    color: t.cardBg,
                    onSelected: (v) => _handleMenuAction(t, v, routine),
                    itemBuilder: (_) => [
                      if (widget.showShareQr)
                        PopupMenuItem(value: 'share_qr', child: Row(children: [Icon(Icons.qr_code_rounded, color: t.accent, size: 18), const SizedBox(width: 8), Text('Compartir QR', style: TextStyle(color: t.primaryText))])),
                      if (widget.showEdit)
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: t.secondaryText, size: 18), const SizedBox(width: 8), Text('Editar', style: TextStyle(color: t.primaryText))])),
                      if (widget.showDuplicate)
                        PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, color: t.secondaryText, size: 18), const SizedBox(width: 8), Text('Duplicar', style: TextStyle(color: t.primaryText))])),
                      PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info, color: t.secondaryText, size: 18), const SizedBox(width: 8), Text('Ver Detalles', style: TextStyle(color: t.primaryText))])),
                    ],
                  ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine['description'] as String,
                    style: TextStyle(color: t.secondaryText, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildChip(t, '${exercises.length} ejercicios'),
                      _buildChip(t, '${routine['estimatedDuration']} min'),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      routine['difficulty'] as String,
                      style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(DemoThemeMode t, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: t.borderC.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: t.tertiaryText, fontSize: 10)),
    );
  }

  Color _getDiffColor(DemoThemeMode t, String diff) {
    switch (diff) {
      case 'Principiante':
        return t.successC;
      case 'Intermedio':
        return t.accent2;
      case 'Avanzado':
        return t.errorC;
      default:
        return t.accent;
    }
  }

  void _handleMenuAction(DemoThemeMode t, String action, Map<String, dynamic> routine) {
    switch (action) {
      case 'share_qr':
        _showQrDialog(t, routine);
        break;
      case 'details':
        _showDetailsDialog(t, routine);
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editar: ${routine['name']}'), backgroundColor: t.accent),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicar: ${routine['name']}'), backgroundColor: t.accent2),
        );
        break;
    }
  }

  // Feature #2: QR with 10-minute expiration
  void _showQrDialog(DemoThemeMode t, Map<String, dynamic> routine) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    final payload = jsonEncode({
      'type': 'routine_import',
      'routineId': routine['id'],
      'name': routine['name'],
      'difficulty': routine['difficulty'],
      'exercises': routine['exercises'],
      'estimatedDuration': routine['estimatedDuration'],
      'description': routine['description'],
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    });

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COMPARTIR RUTINA', style: TextStyle(color: t.primaryText, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  IconButton(icon: Icon(Icons.close, color: t.tertiaryText), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: payload, version: QrVersions.auto, size: 200, gapless: true),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: t.accent, size: 16),
                    const SizedBox(width: 6),
                    Flexible(child: Text(routine['name'] as String, style: TextStyle(color: t.accent, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: t.errorC.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.errorC.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: t.errorC, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Expira en 10 min (${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')})',
                      style: TextStyle(color: t.errorC, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escanea desde la app móvil > Escáner > Importar rutina\nExpira en 10 minutos por seguridad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.subtleText, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(DemoThemeMode t, Map<String, dynamic> routine) {
    final exercises = routine['exercises'] as List;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(routine['name'] as String, style: TextStyle(color: t.primaryText, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: Icon(Icons.close, color: t.tertiaryText), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text(routine['description'] as String, style: TextStyle(color: t.secondaryText, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(t, routine['difficulty'] as String),
                  const SizedBox(width: 6),
                  _buildChip(t, '${routine['estimatedDuration']} min'),
                  const SizedBox(width: 6),
                  _buildChip(t, '${exercises.length} ejercicios'),
                ],
              ),
              const SizedBox(height: 20),
              Text('EJERCICIOS', style: TextStyle(color: t.secondaryText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = exercises[i] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: t.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.borderC.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: t.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text('${i + 1}', style: TextStyle(color: t.accent, fontSize: 12, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex['exerciseName'] as String, style: TextStyle(color: t.primaryText, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('${ex['muscleGroup']} · ${ex['sets']}x${ex['reps']} · ${ex['restSeconds']}s descanso', style: TextStyle(color: t.tertiaryText, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(DemoThemeMode t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: t.borderC.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('No se encontraron rutinas', style: TextStyle(color: t.tertiaryText, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Prueba con otros filtros', style: TextStyle(color: t.subtleText, fontSize: 12)),
        ],
      ),
    );
  }
}
