import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/action_button_expand.dart';
import '../../domain/entities/service_type.dart';
import 'services_scan_page.dart';

/// Página del menú de servicios (Mantenimiento e Inspección)
class ServicesMenuPage extends StatelessWidget {
  const ServicesMenuPage({super.key});

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServicesScanPage(
                      serviceType: ServiceType.maintenance,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ActionButtonExpand(
              icon: Icons.search,
              title: 'Inspección',
              subtitle: 'Gestionar inspección',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServicesScanPage(
                      serviceType: ServiceType.inspection,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

