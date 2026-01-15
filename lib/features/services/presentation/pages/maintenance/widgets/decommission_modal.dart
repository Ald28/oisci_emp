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
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
      _isButtonEnabled = widget.initialReason!.trim().isNotEmpty;
    }
    // Agregar listener para actualizar el estado del botón cuando cambie el texto
    _reasonController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isEnabled = _reasonController.text.trim().isNotEmpty;
    if (_isButtonEnabled != isEnabled) {
      setState(() {
        _isButtonEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.removeListener(_updateButtonState);
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
              onPressed: _isButtonEnabled
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
