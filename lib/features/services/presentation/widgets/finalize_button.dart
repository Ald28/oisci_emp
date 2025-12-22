import 'package:flutter/material.dart';

/// Widget: Botón finalización de servicio
class FinalizeButton extends StatelessWidget {
  final VoidCallback onFinalize;

  const FinalizeButton({
    super.key,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showConfirmDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE84343),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: const Text('Finalizar Servicio'),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Está seguro de que desea finalizar el servicio?'),
        content: const Text(
          'Tenga en cuenta que, una vez finalizado, se enviará automáticamente el reporte al administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onFinalize();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

