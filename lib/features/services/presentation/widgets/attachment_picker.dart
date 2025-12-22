import 'package:flutter/material.dart';

/// Widget: Selector/cámara para adjuntos
class AttachmentPicker extends StatelessWidget {
  final Function(String filePath) onFileSelected;

  const AttachmentPicker({
    super.key,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implementar selección de archivo/cámara
      },
      icon: const Icon(Icons.camera_alt),
      label: const Text('Tomar Foto'),
    );
  }
}

