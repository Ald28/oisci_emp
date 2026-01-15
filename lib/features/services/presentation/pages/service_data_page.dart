import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../domain/usecases/add_extinguisher_to_service_usecase.dart';
import '../../data/repositories/service_repository_impl.dart';
import 'maintenance/maintenance_checklist_page.dart';
import 'package:intl/intl.dart';

/// Pantalla: Mostrar datos del extintor + Continuar
class ServiceDataPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;
  final int servicioId;

  const ServiceDataPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
    required this.servicioId,
  });

  @override
  State<ServiceDataPage> createState() => _ServiceDataPageState();
}

class _ServiceDataPageState extends State<ServiceDataPage> {
  bool _isLoading = false;

  late final AddExtinguisherToServiceUseCase _addExtinguisherUseCase =
      AddExtinguisherToServiceUseCase(ServiceRepositoryImpl());

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear ServicioExtintor (Etapa 2)
      final serviceExtinguisher = await _addExtinguisherUseCase.call(
        servicioId: widget.servicioId,
        extintorId: widget.extinguisher.id,
        estadoInicial: widget.extinguisher.status, // OPERATIVO o INOPERATIVO
        observaciones:
            null, // Se agregará después en la página de observaciones
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navegar a MaintenanceChecklistPage
      if (widget.serviceType == ServiceType.maintenance) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceChecklistPage(
              extinguisher: widget.extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
              servicioExtintorId: serviceExtinguisher.id,
            ),
          ),
        );
      } else {
        // TODO: Navegar a inspection_checklist_page cuando esté implementado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspección - Próximamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al agregar extintor al servicio: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          final maxWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;
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
                        Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Campos de datos del extintor
                    if (widget.extinguisher.serialNumber != null)
                      _buildField(
                        'Nro. Serie',
                        widget.extinguisher.serialNumber!,
                      ),
                    if (widget.extinguisher.serialNumber != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.location != null)
                      _buildField('Ubicación', widget.extinguisher.location!),
                    if (widget.extinguisher.location != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.cylinderNumber != null)
                      _buildField(
                        'Nro. Cilindro',
                        widget.extinguisher.cylinderNumber!,
                      ),
                    if (widget.extinguisher.cylinderNumber != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.type != null)
                      _buildField('Tipo', widget.extinguisher.type!),
                    if (widget.extinguisher.type != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.agent != null)
                      _buildField('Agente', widget.extinguisher.agent!),
                    if (widget.extinguisher.agent != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.capacity != null)
                      _buildField('Capacidad', widget.extinguisher.capacity!),
                    if (widget.extinguisher.capacity != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.status != null)
                      _buildField('Estado', widget.extinguisher.status!),
                    if (widget.extinguisher.status != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.sedeName != null)
                      _buildField('Sede', widget.extinguisher.sedeName!),
                    if (widget.extinguisher.sedeName != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.createdAt != null)
                      _buildField(
                        'Fecha de Creación',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(widget.extinguisher.createdAt!),
                      ),
                    const SizedBox(height: 32),
                    // Botón Agregar extintor y continuar
                    PrimaryButton(
                      text: 'Agregar extintor y continuar',
                      onPressed: _isLoading ? null : _handleContinue,
                      isLoading: _isLoading,
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
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
