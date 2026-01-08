import 'package:flutter/material.dart';
import '../../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/secondary_button.dart';
import '../../../../../core/widgets/floating_label_text_field.dart';
import '../../../domain/entities/extinguisher_entity.dart';
import '../../../domain/entities/service_type.dart';
import '../services_scan_page.dart';

/// Pantalla: Observaciones de mantenimiento
class MaintenanceObservationsPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;
  final int servicioId;
  final int servicioExtintorId;
  final Map<String, bool> checklistItems;
  final String? rechargeAgent;
  final String? decommissionReason;
  final String? partsChangeDetails;

  const MaintenanceObservationsPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
    required this.servicioId,
    required this.servicioExtintorId,
    required this.checklistItems,
    this.rechargeAgent,
    this.decommissionReason,
    this.partsChangeDetails,
  });

  @override
  State<MaintenanceObservationsPage> createState() =>
      _MaintenanceObservationsPageState();
}

class _MaintenanceObservationsPageState
    extends State<MaintenanceObservationsPage> {
  final _observationsController = TextEditingController();

  void _handleReturnToScanner() {
    // Navegar al scanner NFC
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ServicesScanPage(
          serviceType: widget.serviceType,
          servicioId: widget.servicioId,
        ),
      ),
      (route) => false, // Eliminar todas las rutas anteriores
    );
  }

  void _handleListAllExtinguishers() {
    // TODO: Implementar navegación a lista de extintores
    // Por ahora mostrar un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listar todos los extintores - Próximamente'),
      ),
    );
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title:
            'Servicios/${widget.serviceType == ServiceType.maintenance ? 'Mantenimiento' : 'Inspección'}',
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
            // Título
            const Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Campo de observaciones
            FloatingLabelTextField(
              controller: _observationsController,
              label: 'Observaciones',
              hintText: 'Ingrese sus observaciones aquí...',
              maxLines: 10,
            ),
            const SizedBox(height: 32),
            // Botón: Volver al scanner NFC
            SecondaryButton(
              text: 'Volver al scanner NFC',
              onPressed: _handleReturnToScanner,
            ),
            const SizedBox(height: 16),
            // Botón: Listar todos los extintores
            PrimaryButton(
              text: 'Listar todos los extintores',
              onPressed: _handleListAllExtinguishers,
            ),
          ],
        ),
      ),
    );
  }
}
