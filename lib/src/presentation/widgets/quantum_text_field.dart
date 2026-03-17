import 'package:flutter/material.dart';
import '../theme/quantum_colors.dart';

/// Campo de texto cuántico con efecto de brillo
class QuantumTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;

  const QuantumTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<QuantumTextField> createState() => _QuantumTextFieldState();
}

class _QuantumTextFieldState extends State<QuantumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: QuantumTypography.label.copyWith(
              color: _isFocused
                  ? QuantumColors.quantumBlue
                  : QuantumColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: hasError
                          ? QuantumColors.error.withValues(alpha: 0.2)
                          : QuantumColors.quantumBlue.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            style: QuantumTypography.body.copyWith(
              color: QuantumColors.nebulaWhite,
            ),
            cursorColor: QuantumColors.quantumBlue,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: QuantumTypography.body.copyWith(
                color: QuantumColors.textTertiary,
              ),
              filled: true,
              fillColor: QuantumColors.voidGray.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? QuantumColors.quantumBlue
                          : QuantumColors.textSecondary,
                      size: 22,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: QuantumColors.textSecondary,
                        size: 22,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: QuantumColors.subtleBorder,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: QuantumColors.subtleBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError
                      ? QuantumColors.error
                      : QuantumColors.quantumBlue,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: QuantumColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: QuantumColors.error,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: QuantumColors.subtleBorder.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: QuantumColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                widget.errorText!,
                style: QuantumTypography.caption.copyWith(
                  color: QuantumColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Campo de búsqueda cuántico
class QuantumSearchField extends StatefulWidget {
  final String? hint;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const QuantumSearchField({
    super.key,
    this.hint,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<QuantumSearchField> createState() => _QuantumSearchFieldState();
}

class _QuantumSearchFieldState extends State<QuantumSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateHasText);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateHasText() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QuantumColors.voidGray.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: QuantumTypography.body.copyWith(
          color: QuantumColors.nebulaWhite,
        ),
        cursorColor: QuantumColors.quantumBlue,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Buscar...',
          hintStyle: QuantumTypography.body.copyWith(
            color: QuantumColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: QuantumColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _hasText
              ? GestureDetector(
                  onTap: _clear,
                  child: Icon(
                    Icons.close,
                    color: QuantumColors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
