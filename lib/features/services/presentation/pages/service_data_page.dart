import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/extinguisher.dart';
import 'package:intl/intl.dart';

/// Pantalla: Mostrar datos del extintor + Continuar
class ServiceDataPage extends StatelessWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;

  const ServiceDataPage({
    super.key,
    required this.extinguisher,
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
                    if (extinguisher.codigoNFC != null)
                      _buildDataRow('1', 'Código NFC', extinguisher.codigoNFC!),
                    if (extinguisher.codigoNFC != null) _buildDivider(),
                    if (extinguisher.ubicacion != null)
                      _buildDataRow('2', 'Ubicación', extinguisher.ubicacion!),
                    if (extinguisher.ubicacion != null) _buildDivider(),
                    if (extinguisher.numeroSerie != null)
                      _buildDataRow('3', 'Nro. Serie', extinguisher.numeroSerie!),
                    if (extinguisher.numeroSerie != null) _buildDivider(),
                    if (extinguisher.numeroCilindro != null)
                      _buildDataRow('4', 'Nro. Cilindro', extinguisher.numeroCilindro!),
                    if (extinguisher.numeroCilindro != null) _buildDivider(),
                    if (extinguisher.tipo != null)
                      _buildDataRow('5', 'Tipo', extinguisher.tipo!),
                    if (extinguisher.tipo != null) _buildDivider(),
                    if (extinguisher.agente != null)
                      _buildDataRow('6', 'Agente', extinguisher.agente!),
                    if (extinguisher.agente != null) _buildDivider(),
                    if (extinguisher.capacidad != null)
                      _buildDataRow('7', 'Capacidad', extinguisher.capacidad!),
                    if (extinguisher.capacidad != null) _buildDivider(),
                    if (extinguisher.estado != null)
                      _buildDataRow('8', 'Estado', extinguisher.estado!),
                    if (extinguisher.estado != null) _buildDivider(),
                    if (extinguisher.historico != null)
                      _buildDataRow('9', 'Histórico', extinguisher.historico!),
                    if (extinguisher.historico != null) _buildDivider(),
                    if (extinguisher.fechaBaja != null)
                      _buildDataRow('10', 'Fecha de Baja', extinguisher.fechaBaja!),
                    if (extinguisher.fechaBaja != null) _buildDivider(),
                    if (extinguisher.createdAt != null)
                      _buildDataRow(
                        '11',
                        'Fecha de Creación',
                        DateFormat('dd/MM/yyyy').format(extinguisher.createdAt!),
                      ),
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

  Widget _buildDataRow(String number, String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
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
