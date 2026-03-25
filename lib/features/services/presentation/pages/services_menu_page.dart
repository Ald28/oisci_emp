import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../home/presentation/widgets/service_notifications_modal.dart';
import '../../../../core/widgets/action_button_expand.dart';
import '../../../../core/network/error_handler.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/sede_entity.dart';
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../domain/usecases/create_service_usecase.dart';
import '../../domain/usecases/get_services_in_progress_usecase.dart';
import '../../data/repositories/sede_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../client_statistics/domain/entities/client_entity.dart';
import '../../../client_statistics/data/repositories/client_repository_impl.dart';
import '../../../client_statistics/domain/usecases/search_clients_usecase.dart';
import 'services_scan_page.dart';

/// Página del menú de servicios (Mantenimiento e Inspección)
class ServicesMenuPage extends StatefulWidget {
  const ServicesMenuPage({super.key});

  @override
  State<ServicesMenuPage> createState() => _ServicesMenuPageState();
}

class _ServicesMenuPageState extends State<ServicesMenuPage> {
  int? _selectedClientId;
  List<ClientEntity> _clients = [];
  bool _isLoadingClients = false;

  int? _selectedSedeId;
  List<Sede> _sedes = [];
  bool _isLoadingSedes = false;
  List<ServiceEntity> _servicesInProgress = [];

  late final GetSedesUseCase _getSedesUseCase = GetSedesUseCase(
    SedeRepositoryImpl(),
  );
  late final CreateServiceUseCase _createServiceUseCase = CreateServiceUseCase(
    ServiceRepositoryImpl(),
  );
  late final GetServicesInProgressUseCase _getServicesInProgressUseCase =
      GetServicesInProgressUseCase(ServiceRepositoryImpl());
  late final SearchClientsUseCase _searchClientsUseCase = SearchClientsUseCase(
    ClientRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadSedes();
    _checkServiceInProgress();
  }

  Future<void> _checkServiceInProgress() async {
    try {
      final services = await _getServicesInProgressUseCase.call();

      if (mounted) {
        setState(() {
          _servicesInProgress = services;
        });
      }
    } catch (e) {
      // Si hay error, no mostrar notificaciones
      if (mounted) {
        setState(() {
          _servicesInProgress = [];
        });
      }
    }
  }

  void _handleShowNotifications() {
    showDialog(
      context: context,
      builder: (context) =>
          ServiceNotificationsModal(servicesInProgress: _servicesInProgress),
    );
  }

  Widget _buildNotificationIcon() {
    final count = _servicesInProgress.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _handleShowNotifications,
          tooltip: 'Notificaciones',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
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

  Future<void> _handleRefresh() async {
    await Future.wait([_loadClients(), _loadSedes(), _checkServiceInProgress()]);
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoadingClients = true;
    });

    try {
      final responseData = await _searchClientsUseCase.call(page: 1, pageSize: 100);

      if (responseData['data'] != null && mounted) {
        setState(() {
          _clients = (responseData['data'] as List).cast<ClientEntity>();
          _isLoadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadSedes() async {
    setState(() {
      _isLoadingSedes = true;
    });

    try {
      final sedes = await _getSedesUseCase();

      if (mounted) {
        setState(() {
          _sedes = sedes;
          _isLoadingSedes = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSedes = false;
        });
        ErrorHandler.handleDioError(
          context,
          e,
          customMessage:
              'Error al cargar sedes: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSedes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sedes: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _serviceTypeToString(ServiceType type) {
    switch (type) {
      case ServiceType.maintenance:
        return 'MANTENIMIENTO';
      case ServiceType.inspection:
        return 'INSPECCION';
    }
  }

  Future<void> _handleServiceSelection(ServiceType serviceType) async {
    // Verificar si hay sede seleccionada
    if (_selectedSedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una sede'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Obtener userId de la sesión
    final userIdStr = await AuthService.getUserId();
    if (!mounted) return;
    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el ID del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = int.parse(userIdStr);
    final typeStr = _serviceTypeToString(serviceType);

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Crear servicio
      final service = await _createServiceUseCase.call(
        type: typeStr,
        dateStart: DateTime.now(),
        sedeId: _selectedSedeId!,
        userId: userId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Navegar a ServicesScanPage con el servicioId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServicesScanPage(
            serviceType: serviceType,
            servicioId: service.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear servicio: ${e.toString()}'),
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
        actions: [_buildNotificationIcon()],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFE84343),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Alerta de servicio en proceso
              if (_servicesInProgress.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tienes un mantenimiento en proceso',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Servicio ID: ${_servicesInProgress.first.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_servicesInProgress.isNotEmpty) {
                            final service = _servicesInProgress.first;
                            final serviceType = service.type == 'MANTENIMIENTO'
                                ? ServiceType.maintenance
                                : ServiceType.inspection;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServicesScanPage(
                                  serviceType: serviceType,
                                  servicioId: service.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Ver'),
                      ),
                    ],
                  ),
                ),
              // Selector de Cliente
              const Text(
                'Seleccionar cliente:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildClientDropdown(),
              const SizedBox(height: 16),
              // Selector de Sede
              const Text(
                'Seleccionar sede:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildSedeDropdown(),
              const SizedBox(height: 28),
              const Text(
                'Seleccionar el servicio a realizar:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              // Botones de servicios (ancho completo)
              ActionButtonExpand(
                icon: Icons.build,
                title: 'Mantenimiento',
                subtitle: 'Gestionar mantenimiento',
                onTap: () => _handleServiceSelection(ServiceType.maintenance),
              ),
              const SizedBox(height: 16),
              ActionButtonExpand(
                icon: Icons.search,
                title: 'Inspección',
                subtitle: 'Gestionar inspección',
                onTap: () => _handleServiceSelection(ServiceType.inspection),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientDropdown() {
    final hasValue = _selectedClientId != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
          child: _isLoadingClients
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<int>(
                  initialValue: _selectedClientId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  hint: const Text(
                    'Seleccionar cliente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  items: _clients.map((client) {
                    return DropdownMenuItem<int>(
                      value: client.id,
                      child: Text(
                        client.razonSocial,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                      _selectedSedeId = null; // Reset sede when client changes
                    });
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
        ),
        if (hasValue)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cliente',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSedeDropdown() {
    final hasValue = _selectedSedeId != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
          child: _isLoadingSedes
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<int>(
                  initialValue: _selectedSedeId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  hint: const Text(
                    'Seleccionar sede',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  items: _sedes
                      .where((sede) => sede.clientId == _selectedClientId)
                      .map((sede) {
                    return DropdownMenuItem<int>(
                      value: sede.id,
                      child: Text(
                        sede.nameSede,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSedeId = value;
                    });
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
        ),
        if (hasValue)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Sede',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
