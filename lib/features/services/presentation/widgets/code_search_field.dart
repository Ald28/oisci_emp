import 'package:flutter/material.dart';
import '../../../../core/widgets/primary_button.dart';

/// Widget: Input + Botón Buscar
class CodeSearchField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const CodeSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  State<CodeSearchField> createState() => _CodeSearchFieldState();
}

class _CodeSearchFieldState extends State<CodeSearchField> {
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
    final showLabelOnTop = _isFocused || hasText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Si no puedes escanear la tarjeta ingresa el código o número de serie aquí',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Input field con label en el borde superior izquierdo
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: showLabelOnTop ? null : 'Código o Nº de Serie',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isFocused ? const Color(0xFFE84343) : Colors.grey[300]!,
                      width: _isFocused ? 2 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE84343),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              // Label en el borde superior izquierdo (cuando está enfocado o tiene texto)
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
                      'Código o Nº de Serie',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFocused ? const Color(0xFFE84343) : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Botón Buscar (debajo del input)
        PrimaryButton(
          text: 'Buscar',
          onPressed: widget.onSearch,
        ),
      ],
    );
  }
}
