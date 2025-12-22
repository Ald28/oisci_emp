import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../widgets/nfc_hint_card.dart';
import '../widgets/code_search_field.dart';
import 'service_data_page.dart';
import 'service_register_page.dart';
import '../../domain/entities/service_type.dart';

/// Pantalla: NFC + input manual + Buscar
/// Compartida para Mantenimiento e Inspección
class ServicesScanPage extends StatefulWidget {
  final ServiceType serviceType;

  const ServicesScanPage({
    super.key,
    required this.serviceType,
  });

  @override
  State<ServicesScanPage> createState() => _ServicesScanPageState();
}

class _ServicesScanPageState extends State<ServicesScanPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleNfcScan() async {
    setState(() {
      _isScanning = true;
    });

    // TODO: Implementar escaneo NFC real
    // Por ahora simulamos un escaneo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });

      // Simulamos que encontramos un código
      final scannedCode = 'PG05'; // Esto vendría del NFC
      await _searchExtinguisher(scannedCode);
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

  Future<void> _searchExtinguisher(String code) async {
    // TODO: Llamar al API para buscar el extintor
    // Por ahora simulamos la búsqueda
    final extinguisherExists = code.isNotEmpty; // Simulación

    if (!mounted) return;

    if (extinguisherExists) {
      // Extintor existe, navegar a datos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDataPage(
            extinguisherCode: code,
            serviceType: widget.serviceType,
          ),
        ),
      );
    } else {
      // Extintor no existe, mostrar modal
      _showExtinguisherNotFoundDialog(code);
    }
  }

  void _showExtinguisherNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extintor no encontrado'),
        content: Text(
          'El extintor con código "$code" no existe en la base de datos.\n\n¿Deseas registrar un nuevo extintor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceRegisterPage(
                    serviceType: widget.serviceType,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84343),
              foregroundColor: Colors.white,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
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
                  ? const CircularProgressIndicator(
                      color: Color(0xFFE84343),
                    )
                  : InkWell(
                      onTap: _handleNfcScan,
                      child: NfcHintCard(),
                    ),
            ),
            const SizedBox(height: 32),
            // Campo de búsqueda manual
            CodeSearchField(
              controller: _codeController,
              onSearch: _handleManualSearch,
            ),
          ],
        ),
      ),
    );
  }
}
