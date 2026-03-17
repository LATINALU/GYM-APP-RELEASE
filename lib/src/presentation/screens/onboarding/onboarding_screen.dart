import 'package:flutter/material.dart';

/// Onboarding Screen - First-time user experience
/// Collects fitness goal, experience level, and schedule preference
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  String? _goal;
  String? _experience;
  int _daysPerWeek = 4;

  final _goals = [
    ('💪', 'Ganar Músculo', 'Aumentar masa muscular y fuerza'),
    ('🔥', 'Perder Grasa', 'Reducir porcentaje de grasa corporal'),
    ('⚡', 'Rendimiento', 'Mejorar resistencia y capacidad atlética'),
    ('🧘', 'Bienestar', 'Mejorar salud general y flexibilidad'),
    ('🏋️', 'Fuerza Pura', 'Maximizar levantamientos principales'),
  ];

  final _levels = [
    ('🌱', 'Principiante', '< 6 meses entrenando'),
    ('🌿', 'Intermedio', '6 meses - 2 años'),
    ('🌳', 'Avanzado', '2 - 5 años'),
    ('🏆', 'Elite', '5+ años de entrenamiento'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(child: Column(children: [
        // Progress bar
        Padding(padding: const EdgeInsets.all(20), child: Row(children: List.generate(3, (i) => Expanded(
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 4,
            decoration: BoxDecoration(color: i <= _page ? const Color(0xFF6C63FF) : Colors.white10, borderRadius: BorderRadius.circular(2))))))),
        Expanded(child: PageView(controller: _controller, physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (p) => setState(() => _page = p), children: [
            _buildGoalPage(),
            _buildExperiencePage(),
            _buildSchedulePage(),
          ])),
      ])),
    );
  }

  Widget _buildGoalPage() => Padding(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Cuál es tu\nobjetivo principal?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
      const SizedBox(height: 8),
      const Text('Personalizaremos tu experiencia', style: TextStyle(color: Colors.white38, fontSize: 14)),
      const SizedBox(height: 32),
      ...(_goals.map((g) => _optionCard(g.$1, g.$2, g.$3, _goal == g.$2, () {
        setState(() => _goal = g.$2);
        Future.delayed(const Duration(milliseconds: 300), () => _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut));
      }))),
    ],
  ));

  Widget _buildExperiencePage() => Padding(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Cuál es tu nivel\nde experiencia?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
      const SizedBox(height: 8),
      const Text('Adaptaremos la dificultad', style: TextStyle(color: Colors.white38, fontSize: 14)),
      const SizedBox(height: 32),
      ...(_levels.map((l) => _optionCard(l.$1, l.$2, l.$3, _experience == l.$2, () {
        setState(() => _experience = l.$2);
        Future.delayed(const Duration(milliseconds: 300), () => _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut));
      }))),
    ],
  ));

  Widget _buildSchedulePage() => Padding(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Cuántos días\npor semana?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
      const SizedBox(height: 8),
      const Text('Te sugeriremos la mejor rutina', style: TextStyle(color: Colors.white38, fontSize: 14)),
      const SizedBox(height: 48),
      Center(child: Text('$_daysPerWeek', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 72, fontWeight: FontWeight.w900))),
      const Center(child: Text('días por semana', style: TextStyle(color: Colors.white38, fontSize: 16))),
      const SizedBox(height: 32),
      Slider(value: _daysPerWeek.toDouble(), min: 2, max: 7, divisions: 5,
        activeColor: const Color(0xFF6C63FF), inactiveColor: Colors.white10,
        onChanged: (v) => setState(() => _daysPerWeek = v.toInt())),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].asMap().entries.map((e) {
        final active = e.key < _daysPerWeek;
        return Container(width: 42, height: 42, margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: active ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? const Color(0xFF6C63FF).withValues(alpha: 0.4) : Colors.transparent)),
          child: Center(child: Text(e.value, style: TextStyle(color: active ? const Color(0xFF6C63FF) : Colors.white24, fontWeight: FontWeight.w600))));
      }).toList()),
      const Spacer(),
      SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
        onPressed: widget.onComplete,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('Comenzar 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
    ],
  ));

  Widget _optionCard(String emoji, String title, String subtitle, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? const Color(0xFF6C63FF).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06))),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        if (selected) const Icon(Icons.check_circle, color: Color(0xFF6C63FF)),
      ]),
    ));
  }
}
