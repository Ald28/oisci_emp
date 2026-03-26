import 'package:flutter/material.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/floating_label_text_field.dart';

/// Widget: Input + Botón Buscar + Botón Vincular
class CodeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onLinkExisting;
  final bool isLoadingExisting;

  const CodeSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onLinkExisting,
    this.isLoadingExisting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Si no puedes escanear la tarjeta ingresa el código del extintor aquí (el que está visible en el extintor)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingLabelTextField(
            controller: controller,
            label: 'Código extintor',
            hintText: 'Ingrese el código aquí',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Botón Buscar
            Expanded(
              flex: 3,
              child: PrimaryButton(
                text: 'Buscar',
                onPressed: onSearch,
              ),
            ),
            if (onLinkExisting != null) ...[
              const SizedBox(width: 12),
              // Botón Vincular (icono al lado de buscar)
              Container(
                height: 54, // Mismo alto que el PrimaryButton usualmente
                width: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE84343), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE84343).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoadingExisting ? null : onLinkExisting,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: isLoadingExisting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
