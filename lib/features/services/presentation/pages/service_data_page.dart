import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../domain/usecases/add_extinguisher_to_service_usecase.dart';
import '../../data/repositories/service_repository_impl.dart';
import 'maintenance/maintenance_checklist_page.dart';
import 'inspection/inspection_checklist_page.dart';
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

      // Navegar a la página correspondiente según el tipo de servicio
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionChecklistPage(
              extinguisher: widget.extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
              servicioExtintorId: serviceExtinguisher.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje amigable si el extintor ya está agregado
      final errorMessage = e.toString();
      final isDuplicateError = errorMessage.contains('ya está agregado');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDuplicateError
                ? 'Este extintor ya está agregado al servicio. Por favor, escanea o busca otro extintor.'
                : 'Error al agregar extintor al servicio: ${errorMessage.replaceAll('Exception: ', '')}',
          ),
          backgroundColor: isDuplicateError ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
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
                    if (widget.extinguisher.pressure != null)
                      _buildField('Presión', widget.extinguisher.pressure!),
                    if (widget.extinguisher.pressure != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.brand != null)
                      _buildField('Marca', widget.extinguisher.brand!),
                    if (widget.extinguisher.brand != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.model != null)
                      _buildField('Modelo', widget.extinguisher.model!),
                    if (widget.extinguisher.model != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.rating != null)
                      _buildField('Clasificación', widget.extinguisher.rating!),
                    if (widget.extinguisher.rating != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.yearManufacture != null)
                      _buildField('Año de Fabricación', widget.extinguisher.yearManufacture!),
                    if (widget.extinguisher.yearManufacture != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.dateHydrostatic != null)
                      _buildField(
                        'Fecha Hidrostática',
                        _formatDate(widget.extinguisher.dateHydrostatic!),
                      ),
                    if (widget.extinguisher.dateHydrostatic != null)
                      const SizedBox(height: 12),
                    if (widget.extinguisher.dateMaintenance != null)
                      _buildField(
                        'Fecha de Mantenimiento',
                        _formatDate(widget.extinguisher.dateMaintenance!),
                      ),
                    if (widget.extinguisher.dateMaintenance != null)
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

  /// Formatear fecha desde String (puede venir en formato ISO o dd/MM/yyyy)
  String _formatDate(String dateString) {
    try {
      // Intentar parsear como ISO (yyyy-MM-dd)
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // Si no se puede parsear, retornar el string original
      return dateString;
    }
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
