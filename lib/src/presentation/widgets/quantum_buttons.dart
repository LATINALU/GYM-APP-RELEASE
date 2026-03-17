import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

/// Botón de acción flotante holográfico con animación
class FloatingActionHologram extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final Color? color;
  final double size;

  const FloatingActionHologram({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.color,
    this.size = 64,
  });

  @override
  State<FloatingActionHologram> createState() => _FloatingActionHologramState();
}

class _FloatingActionHologramState extends State<FloatingActionHologram>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? QuantumColors.quantumBlue;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: QuantumColors.voidGray.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: buttonColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.label!,
                      style: QuantumTypography.data.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: buttonColor,
                      ),
                    ),
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      buttonColor.withOpacity(_glowAnimation.value + 0.3),
                      buttonColor.withOpacity(_glowAnimation.value),
                    ],
                    center: const Alignment(0.1, -0.1),
                    focal: const Alignment(0.1, -0.1),
                    focalRadius: 0.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(_glowAnimation.value),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: buttonColor.withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 50,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    splashColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: widget.size * 0.4,
                        color: QuantumColors.nebulaWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Botón cuántico estándar
class QuantumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;

  const QuantumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
  });

  @override
  State<QuantumButton> createState() => _QuantumButtonState();
}

class _QuantumButtonState extends State<QuantumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? QuantumColors.quantumBlue;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : _onTapDown,
            onTapUp: widget.isLoading ? null : _onTapUp,
            onTapCancel: widget.isLoading ? null : _onTapCancel,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                gradient: widget.isOutlined
                    ? null
                    : LinearGradient(
                        colors: [
                          buttonColor,
                          buttonColor.withValues(alpha: 0.8),
                        ],
                      ),
                color: widget.isOutlined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isOutlined
                      ? buttonColor
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: widget.isOutlined || _isPressed
                    ? null
                    : [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isOutlined
                              ? buttonColor
                              : QuantumColors.nebulaWhite,
                        ),
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 20,
                        color: widget.isOutlined
                            ? buttonColor
                            : QuantumColors.nebulaWhite,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: QuantumTypography.button.copyWith(
                        color: widget.isOutlined
                            ? buttonColor
                            : QuantumColors.nebulaWhite,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botón de icono cuántico
class QuantumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final bool showBackground;
  final String? tooltip;

  const QuantumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 44,
    this.showBackground = true,
    this.tooltip,
  });

  @override
  State<QuantumIconButton> createState() => _QuantumIconButtonState();
}

class _QuantumIconButtonState extends State<QuantumIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? QuantumColors.quantumBlue;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.showBackground
                ? (_isHovered
                    ? buttonColor.withValues(alpha: 0.15)
                    : QuantumColors.voidGray.withValues(alpha: 0.4))
                : Colors.transparent,
            border: Border.all(
              color: _isHovered
                  ? buttonColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: _isHovered ? buttonColor : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
