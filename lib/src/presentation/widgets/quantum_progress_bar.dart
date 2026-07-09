import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

/// Barra de progreso cuántica con animaciones fluidas
class QuantumProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final String? label;
  final Color? progressColor;
  final bool showPercentage;
  final bool animated;

  const QuantumProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.label,
    this.progressColor,
    this.showPercentage = false,
    this.animated = true,
  });

  @override
  State<QuantumProgressBar> createState() => _QuantumProgressBarState();
}

class _QuantumProgressBarState extends State<QuantumProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animated) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.progressColor ?? QuantumColors.quantumBlue;
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: QuantumTypography.bodySmall.copyWith(
                      color: QuantumColors.textSecondary,
                    ),
                  ),
                if (widget.showPercentage)
                  Text(
                    '${(clampedProgress * 100).toInt()}%',
                    style: QuantumTypography.data.copyWith(
                      color: progressColor,
                    ),
                  ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final progressWidth = maxWidth * clampedProgress;
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Fondo
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: QuantumColors.voidGray,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                
                // Progreso
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: widget.height,
                  width: progressWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor,
                        progressColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                
                // Indicador de pulso en el extremo
                if (widget.animated && clampedProgress > 0.05)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: progressWidth - 5,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: widget.height + 2,
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: progressColor.withValues(alpha: _pulseAnimation.value),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Indicador de progreso circular cuántico
class QuantumCircularProgress extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final String? centerText;
  final String? label;
  final Color? progressColor;
  final bool animated;

  const QuantumCircularProgress({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.centerText,
    this.label,
    this.progressColor,
    this.animated = true,
  });

  @override
  State<QuantumCircularProgress> createState() => _QuantumCircularProgressState();
}

class _QuantumCircularProgressState extends State<QuantumCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.animated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(QuantumCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.progressColor ?? QuantumColors.quantumBlue;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CircularProgressPainter(
                  progress: widget.animated ? _progressAnimation.value : widget.progress,
                  strokeWidth: widget.strokeWidth,
                  progressColor: progressColor,
                  backgroundColor: QuantumColors.voidGray,
                ),
                child: Center(
                  child: widget.centerText != null
                      ? Text(
                          widget.centerText!,
                          style: QuantumTypography.h3.copyWith(
                            color: progressColor,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: QuantumTypography.bodySmall.copyWith(
              color: QuantumColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Fondo
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progreso
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          progressColor.withValues(alpha: 0.3),
          progressColor,
        ],
        startAngle: -1.5708, // -90 degrees
        endAngle: 4.7124, // 270 degrees
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * 3.14159 * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top (-90 degrees)
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Brillo en el extremo
    if (progress > 0.01) {
      final glowAngle = -1.5708 + sweepAngle;
      final glowX = center.dx + radius * cos(glowAngle);
      final glowY = center.dy + radius * sin(glowAngle);
      
      final glowPaint = Paint()
        ..color = progressColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(Offset(glowX, glowY), strokeWidth / 2, glowPaint);
    }
  }
  
  double cos(double radians) => 
      radians == 0 ? 1 : (radians * 180 / 3.14159).abs() < 0.001 ? 1 : _cos(radians);
  
  double sin(double radians) => 
      radians == 0 ? 0 : _sin(radians);
  
  double _cos(double x) {
    x = x % (2 * 3.14159);
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
  
  double _sin(double x) {
    x = x % (2 * 3.14159);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
