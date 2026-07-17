import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_state_notifier.dart';
import '../../theme/quantum_colors.dart';

/// Kiosk theme mode for accessibility.
enum KioskThemeMode { dark, highContrast }

/// Extension helpers for kiosk theme colors.
extension KioskThemeColors on KioskThemeMode {
  Color get background => this == KioskThemeMode.highContrast
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF0A0A12);
  Color get surface => this == KioskThemeMode.highContrast
      ? const Color(0xFFF5F5F5)
      : const Color(0xFF0D0D1A);
  Color get cardBackground => this == KioskThemeMode.highContrast
      ? const Color(0xFFEEEEEE)
      : const Color(0xFF151725);
  Color get primaryText => this == KioskThemeMode.highContrast
      ? const Color(0xFF1A1A2E)
      : Colors.white;
  Color get secondaryText => this == KioskThemeMode.highContrast
      ? const Color(0xFF555555)
      : Colors.white54;
  Color get tertiaryText => this == KioskThemeMode.highContrast
      ? const Color(0xFF888888)
      : Colors.white38;
  Color get subtleText => this == KioskThemeMode.highContrast
      ? const Color(0xFFAAAAAA)
      : Colors.white24;
  Color get borderAlpha => this == KioskThemeMode.highContrast
      ? const Color(0xFFCCCCCC)
      : Colors.white;
  Color get accent => this == KioskThemeMode.highContrast
      ? const Color(0xFF0D47A1)
      : QuantumColors.quantumBlue;
  Color get accentText => this == KioskThemeMode.highContrast
      ? const Color(0xFF0D47A1)
      : QuantumColors.quantumBlue;
  Color get successColor => this == KioskThemeMode.highContrast
      ? const Color(0xFF2E7D32)
      : QuantumColors.success;
  Color get errorColor => this == KioskThemeMode.highContrast
      ? const Color(0xFFC62828)
      : Colors.redAccent;
  Color get buttonTextColor => this == KioskThemeMode.highContrast
      ? Colors.white
      : Colors.black;
}

/// Full-screen kiosk mode for desktop.
/// Gym users can browse routines, create custom routines, and generate QR codes
/// to import routines into their mobile app profile.
class KioskRoutineScreen extends StatefulWidget {
  final String? gymId;

  const KioskRoutineScreen({super.key, this.gymId});

  @override
  State<KioskRoutineScreen> createState() => _KioskRoutineScreenState();
}

class _KioskRoutineScreenState extends State<KioskRoutineScreen> {
  late String _gymId;
  int _currentIndex = 0;
  String _searchQuery = '';
  String _selectedDifficulty = 'Todos';
  String _selectedMuscleGroup = 'Todos';
  KioskThemeMode _themeMode = KioskThemeMode.dark;
  bool _isOffline = false;
  List<Map<String, dynamic>> _cachedRoutines = [];
  final List<String> _difficulties = ['Todos', 'Principiante', 'Intermedio', 'Avanzado'];
  final List<String> _muscleGroups = [
    'Todos', 'Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps',
    'Piernas', 'Glúteos', 'Abdominales', 'Cardio', 'Cuerpo Completo',
  ];

  @override
  void initState() {
    super.initState();
    _gymId = widget.gymId ??
        AuthStateNotifier.instance.profile?.gymId?.value ??
        '';
    _loadThemePreference();
    _loadCachedData();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isHighContrast = prefs.getBool('kiosk_high_contrast') ?? false;
    setState(() => _themeMode = isHighContrast
        ? KioskThemeMode.highContrast
        : KioskThemeMode.dark);
  }

  Future<void> _toggleTheme() async {
    final newMode = _themeMode == KioskThemeMode.dark
        ? KioskThemeMode.highContrast
        : KioskThemeMode.dark;
    setState(() => _themeMode = newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kiosk_high_contrast', newMode == KioskThemeMode.highContrast);
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final routinesJson = prefs.getString('kiosk_cached_routines_$_gymId');
    if (routinesJson != null) {
      try {
        final list = jsonDecode(routinesJson) as List;
        _cachedRoutines = list.cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _cacheRoutines(List<Map<String, dynamic>> routines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kiosk_cached_routines_$_gymId', jsonEncode(routines));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeMode.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildKioskHeader(),
            _buildTabBar(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildBrowseRoutinesView(),
                  _buildCreateRoutineView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKioskHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      decoration: BoxDecoration(
        color: _themeMode.surface,
        border: Border(
          bottom: BorderSide(color: _themeMode.borderAlpha.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _themeMode.accent,
                      _themeMode == KioskThemeMode.highContrast
                          ? const Color(0xFF0277BD)
                          : QuantumColors.matrixCyan,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KIOSKO DE RUTINAS',
                    style: QuantumTypography.h3.copyWith(
                      fontSize: 22,
                      letterSpacing: 2,
                      color: _themeMode.primaryText,
                    ),
                  ),
                  Text(
                    'Explora y crea tu rutina personalizada',
                    style: QuantumTypography.caption.copyWith(
                      color: _themeMode.tertiaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Offline indicator
              if (_isOffline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _themeMode.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _themeMode.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded, color: _themeMode.errorColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'SIN CONEXIÓN',
                        style: TextStyle(
                          color: _themeMode.errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _themeMode.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _themeMode.successColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sensors_rounded, color: _themeMode.successColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'EN VIVO',
                        style: TextStyle(
                          color: _themeMode.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 16),
              // Theme toggle button
              GestureDetector(
                onTap: _toggleTheme,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _themeMode.borderAlpha.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _themeMode.borderAlpha.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Icon(
                    _themeMode == KioskThemeMode.highContrast
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: _themeMode.secondaryText,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                DateTime.now().toString().split(' ')[0],
                style: TextStyle(color: _themeMode.tertiaryText, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      child: Row(
        children: [
          _buildTabItem('Explorar Rutinas', Icons.explore_rounded, 0),
          const SizedBox(width: 12),
          _buildTabItem('Crear Mi Rutina', Icons.add_circle_outline_rounded, 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _themeMode.accent.withValues(alpha: 0.15)
              : _themeMode.borderAlpha.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _themeMode.accent.withValues(alpha: 0.5)
                : _themeMode.borderAlpha.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _themeMode.accent : _themeMode.tertiaryText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _themeMode.primaryText : _themeMode.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BROWSE ROUTINES VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBrowseRoutinesView() {
    if (_gymId.isEmpty) {
      return _buildNoGymState();
    }

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('routines')
                .where('gymId', isEqualTo: _gymId)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              // Offline fallback: use cached data when stream errors
              if (snapshot.hasError) {
                if (!_isOffline) setState(() => _isOffline = true);
                return _buildOfflineRoutineGrid();
              }
              if (_isOffline && snapshot.hasData) {
                setState(() => _isOffline = false);
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _cachedRoutines.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _cachedRoutines.isNotEmpty) {
                return _buildOfflineRoutineGrid();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                if (_cachedRoutines.isNotEmpty) {
                  return _buildOfflineRoutineGrid();
                }
                return _buildEmptyRoutinesState();
              }

              // Cache the routines for offline use
              final allRoutines = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();
              _cacheRoutines(allRoutines.cast<Map<String, dynamic>>());

              var routines = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (_selectedDifficulty != 'Todos' &&
                    data['difficulty'] != _selectedDifficulty) {
                  return false;
                }
                if (_selectedMuscleGroup != 'Todos') {
                  final exercises = data['exercises'] as List? ?? [];
                  final hasMuscle = exercises.any((ex) {
                    final mg = (ex['muscleGroup'] ?? ex['primaryMuscle'] ?? '').toString();
                    return mg.toLowerCase().contains(_selectedMuscleGroup.toLowerCase());
                  });
                  if (!hasMuscle) return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  if (!name.contains(_searchQuery.toLowerCase()) &&
                      !desc.contains(_searchQuery.toLowerCase())) {
                    return false;
                  }
                }
                return true;
              }).toList();

              if (routines.isEmpty) {
                return _buildEmptyRoutinesState();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(48),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final data = routines[index].data() as Map<String, dynamic>;
                  return _buildRoutineCard(
                    routines[index].id,
                    data,
                  ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineRoutineGrid() {
    var routines = _cachedRoutines.where((data) {
      if (_selectedDifficulty != 'Todos' &&
          data['difficulty'] != _selectedDifficulty) {
        return false;
      }
      if (_selectedMuscleGroup != 'Todos') {
        final exercises = data['exercises'] as List? ?? [];
        final hasMuscle = exercises.any((ex) {
          final mg = (ex['muscleGroup'] ?? ex['primaryMuscle'] ?? '').toString();
          return mg.toLowerCase().contains(_selectedMuscleGroup.toLowerCase());
        });
        if (!hasMuscle) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase()) &&
            !desc.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    if (routines.isEmpty) {
      return _buildEmptyRoutinesState();
    }

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(48),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final data = routines[index];
            final id = data['id'] ?? '';
            return _buildRoutineCard(id, data)
                .animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05);
          },
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _themeMode.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _themeMode.errorColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: _themeMode.errorColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Mostrando rutinas en caché',
                  style: TextStyle(color: _themeMode.errorColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _themeMode.borderAlpha.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _themeMode.borderAlpha.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    style: TextStyle(color: _themeMode.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o descripción...',
                      hintStyle: TextStyle(color: _themeMode.tertiaryText),
                      prefixIcon: Icon(Icons.search, color: _themeMode.tertiaryText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Difficulty filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: _difficulties.length,
                  itemBuilder: (context, index) {
                    final d = _difficulties[index];
                    final isSelected = d == _selectedDifficulty;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDifficulty = d),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _themeMode.accent
                              : _themeMode.borderAlpha.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? _themeMode.accent
                                : _themeMode.borderAlpha.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              color: isSelected ? _themeMode.buttonTextColor : _themeMode.secondaryText,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Muscle group filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final mg = _muscleGroups[index];
                final isSelected = mg == _selectedMuscleGroup;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMuscleGroup = mg),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _themeMode.accent.withValues(alpha: 0.15)
                          : _themeMode.borderAlpha.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _themeMode.accent.withValues(alpha: 0.5)
                            : _themeMode.borderAlpha.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          size: 14,
                          color: isSelected ? _themeMode.accent : _themeMode.tertiaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mg,
                          style: TextStyle(
                            color: isSelected ? _themeMode.accent : _themeMode.secondaryText,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Sin nombre';
    final difficulty = data['difficulty'] ?? 'Intermedio';
    final exerciseCount = (data['exercises'] as List?)?.length ?? 0;
    final duration = data['estimatedDuration'] ?? 60;
    final description = data['description'] ?? '';
    final diffColor = _getDifficultyColor(difficulty);

    return GestureDetector(
      onTap: () => _showRoutineDetailDialog(id, data),
      child: Container(
        decoration: BoxDecoration(
          color: _themeMode.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _themeMode.borderAlpha.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    diffColor.withValues(alpha: 0.2),
                    diffColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Icon(
                  Icons.architecture_rounded,
                  size: 56,
                  color: diffColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _themeMode.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      difficulty,
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(color: _themeMode.tertiaryText, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, size: 14, color: _themeMode.tertiaryText),
                          const SizedBox(width: 4),
                          Text(
                            '$exerciseCount ejercicios',
                            style: TextStyle(color: _themeMode.tertiaryText, fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: _themeMode.tertiaryText),
                          const SizedBox(width: 4),
                          Text(
                            '$duration min',
                            style: TextStyle(color: _themeMode.tertiaryText, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineDetailDialog(String id, Map<String, dynamic> data) {
    final exercises = (data['exercises'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _themeMode.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['name'] ?? 'Rutina',
                      style: QuantumTypography.h2.copyWith(fontSize: 24, color: _themeMode.primaryText),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _themeMode.tertiaryText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? '',
                style: TextStyle(color: _themeMode.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Divider(color: _themeMode.borderAlpha.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(
                'EJERCICIOS (${exercises.length})',
                style: QuantumTypography.caption.copyWith(letterSpacing: 1.5, color: _themeMode.secondaryText),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = exercises[i] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _themeMode.borderAlpha.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _themeMode.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: _themeMode.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex['exerciseName'] ?? ex['name'] ?? 'Ejercicio',
                                  style: TextStyle(
                                    color: _themeMode.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (ex['muscleGroup'] != null)
                                  Text(
                                    ex['muscleGroup'],
                                    style: TextStyle(
                                      color: _themeMode.tertiaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (ex['sets'] != null)
                            Text(
                              '${ex['sets']}x${ex['reps'] ?? '10'}',
                              style: TextStyle(
                                color: _themeMode == KioskThemeMode.highContrast
                                    ? const Color(0xFF0277BD)
                                    : QuantumColors.matrixCyan,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GymButtonKiosk(
                    text: 'Generar QR',
                    icon: Icons.qr_code_rounded,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQrDialog(id, data);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE ROUTINE VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCreateRoutineView() {
    return _CreateRoutinePanel(
      gymId: _gymId,
      themeMode: _themeMode,
      onRoutineCreated: _showQrDialog,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QR DIALOG
  // ═══════════════════════════════════════════════════════════════════════════
  void _showQrDialog(String routineId, Map<String, dynamic> routineData) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));
    final qrPayload = jsonEncode({
      'type': 'routine_import',
      'routineId': routineId,
      'gymId': _gymId,
      'name': routineData['name'],
      'difficulty': routineData['difficulty'],
      'exercises': routineData['exercises'],
      'estimatedDuration': routineData['estimatedDuration'] ?? 60,
      'description': routineData['description'] ?? '',
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: _themeMode.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CÓDIGO QR DE RUTINA',
                    style: QuantumTypography.h3.copyWith(letterSpacing: 2, color: _themeMode.primaryText),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _themeMode.tertiaryText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Escanea con la app móvil para importar esta rutina',
                style: TextStyle(color: _themeMode.tertiaryText, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 280,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _themeMode.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: _themeMode.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      routineData['name'] ?? 'Rutina',
                      style: TextStyle(
                        color: _themeMode.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Expiration notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _themeMode.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _themeMode.errorColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: _themeMode.errorColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Expira en 10 minutos (${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')})',
                      style: TextStyle(
                        color: _themeMode.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'El código QR contiene toda la información de la rutina.\n'
                'Expira en 10 minutos por seguridad.\n'
                'Ábrelo desde la app móvil > Escáner > Importar rutina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _themeMode.subtleText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNoGymState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: _themeMode.borderAlpha.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Sin gimnasio configurado',
            style: TextStyle(color: _themeMode.secondaryText, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacta al personal del gimnasio para configurar el acceso.',
            style: TextStyle(color: _themeMode.tertiaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoutinesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_outlined, size: 80, color: _themeMode.borderAlpha.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No hay rutinas disponibles',
            style: TextStyle(color: _themeMode.secondaryText, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'El gimnasio aún no ha publicado rutinas.\nCrea tu propia rutina en la pestaña "Crear Mi Rutina".',
            textAlign: TextAlign.center,
            style: TextStyle(color: _themeMode.tertiaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Principiante':
        return _themeMode.successColor;
      case 'Intermedio':
        return _themeMode == KioskThemeMode.highContrast
            ? const Color(0xFFE65100)
            : QuantumColors.accent;
      case 'Avanzado':
        return _themeMode.errorColor;
      default:
        return _themeMode.accent;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CREATE ROUTINE PANEL
// ═════════════════════════════════════════════════════════════════════════════
class _CreateRoutinePanel extends StatefulWidget {
  final String gymId;
  final KioskThemeMode themeMode;
  final void Function(String routineId, Map<String, dynamic> routineData) onRoutineCreated;

  const _CreateRoutinePanel({
    required this.gymId,
    required this.themeMode,
    required this.onRoutineCreated,
  });

  @override
  State<_CreateRoutinePanel> createState() => _CreateRoutinePanelState();
}

class _CreateRoutinePanelState extends State<_CreateRoutinePanel> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  String _selectedDifficulty = 'Intermedio';
  String _searchQuery = '';
  List<Map<String, dynamic>> _selectedExercises = [];
  bool _isSaving = false;

  final List<String> _difficulties = ['Principiante', 'Intermedio', 'Avanzado'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Exercise Library
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildExerciseSearch(),
              Expanded(child: _buildExerciseList()),
            ],
          ),
        ),
        // Right: Routine Builder
        Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.themeMode.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.themeMode.borderAlpha.withValues(alpha: 0.06)),
          ),
          child: _buildRoutineSummary(),
        ),
      ],
    );
  }

  Widget _buildExerciseSearch() {
    final t = widget.themeMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.borderAlpha.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.borderAlpha.withValues(alpha: 0.08)),
              ),
              child: TextField(
                style: TextStyle(color: t.primaryText),
                decoration: InputDecoration(
                  hintText: 'Buscar ejercicio por nombre o músculo...',
                  hintStyle: TextStyle(color: t.tertiaryText),
                  prefixIcon: Icon(Icons.search, color: t.tertiaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    final t = widget.themeMode;
    if (widget.gymId.isEmpty) {
      return Center(
        child: Text(
          'Sin gimnasio configurado',
          style: TextStyle(color: t.tertiaryText, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exercises')
          .where('gymId', isEqualTo: widget.gymId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64, color: t.errorColor.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('Sin conexión. Intenta más tarde.',
                    style: TextStyle(color: t.tertiaryText, fontSize: 16)),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_outlined, size: 64, color: t.borderAlpha.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'No hay ejercicios disponibles',
                  style: TextStyle(color: t.tertiaryText, fontSize: 16),
                ),
              ],
            ),
          );
        }

        var exercises = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (_searchQuery.isNotEmpty) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            final muscle = (data['primaryMuscle'] ?? data['muscleGroup'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || muscle.contains(_searchQuery);
          }
          return true;
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final data = exercises[index].data() as Map<String, dynamic>;
            final id = exercises[index].id;
            final isSelected = _selectedExercises.any((e) => e['exerciseId'] == id);
            return _buildExerciseCard(id, data, isSelected);
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(
    String id,
    Map<String, dynamic> data,
    bool isSelected,
  ) {
    final t = widget.themeMode;
    final name = data['name'] ?? 'Sin nombre';
    final muscle = data['primaryMuscle'] ?? data['muscleGroup'] ?? 'General';
    final difficulty = data['difficulty'] ?? 'Intermedio';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedExercises.removeWhere((e) => e['exerciseId'] == id);
          } else {
            _selectedExercises.add({
              'exerciseId': id,
              'exerciseName': name,
              'muscleGroup': muscle,
              'difficulty': difficulty,
              'sets': 3,
              'reps': '10-12',
              'restSeconds': 90,
              'order': _selectedExercises.length + 1,
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? t.accent.withValues(alpha: 0.1)
              : t.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? t.accent.withValues(alpha: 0.5)
                : t.borderAlpha.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? t.primaryText : t.secondaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected ? t.accent : t.subtleText,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              muscle,
              style: TextStyle(
                color: isSelected ? t.accent.withValues(alpha: 0.7) : t.tertiaryText,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              difficulty,
              style: TextStyle(
                color: _getDifficultyColor(difficulty),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSummary() {
    final t = widget.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Icon(Icons.architecture_rounded, color: t.accent),
              const SizedBox(width: 12),
              Text(
                'MI RUTINA',
                style: QuantumTypography.h3.copyWith(fontSize: 18, letterSpacing: 1.5, color: t.primaryText),
              ),
            ],
          ),
        ),
        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKioskField('Nombre de la rutina', _nameCtrl, 'Ej: Mi Rutina Personal'),
                const SizedBox(height: 16),
                _buildKioskDropdown(),
                const SizedBox(height: 16),
                _buildKioskField('Duración (min)', _durationCtrl, '60', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildKioskField('Descripción', _descCtrl, 'Objetivo de la rutina...', maxLines: 2),
                const SizedBox(height: 20),
                Text(
                  'EJERCICIOS SELECCIONADOS (${_selectedExercises.length})',
                  style: QuantumTypography.caption.copyWith(letterSpacing: 1.2, color: t.secondaryText),
                ),
                const SizedBox(height: 12),
                if (_selectedExercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: t.borderAlpha.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: t.borderAlpha.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Selecciona ejercicios de la izquierda',
                        style: TextStyle(color: t.tertiaryText, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedExercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = _selectedExercises[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.borderAlpha.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: t.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ex['exerciseName'],
                                style: TextStyle(
                                  color: t.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: t.errorColor, size: 16),
                              onPressed: () {
                                setState(() => _selectedExercises.removeAt(i));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        // Save button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.borderAlpha.withValues(alpha: 0.05))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveRoutine,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.buttonTextColor),
                    )
                  : Icon(Icons.qr_code_rounded, color: t.buttonTextColor),
              label: Text(
                _isSaving ? 'GUARDANDO...' : 'GENERAR QR',
                style: TextStyle(
                  color: t.buttonTextColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKioskField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final t = widget.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: t.tertiaryText, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: t.primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.subtleText, fontSize: 13),
            filled: true,
            fillColor: t.borderAlpha.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKioskDropdown() {
    final t = widget.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dificultad',
          style: TextStyle(color: t.tertiaryText, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: t.borderAlpha.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDifficulty,
            dropdownColor: t == KioskThemeMode.highContrast
                ? const Color(0xFFF5F5F5)
                : const Color(0xFF151725),
            style: TextStyle(color: t.primaryText),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _difficulties
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDifficulty = v ?? 'Intermedio'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveRoutine() async {
    final t = widget.themeMode;
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackBar('El nombre es requerido', t.errorColor);
      return;
    }
    if (_selectedExercises.isEmpty) {
      _showSnackBar('Selecciona al menos un ejercicio', t.errorColor);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final routineData = {
        'gymId': widget.gymId,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'difficulty': _selectedDifficulty,
        'estimatedDuration': int.tryParse(_durationCtrl.text) ?? 60,
        'exercises': _selectedExercises,
        'isActive': true,
        'isKioskCreated': true,
        'createdAt': now.toIso8601String(),
        'createdBy': 'kiosk_user',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('routines')
          .add(routineData);

      setState(() => _isSaving = false);

      if (mounted) {
        widget.onRoutineCreated(docRef.id, routineData);
        _showSnackBar('Rutina creada exitosamente', t.successColor);
        _nameCtrl.clear();
        _descCtrl.clear();
        _durationCtrl.text = '60';
        setState(() => _selectedExercises = []);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('Error: $e', t.errorColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    final t = widget.themeMode;
    switch (difficulty) {
      case 'Principiante':
        return t.successColor;
      case 'Intermedio':
        return t == KioskThemeMode.highContrast
            ? const Color(0xFFE65100)
            : QuantumColors.accent;
      case 'Avanzado':
        return t.errorColor;
      default:
        return t.accent;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class GymButtonKiosk extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;

  const GymButtonKiosk({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: QuantumColors.quantumBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon ?? Icons.check, color: Colors.black, size: 20),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
