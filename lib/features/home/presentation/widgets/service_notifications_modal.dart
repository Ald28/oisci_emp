import 'package:flutter/material.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../services/domain/entities/service_type.dart';
import '../../../services/presentation/pages/services_scan_page.dart';

/// Modal: Notificaciones de servicios en proceso
class ServiceNotificationsModal extends StatelessWidget {
  final List<ServiceEntity> servicesInProgress;

  const ServiceNotificationsModal({
    super.key,
    required this.servicesInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE84343),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Servicios en Proceso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Lista de servicios
            Flexible(
              child: servicesInProgress.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay servicios en proceso',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: servicesInProgress.length,
                      itemBuilder: (context, index) {
                        final service = servicesInProgress[index];
                        return _buildServiceCard(context, service);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceEntity service) {
    final serviceType = service.type == 'MANTENIMIENTO'
        ? ServiceType.maintenance
        : ServiceType.inspection;

    final typeLabel = service.type == 'MANTENIMIENTO'
        ? 'Mantenimiento'
        : 'Inspección';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE84343),
          child: Icon(
            service.type == 'MANTENIMIENTO' ? Icons.build : Icons.search,
            color: Colors.white,
          ),
        ),
        title: Text(
          typeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${service.id}'),
            Text(
              'Iniciado: ${_formatDate(service.dateStart)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context); // Cerrar modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServicesScanPage(
                serviceType: serviceType,
                servicioId: service.id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
