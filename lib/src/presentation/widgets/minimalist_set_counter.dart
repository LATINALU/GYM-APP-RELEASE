import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';
import 'quantum_buttons.dart';

/// Contador de sets/reps minimalista
class MinimalistSetCounter extends StatefulWidget {
  final int initialSets;
  final int initialReps;
  final Function(int sets, int reps) onChanged;
  final int minSets;
  final int maxSets;
  final int minReps;
  final int maxReps;

  const MinimalistSetCounter({
    super.key,
    required this.initialSets,
    required this.initialReps,
    required this.onChanged,
    this.minSets = 1,
    this.maxSets = 10,
    this.minReps = 1,
    this.maxReps = 50,
  });

  @override
  State<MinimalistSetCounter> createState() => _MinimalistSetCounterState();
}

class _MinimalistSetCounterState extends State<MinimalistSetCounter> {
  late int _sets;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _sets = widget.initialSets;
    _reps = widget.initialReps;
  }

  void _incrementSets() {
    if (_sets < widget.maxSets) {
      setState(() {
        _sets++;
        widget.onChanged(_sets, _reps);
      });
    }
  }

  void _decrementSets() {
    if (_sets > widget.minSets) {
      setState(() {
        _sets--;
        widget.onChanged(_sets, _reps);
      });
    }
  }

  void _incrementReps() {
    if (_reps < widget.maxReps) {
      setState(() {
        _reps++;
        widget.onChanged(_sets, _reps);
      });
    }
  }

  void _decrementReps() {
    if (_reps > widget.minReps) {
      setState(() {
        _reps--;
        widget.onChanged(_sets, _reps);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QuantumColors.voidGray.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SETS',
                style: QuantumTypography.data.copyWith(
                  letterSpacing: 2,
                ),
              ),
              Text(
                'REPS',
                style: QuantumTypography.data.copyWith(
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contadores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contador de Sets
              _CounterControl(
                value: _sets,
                onIncrement: _incrementSets,
                onDecrement: _decrementSets,
                canIncrement: _sets < widget.maxSets,
                canDecrement: _sets > widget.minSets,
              ),

              // Divisor
              Container(
                width: 1,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      QuantumColors.quantumBlue.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Contador de Reps
              _CounterControl(
                value: _reps,
                onIncrement: _incrementReps,
                onDecrement: _decrementReps,
                canIncrement: _reps < widget.maxReps,
                canDecrement: _reps > widget.minReps,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterControl extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;
  final bool canDecrement;

  const _CounterControl({
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.canIncrement,
    required this.canDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterButton(
          icon: Icons.remove,
          onPressed: onDecrement,
          isEnabled: canDecrement,
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 60,
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: QuantumTypography.displayMedium.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _CounterButton(
          icon: Icons.add,
          onPressed: onIncrement,
          isEnabled: canIncrement,
        ),
      ],
    );
  }
}

class _CounterButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isEnabled;

  const _CounterButton({
    required this.icon,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
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
    if (widget.isEnabled) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _controller.reverse();
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isEnabled
                    ? QuantumColors.quantumBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isEnabled
                      ? QuantumColors.quantumBlue
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isEnabled
                      ? QuantumColors.quantumBlue
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Selector numérico simple
class QuantumNumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Function(int) onChanged;
  final String? suffix;

  const QuantumNumberPicker({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: QuantumTypography.label,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            QuantumIconButton(
              icon: Icons.remove,
              onPressed: () {
                if (value > min) onChanged(value - 1);
              },
              size: 40,
              color: value > min ? QuantumColors.quantumBlue : QuantumColors.disabled,
            ),
            const SizedBox(width: 16),
            Text(
              suffix != null ? '$value$suffix' : value.toString(),
              style: QuantumTypography.h3,
            ),
            const SizedBox(width: 16),
            QuantumIconButton(
              icon: Icons.add,
              onPressed: () {
                if (value < max) onChanged(value + 1);
              },
              size: 40,
              color: value < max ? QuantumColors.quantumBlue : QuantumColors.disabled,
            ),
          ],
        ),
      ],
    );
  }
}
