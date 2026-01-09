import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/nfc/nfc_service.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../widgets/nfc_hint_card.dart';
import '../widgets/code_search_field.dart';
import 'service_data_page.dart';
import 'service_register_page.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/service_extinguisher_entity.dart';
import '../../domain/usecases/search_extinguisher_usecase.dart';
import '../../domain/usecases/get_service_extinguishers_by_service_id_usecase.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import 'maintenance/widgets/service_extinguisher_cart_modal.dart';

/// Pantalla: NFC + input manual + Buscar
/// Compartida para Mantenimiento e Inspección
class ServicesScanPage extends StatefulWidget {
  final ServiceType serviceType;
  final int servicioId;

  const ServicesScanPage({
    super.key,
    required this.serviceType,
    required this.servicioId,
  });

  @override
  State<ServicesScanPage> createState() => _ServicesScanPageState();
}

class _ServicesScanPageState extends State<ServicesScanPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = false;
  bool _isSearching = false;
  List<ServiceExtinguisherEntity> _serviceExtinguishers = [];

  // Inicializar use cases
  late final SearchExtinguisherUseCase _searchUseCase =
      SearchExtinguisherUseCase(ExtinguisherRepositoryImpl());
  late final GetServiceExtinguishersByServiceIdUseCase
  _getServiceExtinguishersUseCase = GetServiceExtinguishersByServiceIdUseCase(
    ServiceRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleNfcScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Escanear tarjeta NFC
      final result = await NfcService.scan();

      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer la tarjeta NFC'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Usar codeNFC si está disponible, sino usar UID
      final searchTerm = result.codeNFC ?? result.uid;

      // Mostrar mensaje informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.codeNFC != null
                ? 'codeNFC leído: ${result.codeNFC}'
                : 'UID leído: ${result.uid}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Buscar extintor
      await _searchExtinguisher(searchTerm);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear NFC: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleManualSearch() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un código o número de serie'),
        ),
      );
      return;
    }

    await _searchExtinguisher(_codeController.text.trim());
  }

  Future<void> _handleBackButton(BuildContext context) async {
    // Mostrar modal de confirmación para salir del servicio de mantenimiento
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del servicio?'),
        content: const Text(
          '¿Está seguro de que desea salir del servicio de mantenimiento? Se perderán los cambios no guardados.',
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
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldExit != true || !context.mounted) return;

    // Si puede hacer pop, hacerlo normalmente (volver a ServicesMenuPage)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // Si no puede hacer pop, no hacer nada (no debería pasar en flujo normal)
  }

  Future<void> _searchExtinguisher(String searchTerm) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final extinguisher = await _searchUseCase.call(searchTerm);

      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      if (extinguisher != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDataPage(
              extinguisher: extinguisher,
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
            ),
          ),
        );
      } else {
        // Si no encuentra el extintor, abrir directamente el formulario de registro
        // con el número de serie autocompletado (como en movil-aldo)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRegisterPage(
              serviceType: widget.serviceType,
              initialSerial: searchTerm,
              servicioId: widget.servicioId,
            ),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      // Usar el helper reutilizable para manejar errores
      final handled = ErrorHandler.handleDioError(
        context,
        e,
        customMessage:
            'Error al buscar extintor: ${ErrorHandler.getErrorMessage(e)}',
      );

      // Si el error 401 fue manejado, no hacer nada más
      if (handled) return;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar extintor: ${e.toString()}'),
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
          onPressed: () => _handleBackButton(context),
        ),
        actions: [
          IconButton(
            icon: _buildCartIconWithBadge(),
            onPressed: _showCartModal,
            tooltip: 'Ver extintores agregados',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Instrucción NFC
            const Text(
              'Acerca la tarjeta del extintor al teléfono',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Tarjeta NFC
            Center(
              child: _isScanning
                  ? const CircularProgressIndicator(color: Color(0xFFE84343))
                  : InkWell(onTap: _handleNfcScan, child: NfcHintCard()),
            ),
            const SizedBox(height: 32),
            // Campo de búsqueda manual
            _isSearching
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFE84343),
                      ),
                    ),
                  )
                : CodeSearchField(
                    controller: _codeController,
                    onSearch: _handleManualSearch,
                  ),
          ],
        ),
      ),
    );
  }
}
