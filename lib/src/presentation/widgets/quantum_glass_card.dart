import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

/// Tarjeta con efecto glassmorphism cuántico
/// Efecto de cristal esmerilado con brillo sutil
class QuantumGlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final Color? accentColor;
  final double borderRadius;
  final bool showGlow;

  const QuantumGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.enableHoverEffect = true,
    this.accentColor,
    this.borderRadius = 16,
    this.showGlow = false,
  });

  @override
  State<QuantumGlassCard> createState() => _QuantumGlassCardState();
}

class _QuantumGlassCardState extends State<QuantumGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.03,
      end: 0.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? QuantumColors.quantumBlue;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                padding: widget.padding ?? const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: QuantumColors.voidGray.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _isHovered 
                        ? accentColor.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    width: _isHovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    // Sombra interna minimalista
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                    // Brillo sutil
                    BoxShadow(
                      color: accentColor.withOpacity(_glowAnimation.value),
                      blurRadius: 30,
                      spreadRadius: widget.showGlow ? 2 : 1,
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
