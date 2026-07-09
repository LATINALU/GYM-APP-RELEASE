import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NEON WIDGETS - Cyberpunk/Glassmorphism Design System for Client Screens
// Uses existing QuantumColors (quantumBlue as neon accent)
// ═══════════════════════════════════════════════════════════════════════════════

/// Base neon card with optional glow border
class NeonCard extends StatelessWidget {
  final Widget child;
  final bool hasGlow;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.hasGlow = false,
    this.glowColor,
    this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? QuantumColors.quantumBlue;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuantumColors.voidGray.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: hasGlow ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
          width: 1.5,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Neon stat card (calories, streak, volume)
class NeonStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final bool isActive;

  const NeonStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      hasGlow: isActive,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: QuantumColors.quantumBlue, size: 26),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Glowing bar for bar charts
class GlowingBar extends StatelessWidget {
  final double heightFactor;
  final Color? color;

  const GlowingBar({super.key, required this.heightFactor, this.color});

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? QuantumColors.quantumBlue;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        return Container(
          width: 12,
          height: availableHeight * heightFactor.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: barColor.withValues(alpha: 0.6),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 2,
                spreadRadius: -1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Neon circular timer with CustomPainter glow effect
class NeonCircularTimer extends StatelessWidget {
  final double progress;
  final double size;
  final Widget? center;

  const NeonCircularTimer({
    super.key,
    required this.progress,
    this.size = 220,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 14,
              valueColor: AlwaysStoppedAnimation<Color>(
                QuantumColors.voidGray.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Neon arc
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _NeonArcPainter(progress: progress),
            ),
          ),
          // Center content
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _NeonArcPainter extends CustomPainter {
  final double progress;
  _NeonArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glow layer
    final glowPaint = Paint()
      ..color = QuantumColors.quantumBlue.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Sharp layer
    final mainPaint = Paint()
      ..color = QuantumColors.quantumBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, mainPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Cyberpunk grid background painter
class GridBackgroundPainter extends CustomPainter {
  final double spacing;
  final double opacity;

  GridBackgroundPainter({this.spacing = 32, this.opacity = 0.03});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glowing muscle spot for heatmap
class GlowingMuscleSpot extends StatelessWidget {
  final double size;
  final bool isElongated;
  final double intensity;

  const GlowingMuscleSpot({
    super.key,
    required this.size,
    this.isElongated = false,
    this.intensity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: isElongated ? size * 2 : size,
      decoration: BoxDecoration(
        color: QuantumColors.quantumBlue.withValues(alpha: intensity),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.7),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Neon-style tag chip
class NeonTagChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const NeonTagChip({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? QuantumColors.quantumBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive
                ? QuantumColors.quantumBlue
                : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: QuantumColors.quantumBlue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.5),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Neon icon toggle button (for heatmap controls etc.)
class NeonIconToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const NeonIconToggle({
    super.key,
    required this.icon,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isActive ? QuantumColors.quantumBlue.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: QuantumColors.quantumBlue.withValues(alpha: 0.25),
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? QuantumColors.quantumBlue : Colors.white.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }
}

/// Neon action card (grid items like AI Coach, Scan, etc.)
class NeonActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const NeonActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: QuantumColors.voidGray.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Stack(
            children: [
              // Subtle grid pattern overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: GridBackgroundPainter(spacing: 20, opacity: 0.02),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: QuantumColors.quantumBlue, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neon-glow avatar with optional badge
class NeonGlowAvatar extends StatelessWidget {
  final String initial;
  final double radius;
  final String? imageUrl;

  const NeonGlowAvatar({
    super.key,
    required this.initial,
    this.radius = 60,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QuantumColors.quantumBlue, width: 3),
        boxShadow: [
          BoxShadow(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.45),
            blurRadius: 25,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: QuantumColors.quantumBlue.withValues(alpha: 0.7),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: Container(
            color: QuantumColors.voidGray,
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: QuantumColors.quantumBlue,
                fontSize: radius * 0.65,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
