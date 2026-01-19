import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../services/domain/entities/extinguisher_entity.dart';

/// Página: Detalles del Equipo
class EquipmentDetailPage extends StatelessWidget {
  final Extinguisher extinguisher;

  const EquipmentDetailPage({super.key, required this.extinguisher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Equipo ${extinguisher.serialNumber ?? 'N/A'}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotos del equipo (si existen)
            if (extinguisher.photo != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fotos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Placeholder para fotos
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Información del equipo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Equipo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      '1',
                      'Código',
                      extinguisher.serialNumber ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '2',
                      'Ubicación',
                      extinguisher.location ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '3',
                      'Nro. Serie',
                      extinguisher.serialNumber ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '4',
                      'Nro. Cilindro',
                      extinguisher.cylinderNumber ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '5',
                      'Tipo de agente',
                      _getExtinguisherTypeLabel(),
                    ),
                    _buildDetailRow(
                      '6',
                      'Capacidad',
                      extinguisher.capacity ?? 'N/A',
                    ),
                    _buildDetailRow(
                      '7',
                      'Estado',
                      extinguisher.status ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String number, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getExtinguisherTypeLabel() {
    if (extinguisher.type != null && extinguisher.agent != null) {
      return '${extinguisher.type} ${extinguisher.agent}';
    } else if (extinguisher.type != null) {
      return extinguisher.type!;
    } else if (extinguisher.agent != null) {
      return extinguisher.agent!;
    }
    return 'Desconocido';
  }
}
