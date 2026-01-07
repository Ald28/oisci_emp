import 'package:flutter/material.dart';
import '../../../../../../core/widgets/floating_label_text_field.dart';
import '../../../../../../core/widgets/primary_button.dart';

/// Modal: Motivo de baja de extintor
class DecommissionModal extends StatefulWidget {
  final String? initialReason;

  const DecommissionModal({super.key, this.initialReason});

  @override
  State<DecommissionModal> createState() => _DecommissionModalState();
}

class _DecommissionModalState extends State<DecommissionModal> {
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'BAJA DE EXTINTOR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Campo de texto
            FloatingLabelTextField(
              controller: _reasonController,
              label: 'Motivo de baja',
              hintText: 'Ej: ABOLLADURA EN CILINDRO',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Botón OK
            PrimaryButton(
              text: 'OK',
              onPressed: _reasonController.text.trim().isNotEmpty
                  ? () {
                      Navigator.of(context).pop(_reasonController.text.trim());
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
