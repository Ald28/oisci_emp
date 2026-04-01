import 'package:flutter/material.dart';

/// Widget reutilizable: Input con label flotante en el borde superior izquierdo
class FloatingLabelTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final FocusNode? focusNode;

  const FloatingLabelTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.prefixIcon,
    this.focusNode,
  });

  @override
  State<FloatingLabelTextField> createState() => _FloatingLabelTextFieldState();
}

class _FloatingLabelTextFieldState extends State<FloatingLabelTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isBlocked = widget.readOnly;
    final showLabelOnTop = isBlocked ? hasText : (_isFocused || hasText);

    final fillColor = isBlocked ? Colors.grey[200]! : const Color(0xFFF5F5F5);
    final borderColor = isBlocked
        ? Colors.grey[400]!
        : (_isFocused ? const Color(0xFFE84343) : Colors.grey[300]!);
    final borderWidth = isBlocked ? 1.0 : (_isFocused ? 2.0 : 1.0);
    final labelColor = isBlocked
        ? Colors.grey[600]!
        : (_isFocused ? const Color(0xFFE84343) : Colors.grey[700]!);

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          showCursor: !widget.readOnly,
          enableInteractiveSelection: !widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: showLabelOnTop ? null : (widget.hintText ?? widget.label),
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isBlocked ? Colors.grey[400]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isBlocked ? Colors.grey[400]! : const Color(0xFFE84343),
                width: isBlocked ? 1 : 2,
              ),
            ),
            prefixIcon: widget.prefixIcon,
            contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            counterText: '',
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isBlocked ? Colors.grey[700] : Colors.black87,
          ),
        ),
        if (showLabelOnTop)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );

    if (isBlocked) {
      content = IgnorePointer(child: content);
    } else {
      content = Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: content,
      );
    }

    return content;
  }
}
