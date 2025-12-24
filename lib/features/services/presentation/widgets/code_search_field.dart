import 'package:flutter/material.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/floating_label_text_field.dart';

/// Widget: Input + Botón Buscar
class CodeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const CodeSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
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
        // Input field con label flotante reutilizable
        FloatingLabelTextField(
          controller: controller,
          label: 'Código o Nº de Serie',
          hintText: 'Código o Nº de Serie',
        ),
        const SizedBox(height: 16),
        // Botón Buscar (debajo del input)
        PrimaryButton(
          text: 'Buscar',
          onPressed: onSearch,
        ),
      ],
    );
  }
}
