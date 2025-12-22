import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/service_type.dart';

/// Pantalla: Mostrar datos del extintor + Continuar
class ServiceDataPage extends StatelessWidget {
  final String extinguisherCode;
  final ServiceType serviceType;

  const ServiceDataPage({
    super.key,
    required this.extinguisherCode,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Servicios',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Título DATOS
            Row(
              children: [
                const Text(
                  'DATOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Lista de datos del extintor
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDataRow('1', 'Código', 'PG05'),
                    _buildDivider(),
                    _buildDataRow('2', 'Ubicación', 'Escalera turbina'),
                    _buildDivider(),
                    _buildDataRow('3', 'Nro. Serie', 'U1572454'),
                    _buildDivider(),
                    _buildDataRow('4', 'Nro. Cilindro', '25478126'),
                    _buildDivider(),
                    _buildDataRow('5', 'Tipo de agente', 'PQS ABC'),
                    _buildDivider(),
                    _buildDataRow('6', 'Capacidad', '05 LBS'),
                    _buildDivider(),
                    _buildDataRow('7', 'Presión', 'INTERNA'),
                    _buildDivider(),
                    _buildDataRow('8', 'Marca', 'AMEREX'),
                    _buildDivider(),
                    _buildDataRow('9', 'Modelo', '4021'),
                    _buildDivider(),
                    _buildDataRow('10', 'Rating', '3A:40B:C'),
                    _buildDivider(),
                    _buildDataRow('11', 'Año de fabricación', '2008'),
                    _buildDivider(),
                    _buildDataRow('12', 'Fecha de Prueba Hidrostática', 'DIC 2023'),
                    _buildDivider(),
                    _buildDataRow('13', 'Fecha de mantenimiento', 'DIC 2023'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Botón Continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navegar al siguiente paso según serviceType
                  // Si es maintenance -> maintenance_checklist_page
                  // Si es inspection -> inspection_checklist_page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Continuar con ${serviceType == ServiceType.maintenance ? 'Mantenimiento' : 'Inspección'}',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84343),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String number, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[300],
    );
  }
}
