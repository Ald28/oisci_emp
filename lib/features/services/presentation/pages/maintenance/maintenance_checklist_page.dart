import 'package:flutter/material.dart';
import '../../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../domain/entities/extinguisher_entity.dart';
import '../../../domain/entities/service_type.dart';
import '../../../domain/entities/service_extinguisher_entity.dart';
import '../../../domain/usecases/create_maintenance_detail_usecase.dart';
import '../../../domain/usecases/update_maintenance_detail_usecase.dart';
import '../../../domain/usecases/get_maintenance_detail_by_service_extinguisher_id_usecase.dart';
import '../../../domain/usecases/get_service_extinguishers_by_service_id_usecase.dart';
import '../../../data/repositories/service_repository_impl.dart';
import '../../widgets/maintenance_checklist_item.dart';
import 'widgets/recharge_modal.dart';
import 'widgets/decommission_modal.dart';
import 'widgets/parts_change_modal.dart';
import 'widgets/service_extinguisher_cart_modal.dart';
import 'maintenance_observations_page.dart';

/// Pantalla: Checklist de Mantenimiento
class MaintenanceChecklistPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;
  final int servicioId;
  final int servicioExtintorId;

  const MaintenanceChecklistPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
    required this.servicioId,
    required this.servicioExtintorId,
  });

  @override
  State<MaintenanceChecklistPage> createState() =>
      _MaintenanceChecklistPageState();
}

class _MaintenanceChecklistPageState extends State<MaintenanceChecklistPage> {
  // Estado de los items del checklist
  Map<String, bool> _checklistItems = {
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

  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _hasExistingMaintenance = false;
  List<ServiceExtinguisherEntity> _serviceExtinguishers = [];

  late final CreateMaintenanceDetailUseCase _createMaintenanceDetailUseCase =
      CreateMaintenanceDetailUseCase(ServiceRepositoryImpl());
  late final UpdateMaintenanceDetailUseCase _updateMaintenanceDetailUseCase =
      UpdateMaintenanceDetailUseCase(ServiceRepositoryImpl());
  late final GetMaintenanceDetailByServiceExtinguisherIdUseCase
  _getMaintenanceDetailUseCase =
      GetMaintenanceDetailByServiceExtinguisherIdUseCase(
        ServiceRepositoryImpl(),
      );
  late final GetServiceExtinguishersByServiceIdUseCase
  _getServiceExtinguishersUseCase = GetServiceExtinguishersByServiceIdUseCase(
    ServiceRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadExistingMaintenanceDetail();
    _loadServiceExtinguishers();
  }

  Future<void> _loadServiceExtinguishers() async {
    try {
      final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
        widget.servicioId,
      );

      if (mounted) {
        setState(() {
          _serviceExtinguishers = serviceExtinguishers;
        });
      }
    } catch (e) {
      // Si hay error, no hacer nada (la lista queda vacía)
    }
  }

  Future<void> _loadExistingMaintenanceDetail() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final existingDetail = await _getMaintenanceDetailUseCase.call(
        widget.servicioExtintorId,
      );

      if (existingDetail != null && mounted) {
        setState(() {
          _hasExistingMaintenance = true;
          // Cargar los datos existentes en el estado
          _checklistItems = {
            'MANTENIMIENTO': existingDetail.mantenimiento,
            'RECARGA': existingDetail.recarga,
            'PRUEBA_HIDRO': existingDetail.pruebaHidrostatica,
            'BAJA_EXTINTOR': existingDetail.bajaExtintor,
            'PINTURA': existingDetail.pintura,
            'REC_CARTUCHO': existingDetail.recargaCartucho,
            'CAMBIO_PARTES': existingDetail.cambioPartes,
          };
          _rechargeAgent = existingDetail.agenteCarga;
          _decommissionReason = existingDetail.motivoBaja;
          // Para cambioPartes, no hay un campo específico en MaintenanceDetailEntity
          // Si necesitas almacenar los detalles de cambio de partes, podrías necesitar un campo adicional
        });
      }
    } catch (e) {
      // Si hay error, continuar sin cargar datos (modo creación)
      if (mounted) {
        setState(() {
          _hasExistingMaintenance = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

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

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Mapear los datos del checklist al formato del backend
      final checklistData = <String, dynamic>{
        'mantenimiento': _checklistItems['MANTENIMIENTO'] ?? false,
        'recarga': _checklistItems['RECARGA'] ?? false,
        'agenteCarga': _rechargeAgent, // Solo si recarga está activa
        'pruebaHidrostatica': _checklistItems['PRUEBA_HIDRO'] ?? false,
        'bajaExtintor': _checklistItems['BAJA_EXTINTOR'] ?? false,
        'motivoBaja': _decommissionReason, // Solo si baja está activa
        'pintura': _checklistItems['PINTURA'] ?? false,
        'recargaCartucho': _checklistItems['REC_CARTUCHO'] ?? false,
        'cambioPartes': _checklistItems['CAMBIO_PARTES'] ?? false,
      };

      // Crear o actualizar MantenimientoDetalle según corresponda
      if (_hasExistingMaintenance) {
        // Actualizar MantenimientoDetalle existente
        await _updateMaintenanceDetailUseCase.call(
          servicioExtintorId: widget.servicioExtintorId,
          checklistData: checklistData,
        );
      } else {
        // Crear nuevo MantenimientoDetalle
        await _createMaintenanceDetailUseCase.call(
          servicioExtintorId: widget.servicioExtintorId,
          checklistData: checklistData,
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navegar a la página de observaciones
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MaintenanceObservationsPage(
            extinguisher: widget.extinguisher,
            serviceType: widget.serviceType,
            servicioId: widget.servicioId,
            servicioExtintorId: widget.servicioExtintorId,
            checklistItems: _checklistItems,
            rechargeAgent: _rechargeAgent,
            decommissionReason: _decommissionReason,
            partsChangeDetails: _partsChangeDetails,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al ${_hasExistingMaintenance ? 'actualizar' : 'crear'} detalle de mantenimiento: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCartIconWithBadge() {
    final count = _serviceExtinguishers.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCartModal() async {
    try {
      final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
        widget.servicioId,
      );

      if (!mounted) return;

      // Actualizar el estado local
      setState(() {
        _serviceExtinguishers = serviceExtinguishers;
      });

      showDialog(
        context: context,
        builder: (context) => ServiceExtinguisherCartModal(
          serviceExtinguishers: serviceExtinguishers,
          servicioId: widget.servicioId,
          serviceType: widget.serviceType,
        ),
      ).then((_) {
        // Recargar cuando se cierra el modal
        _loadServiceExtinguishers();
        _loadExistingMaintenanceDetail(); // También recargar el checklist
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar extintores: ${e.toString()}'),
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
        title:
            'Servicios/${widget.serviceType == ServiceType.maintenance ? 'Mantenimiento' : 'Inspección'}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _buildCartIconWithBadge(),
            onPressed: _showCartModal,
            tooltip: 'Ver extintores agregados',
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE84343)),
            )
          : SingleChildScrollView(
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
                  PrimaryButton(
                    text: 'Continuar',
                    onPressed: _isLoading ? null : _handleContinue,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
    );
  }
}
