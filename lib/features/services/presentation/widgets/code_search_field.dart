import 'package:flutter/material.dart';

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
        // Label (aparece cuando está enfocado o tiene texto)
        if (_isFocused || hasText)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Código o Nº de Serie:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _isFocused ? const Color(0xFFE84343) : Colors.black87,
              ),
            ),
          ),
        // Input field
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: 'Código o Nº de Serie',
              hintStyle: TextStyle(
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isFocused ? const Color(0xFFE84343) : Colors.grey[400]!,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Botón Buscar (debajo del input)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84343),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Buscar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
