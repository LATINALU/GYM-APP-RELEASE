import 'package:flutter/material.dart';
import '../src/presentation/theme/quantum_colors.dart';

/// Widgets compartidos por las pantallas de la demo.

PreferredSizeWidget demoAppBar(
  BuildContext context, {
  required String title,
  required String userName,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleSpacing: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
        Text(userName,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    ),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: QuantumColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          widthFactor: 1,
          child: Text('DEMO',
              style: TextStyle(
                  color: QuantumColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
      ),
      IconButton(
        tooltip: 'Cerrar sesión',
        icon: const Icon(Icons.logout_rounded, color: Colors.white54),
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    ],
  );
}

class DemoCard extends StatelessWidget {
  final Widget child;

  const DemoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumColors.voidGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class DemoSectionTitle extends StatelessWidget {
  final String text;

  const DemoSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class DemoKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DemoKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuantumColors.voidGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
