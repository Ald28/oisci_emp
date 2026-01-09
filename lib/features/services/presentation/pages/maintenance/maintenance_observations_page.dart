import 'package:flutter/material.dart';
import '../../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/widgets/secondary_button.dart';
import '../../../../../core/widgets/floating_label_text_field.dart';
import '../../../domain/entities/extinguisher_entity.dart';
import '../../../domain/entities/service_type.dart';
import '../../../domain/usecases/update_service_extinguisher_observations_usecase.dart';
import '../../../data/repositories/service_repository_impl.dart';
import '../services_scan_page.dart';
import '../services_menu_page.dart';
import '../service_extinguisher_list_page.dart';

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
  bool _isSaving = false;

  late final UpdateServiceExtinguisherObservationsUseCase
  _updateObservationsUseCase = UpdateServiceExtinguisherObservationsUseCase(
    ServiceRepositoryImpl(),
  );

  Future<void> _saveObservations() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _updateObservationsUseCase.call(
        servicioExtintorId: widget.servicioExtintorId,
        observaciones: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar observaciones: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleReturnToScanner() async {
    // Guardar observaciones antes de navegar
    await _saveObservations();

    if (!mounted) return;

    // Navegar al scanner NFC para agregar otro extintor
    // Limpiar el stack hasta la primera ruta (HomePage) y luego construir el stack correcto:
    // HomePage -> ServicesMenuPage -> ServicesScanPage
    // Esto asegura que al dar atrás desde ServicesScanPage, se vaya a ServicesMenuPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ServicesMenuPage()),
      (route) => route.isFirst, // Mantener solo la primera ruta (HomePage)
    );

    // Esperar al siguiente frame para asegurar que la navegación se complete
    // antes de hacer push de ServicesScanPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesScanPage(
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
            ),
          ),
        );
      }
    });
  }

  Future<void> _handleListAllExtinguishers() async {
    // Guardar observaciones antes de navegar
    await _saveObservations();

    if (!mounted) return;

    // Navegar a la página de listado de extintores
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceExtinguisherListPage(
          servicioId: widget.servicioId,
          serviceType: widget.serviceType,
        ),
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
            // Botón: Agregar otro extintor
            SecondaryButton(
              text: 'Agregar otro extintor',
              onPressed: _isSaving ? null : _handleReturnToScanner,
            ),
            const SizedBox(height: 16),
            // Botón: Listar todos los extintores
            PrimaryButton(
              text: 'Listar todos los extintores',
              onPressed: _isSaving ? null : _handleListAllExtinguishers,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
