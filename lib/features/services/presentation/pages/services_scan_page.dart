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
import '../../domain/usecases/search_extinguisher_usecase.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';

/// Pantalla: NFC + input manual + Buscar
/// Compartida para Mantenimiento e Inspección
class ServicesScanPage extends StatefulWidget {
  final ServiceType serviceType;

  const ServicesScanPage({super.key, required this.serviceType});

  @override
  State<ServicesScanPage> createState() => _ServicesScanPageState();
}

class _ServicesScanPageState extends State<ServicesScanPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = false;
  bool _isSearching = false;

  // Inicializar use case
  late final SearchExtinguisherUseCase _searchUseCase =
      SearchExtinguisherUseCase(ExtinguisherRepositoryImpl());

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
          onPressed: () => Navigator.pop(context),
        ),
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
