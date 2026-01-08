import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/action_button_expand.dart';
import '../../../../core/network/error_handler.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sede_entity.dart';
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../domain/usecases/create_service_usecase.dart';
import '../../data/repositories/sede_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../../../core/auth/auth_service.dart';
import 'services_scan_page.dart';

/// Página del menú de servicios (Mantenimiento e Inspección)
class ServicesMenuPage extends StatefulWidget {
  const ServicesMenuPage({super.key});

  @override
  State<ServicesMenuPage> createState() => _ServicesMenuPageState();
}

class _ServicesMenuPageState extends State<ServicesMenuPage> {
  int? _selectedSedeId;
  List<Sede> _sedes = [];
  bool _isLoadingSedes = false;

  late final GetSedesUseCase _getSedesUseCase = GetSedesUseCase(
    SedeRepositoryImpl(),
  );
  late final CreateServiceUseCase _createServiceUseCase = CreateServiceUseCase(
    ServiceRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadSedes();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  items: _sedes.map((sede) {
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
