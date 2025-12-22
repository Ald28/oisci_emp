import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/service_type.dart';

/// Pantalla: Registro de extintor nuevo
class ServiceRegisterPage extends StatelessWidget {
  final ServiceType serviceType;

  const ServiceRegisterPage({
    super.key,
    required this.serviceType,
  });

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
            // Título REGISTRO
            const Text(
              'REGISTRO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Formulario de registro
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField('CÓDIGO DE QR', Icons.qr_code_scanner),
                    const SizedBox(height: 16),
                    _buildTextField('TIPO'),
                    const SizedBox(height: 16),
                    _buildTextField('AGENTE'),
                    const SizedBox(height: 16),
                    _buildTextField('UBICACIÓN'),
                    const SizedBox(height: 16),
                    _buildTextField('NRO. SERIE'),
                    const SizedBox(height: 16),
                    _buildTextField('NRO. UBICACIÓN'),
                    const SizedBox(height: 16),
                    _buildTextField('FECHA DE MANTTO'),
                    const SizedBox(height: 16),
                    _buildTextField('FECHA DE PRUEBA H'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Botón Buscar/Registrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementar registro de extintor
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Extintor registrado exitosamente'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84343),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Registrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, [IconData? icon]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: icon != null
                ? Icon(
                    icon,
                    color: Colors.grey[600],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
