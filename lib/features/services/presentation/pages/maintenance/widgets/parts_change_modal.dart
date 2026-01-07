import 'package:flutter/material.dart';
import '../../../../../../core/widgets/floating_label_text_field.dart';
import '../../../../../../core/widgets/primary_button.dart';

/// Modal: Detalles de cambio de partes
class PartsChangeModal extends StatefulWidget {
  final String? initialDetails;

  const PartsChangeModal({
    super.key,
    this.initialDetails,
  });

  @override
  State<PartsChangeModal> createState() => _PartsChangeModalState();
}

class _PartsChangeModalState extends State<PartsChangeModal> {
  final _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDetails != null) {
      _detailsController.text = widget.initialDetails!;
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'CAMBIO PARTES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Campo de texto
            FloatingLabelTextField(
              controller: _detailsController,
              label: 'Partes cambiadas',
              hintText: 'Ej: CARTUCHO',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Botón OK
            PrimaryButton(
              text: 'OK',
              onPressed: _detailsController.text.trim().isNotEmpty
                  ? () {
                      Navigator.of(context).pop(_detailsController.text.trim());
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

