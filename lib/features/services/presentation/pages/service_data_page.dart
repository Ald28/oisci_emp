import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Título Información del Extintor
                    Row(
                      children: [
                        const Text(
                          'Información del Extintor',
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
                    // Campos de datos del extintor
                    if (extinguisher.codigoNFC != null)
                      _buildField('Código NFC', extinguisher.codigoNFC!),
                    if (extinguisher.codigoNFC != null) const SizedBox(height: 12),
                    if (extinguisher.numeroSerie != null)
                      _buildField('Nro. Serie', extinguisher.numeroSerie!),
                    if (extinguisher.numeroSerie != null) const SizedBox(height: 12),
                    if (extinguisher.ubicacion != null)
                      _buildField('Ubicación', extinguisher.ubicacion!),
                    if (extinguisher.ubicacion != null) const SizedBox(height: 12),
                    if (extinguisher.numeroCilindro != null)
                      _buildField('Nro. Cilindro', extinguisher.numeroCilindro!),
                    if (extinguisher.numeroCilindro != null) const SizedBox(height: 12),
                    if (extinguisher.tipo != null)
                      _buildField('Tipo', extinguisher.tipo!),
                    if (extinguisher.tipo != null) const SizedBox(height: 12),
                    if (extinguisher.agente != null)
                      _buildField('Agente', extinguisher.agente!),
                    if (extinguisher.agente != null) const SizedBox(height: 12),
                    if (extinguisher.capacidad != null)
                      _buildField('Capacidad', extinguisher.capacidad!),
                    if (extinguisher.capacidad != null) const SizedBox(height: 12),
                    if (extinguisher.estado != null)
                      _buildField('Estado', extinguisher.estado!),
                    if (extinguisher.estado != null) const SizedBox(height: 12),
                    if (extinguisher.historico != null)
                      _buildField('Histórico', extinguisher.historico!),
                    if (extinguisher.historico != null) const SizedBox(height: 12),
                    if (extinguisher.fechaBaja != null)
                      _buildField('Fecha de Baja', extinguisher.fechaBaja!),
                    if (extinguisher.fechaBaja != null) const SizedBox(height: 12),
                    if (extinguisher.createdAt != null)
                      _buildField(
                        'Fecha de Creación',
                        DateFormat('dd/MM/yyyy').format(extinguisher.createdAt!),
                      ),
                    const SizedBox(height: 32),
                    // Botón Continuar
                    PrimaryButton(
                      text: 'Continuar',
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 56,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
