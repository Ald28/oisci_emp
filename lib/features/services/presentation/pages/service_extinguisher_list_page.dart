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
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../data/repositories/sede_repository_impl.dart';
import '../../../client_statistics/domain/entities/client_entity.dart';
import '../../../client_statistics/data/repositories/client_repository_impl.dart';
import '../../../client_statistics/domain/usecases/search_clients_usecase.dart';
import '../../domain/usecases/add_extinguisher_to_service_usecase.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../domain/usecases/get_inspection_detail_by_service_extinguisher_id_usecase.dart';
import 'maintenance/maintenance_checklist_page.dart';
import 'inspection/inspection_checklist_page.dart';

class ExtinguisherItem {
  final Extinguisher extinguisher;
  final ServiceExtinguisherEntity? serviceExtinguisher;
  final bool hasRecord;

  ExtinguisherItem({
    required this.extinguisher,
    this.serviceExtinguisher,
    this.hasRecord = false,
  });
}

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
  List<ExtinguisherItem> _items = [];
  bool _isLoading = true;
  bool _isFinalizing = false;

  String _clientName = 'Cargando...';
  String _sedeName = 'Cargando...';

  late final GetServiceExtinguishersByServiceIdUseCase
  _getServiceExtinguishersUseCase = GetServiceExtinguishersByServiceIdUseCase(
    ServiceRepositoryImpl(),
  );
  late final FinalizeServiceUseCase _finalizeServiceUseCase =
      FinalizeServiceUseCase(ServiceRepositoryImpl());
  late final GetSedesUseCase _getSedesUseCase =
      GetSedesUseCase(SedeRepositoryImpl());
  late final SearchClientsUseCase _searchClientsUseCase =
      SearchClientsUseCase(ClientRepositoryImpl());

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
      final service = await ServiceRepositoryImpl().getServiceById(widget.servicioId);

      String tempClientName = 'Desconocido';
      String tempSedeName = 'Desconocido';
      List<ExtinguisherItem> tempItems = [];

      if (service != null && mounted) {
        final sedes = await _getSedesUseCase.call();
        final sede = sedes.where((s) => s.id == service.sedeId).firstOrNull;
        if (sede != null) {
          tempSedeName = sede.nameSede;

          if (sede.clientId != null) {
            final responseData =
                await _searchClientsUseCase.call(page: 1, pageSize: 100);
            final clients = (responseData['data'] as List).cast<ClientEntity>();
            final client =
                clients.where((c) => c.id == sede.clientId).firstOrNull;
            if (client != null) {
              tempClientName = client.razonSocial;
            }
          }
        }

        // 1. Obtener todos los extintores de la sede
        final allExtinguishers = await ExtinguisherRepositoryImpl()
            .getExtinguishersBySedeId(service.sedeId ?? 0);

        // 2. Obtener los status de servicio registrados
        final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
          widget.servicioId,
        );
        final serviceExtByExtId = {
          for (var se in serviceExtinguishers) se.extintorId: se
        };

        // 3. Emparejar extintores con su servicio si lo tienen
        final getInspectionUseCase = GetInspectionDetailByServiceExtinguisherIdUseCase(ServiceRepositoryImpl());
        
        for (final ext in allExtinguishers) {
          final se = serviceExtByExtId[ext.id];
          bool hasRecord = false;

          if (se != null) {
            if (widget.serviceType == ServiceType.inspection) {
              final detail = await getInspectionUseCase.call(se.id);
              hasRecord = detail != null;
            } else {
              hasRecord = se.completado;
            }
          }

          tempItems.add(ExtinguisherItem(
            extinguisher: ext,
            serviceExtinguisher: se,
            hasRecord: hasRecord,
          ));
        }

        // Ordenamiento opcional (por código alfabéticamente)
        tempItems.sort((a, b) {
          final codeA = a.extinguisher.codeExtintor ?? a.extinguisher.serialNumberNFC ?? '';
          final codeB = b.extinguisher.codeExtintor ?? b.extinguisher.serialNumberNFC ?? '';
          return codeA.compareTo(codeB);
        });
      }

      if (mounted) {
        setState(() {
          _clientName = tempClientName;
          _sedeName = tempSedeName;
          _items = tempItems;
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
                // Detalle del cliente y sede
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle del Servicio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cliente: $_clientName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sede: $_sedeName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de extintores
                Expanded(
                  child: _items.isEmpty
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
                                'No hay extintores en esta sede',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 8.0),
                              child: Row(
                                children: const [
                                  SizedBox(
                                      width: 40,
                                      child: Text('ITEM',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      child: Text('COD',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Text('ESTADO',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return _buildServiceExtinguisherCard(item, index);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
                // Botón Finalizar Servicio
                if (_items.isNotEmpty)
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

  Future<void> _handleItemTap(ExtinguisherItem item) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE84343)),
      ),
    );

    try {
      final extinguisher = item.extinguisher;
      ServiceExtinguisherEntity? serviceExtinguisher = item.serviceExtinguisher;

      // Si no existe, crearlo para este servicio
      if (serviceExtinguisher == null) {
        final addExtRec = AddExtinguisherToServiceUseCase(ServiceRepositoryImpl());
        serviceExtinguisher = await addExtRec.call(
           servicioId: widget.servicioId,
           extintorId: extinguisher.id,
           estadoInicial: extinguisher.status ?? 'OPERATIVO',
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Navegar a la página correspondiente según el tipo de servicio
      if (widget.serviceType == ServiceType.maintenance) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceChecklistPage(
              extinguisher: extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
              servicioExtintorId: serviceExtinguisher!.id,
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
              servicioExtintorId: serviceExtinguisher!.id,
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
            'Extintor ID: ${item.extinguisher.id}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildServiceExtinguisherCard(
    ExtinguisherItem item,
    int index,
  ) {
    final extinguisher = item.extinguisher;
    final se = item.serviceExtinguisher;

    // Verificar si se completó el servicio
    final bool isCompleted = item.hasRecord;

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
          (extinguisher.codeExtintor != null && extinguisher.codeExtintor!.isNotEmpty) ||
                  (extinguisher.serialNumberNFC != null &&
                      extinguisher.serialNumberNFC!.isNotEmpty)
              ? '${extinguisher.codeExtintor ?? extinguisher.serialNumberNFC}'
              : 'ID: ${extinguisher.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: se?.observaciones != null && se!.observaciones!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Obs: ${se.observaciones}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: isCompleted
            ? const Icon(Icons.check_box, color: Colors.green, size: 32)
            : const Icon(Icons.check_box_outline_blank, color: Colors.red, size: 32),
        onTap: () => _handleItemTap(item),
      ),
    );
  }
}
