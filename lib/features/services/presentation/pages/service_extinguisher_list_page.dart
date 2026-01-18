import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/service_extinguisher_entity.dart';
import '../../domain/usecases/get_service_extinguishers_by_service_id_usecase.dart';
import '../../domain/usecases/finalize_service_usecase.dart';
import '../../domain/usecases/get_extinguisher_by_id_usecase.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import 'maintenance/maintenance_checklist_page.dart';
import 'inspection/inspection_checklist_page.dart';

/// Página: Lista de ServicioExtintor (Carrito)
class ServiceExtinguisherListPage extends StatefulWidget {
  final int servicioId;
  final ServiceType serviceType;

  const ServiceExtinguisherListPage({
    super.key,
    required this.servicioId,
    required this.serviceType,
  });

  @override
  State<ServiceExtinguisherListPage> createState() =>
      _ServiceExtinguisherListPageState();
}

class _ServiceExtinguisherListPageState
    extends State<ServiceExtinguisherListPage> {
  List<ServiceExtinguisherEntity> _serviceExtinguishers = [];
  bool _isLoading = true;
  bool _isFinalizing = false;

  late final GetServiceExtinguishersByServiceIdUseCase
  _getServiceExtinguishersUseCase = GetServiceExtinguishersByServiceIdUseCase(
    ServiceRepositoryImpl(),
  );
  late final FinalizeServiceUseCase _finalizeServiceUseCase =
      FinalizeServiceUseCase(ServiceRepositoryImpl());
  late final GetExtinguisherByIdUseCase _getExtinguisherUseCase =
      GetExtinguisherByIdUseCase(ExtinguisherRepositoryImpl());

  @override
  void initState() {
    super.initState();
    _loadServiceExtinguishers();
  }

  Future<void> _loadServiceExtinguishers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
        widget.servicioId,
      );

      if (mounted) {
        setState(() {
          _serviceExtinguishers = serviceExtinguishers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar extintores: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFinalizeService() async {
    // Mostrar modal de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Está seguro de que desea finalizar el servicio?'),
        content: const Text(
          'Tenga en cuenta que, una vez finalizado, se enviará automáticamente el reporte al administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE84343),
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isFinalizing = true;
    });

    try {
      await _finalizeServiceUseCase.call(widget.servicioId);

      if (!mounted) return;

      setState(() {
        _isFinalizing = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio finalizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar de vuelta (puedes ajustar la navegación según tu flujo)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFinalizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar servicio: ${e.toString()}'),
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE84343)),
            )
          : Column(
              children: [
                // Lista de extintores
                Expanded(
                  child: _serviceExtinguishers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay extintores agregados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _serviceExtinguishers.length,
                          itemBuilder: (context, index) {
                            final item = _serviceExtinguishers[index];
                            return _buildServiceExtinguisherCard(item, index);
                          },
                        ),
                ),
                // Botón Finalizar Servicio
                if (_serviceExtinguishers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: PrimaryButton(
                      text: 'Finalizar Servicio',
                      onPressed: _isFinalizing ? null : _handleFinalizeService,
                      isLoading: _isFinalizing,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _handleItemTap(ServiceExtinguisherEntity item) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE84343)),
      ),
    );

    try {
      // Obtener el extinguisher por extintorId
      final extinguisher = await _getExtinguisherUseCase.call(item.extintorId);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (extinguisher == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: No se pudo encontrar el extintor (ID: ${item.extintorId}). '
              'Puede que el extintor aún no esté sincronizado.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Navegar a la página correspondiente según el tipo de servicio
      if (!mounted) return;

      if (widget.serviceType == ServiceType.maintenance) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceChecklistPage(
              extinguisher: extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
              servicioExtintorId: item.id,
            ),
          ),
        ).then((_) {
          // Recargar cuando se regresa
          _loadServiceExtinguishers();
        });
      } else if (widget.serviceType == ServiceType.inspection) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectionChecklistPage(
              extinguisher: extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
              servicioExtintorId: item.id,
            ),
          ),
        ).then((_) {
          // Recargar cuando se regresa
          _loadServiceExtinguishers();
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar extintor: ${e.toString()}\n'
            'Extintor ID: ${item.extintorId}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildServiceExtinguisherCard(
    ServiceExtinguisherEntity item,
    int index,
  ) {
    // El estado se muestra con un checkmark o cuadro vacío según la imagen de referencia
    final estado = item.estadoInicial ?? 'N/A';
    final estadoIcon = estado == 'OPERATIVO'
        ? const Icon(Icons.check, color: Colors.green, size: 20)
        : const Icon(
            Icons.check_box_outline_blank,
            color: Colors.grey,
            size: 20,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE84343),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.serialNumber != null && item.serialNumber!.isNotEmpty
              ? 'Código: ${item.serialNumber}'
              : 'Extintor ID: ${item.extintorId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.observaciones != null && item.observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Obs: ${item.observaciones}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: estadoIcon,
        onTap: () => _handleItemTap(item),
      ),
    );
  }
}
