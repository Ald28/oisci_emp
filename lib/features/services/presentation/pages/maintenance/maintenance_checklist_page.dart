import 'package:flutter/material.dart';
import '../../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../domain/entities/extinguisher.dart';
import '../../../domain/entities/service_type.dart';
import '../../widgets/maintenance_checklist_item.dart';
import 'widgets/recharge_modal.dart';
import 'widgets/decommission_modal.dart';
import 'widgets/parts_change_modal.dart';
import 'maintenance_observations_page.dart';

/// Pantalla: Checklist de Mantenimiento
class MaintenanceChecklistPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;

  const MaintenanceChecklistPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
  });

  @override
  State<MaintenanceChecklistPage> createState() =>
      _MaintenanceChecklistPageState();
}

class _MaintenanceChecklistPageState extends State<MaintenanceChecklistPage> {
  // Estado de los items del checklist
  final Map<String, bool> _checklistItems = {
    'MANTENIMIENTO': true,
    'RECARGA': false,
    'PRUEBA_HIDRO': false,
    'BAJA_EXTINTOR': false,
    'PINTURA': false,
    'REC_CARTUCHO': false,
    'CAMBIO_PARTES': false,
  };

  // Datos adicionales de los modales
  String? _rechargeAgent;
  String? _decommissionReason;
  String? _partsChangeDetails;

  void _toggleItem(String itemId) {
    setState(() {
      _checklistItems[itemId] = !(_checklistItems[itemId] ?? false);
    });
  }

  Future<void> _openRechargeModal() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => RechargeModal(initialAgent: _rechargeAgent),
    );

    if (result != null) {
      setState(() {
        _rechargeAgent = result;
        _checklistItems['RECARGA'] = true;
      });
    }
  }

  Future<void> _openDecommissionModal() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          DecommissionModal(initialReason: _decommissionReason),
    );

    if (result != null) {
      setState(() {
        _decommissionReason = result;
        _checklistItems['BAJA_EXTINTOR'] = true;
      });
    }
  }

  Future<void> _openPartsChangeModal() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          PartsChangeModal(initialDetails: _partsChangeDetails),
    );

    if (result != null) {
      setState(() {
        _partsChangeDetails = result;
        _checklistItems['CAMBIO_PARTES'] = true;
      });
    }
  }

  void _handleContinue() {
    // Navegar a la página de observaciones
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceObservationsPage(
          extinguisher: widget.extinguisher,
          serviceType: widget.serviceType,
          checklistItems: _checklistItems,
          rechargeAgent: _rechargeAgent,
          decommissionReason: _decommissionReason,
          partsChangeDetails: _partsChangeDetails,
        ),
      ),
    );
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
              'Checklist de Mantenimiento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Lista de items del checklist
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                children: [
                  // MANTENIMIENTO
                  MaintenanceChecklistItem(
                    title: 'MANTENIMIENTO',
                    isChecked: _checklistItems['MANTENIMIENTO'] ?? false,
                    onTap: () => _toggleItem('MANTENIMIENTO'),
                    showEditIcon: false,
                  ),
                  // RECARGA
                  MaintenanceChecklistItem(
                    title: 'RECARGA',
                    isChecked: _checklistItems['RECARGA'] ?? false,
                    onTap: () => _toggleItem('RECARGA'),
                    onEdit: _openRechargeModal,
                    showEditIcon: true,
                    additionalInfo: _rechargeAgent,
                  ),
                  // PRUEBA HIDRO.
                  MaintenanceChecklistItem(
                    title: 'PRUEBA HIDRO.',
                    isChecked: _checklistItems['PRUEBA_HIDRO'] ?? false,
                    onTap: () => _toggleItem('PRUEBA_HIDRO'),
                    showEditIcon: false,
                  ),
                  // BAJA DE EXTINTOR
                  MaintenanceChecklistItem(
                    title: 'BAJA DE EXTINTOR',
                    isChecked: _checklistItems['BAJA_EXTINTOR'] ?? false,
                    onTap: () => _toggleItem('BAJA_EXTINTOR'),
                    onEdit: _openDecommissionModal,
                    showEditIcon: true,
                    additionalInfo: _decommissionReason,
                  ),
                  // PINTURA
                  MaintenanceChecklistItem(
                    title: 'PINTURA',
                    isChecked: _checklistItems['PINTURA'] ?? false,
                    onTap: () => _toggleItem('PINTURA'),
                    showEditIcon: false,
                  ),
                  // REC. CARTUCHO
                  MaintenanceChecklistItem(
                    title: 'REC. CARTUCHO',
                    isChecked: _checklistItems['REC_CARTUCHO'] ?? false,
                    onTap: () => _toggleItem('REC_CARTUCHO'),
                    showEditIcon: false,
                  ),
                  // CAMBIO PARTES
                  MaintenanceChecklistItem(
                    title: 'CAMBIO PARTES',
                    isChecked: _checklistItems['CAMBIO_PARTES'] ?? false,
                    onTap: () => _toggleItem('CAMBIO_PARTES'),
                    onEdit: _openPartsChangeModal,
                    showEditIcon: true,
                    additionalInfo: _partsChangeDetails,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Botón Continuar
            PrimaryButton(text: 'Continuar', onPressed: _handleContinue),
          ],
        ),
      ),
    );
  }
}
