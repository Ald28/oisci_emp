import 'package:flutter/material.dart';
import '../../../../domain/entities/service_extinguisher_entity.dart';
import '../../../../domain/entities/service_type.dart';
import '../../../../data/repositories/extinguisher_repository_impl.dart';
import '../../../../domain/usecases/get_extinguisher_by_id_usecase.dart';
import '../maintenance_checklist_page.dart';

/// Modal: Carrito de extintores agregados al servicio
class ServiceExtinguisherCartModal extends StatelessWidget {
  final List<ServiceExtinguisherEntity> serviceExtinguishers;
  final int servicioId;
  final ServiceType serviceType;

  const ServiceExtinguisherCartModal({
    super.key,
    required this.serviceExtinguishers,
    required this.servicioId,
    required this.serviceType,
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
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Extintores Agregados',
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
            // Lista de extintores
            Flexible(
              child: serviceExtinguishers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
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
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: serviceExtinguishers.length,
                      itemBuilder: (context, index) {
                        final item = serviceExtinguishers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                              'Extintor ID: ${item.extintorId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle:
                                item.observaciones != null &&
                                    item.observaciones!.isNotEmpty
                                ? Text(
                                    item.observaciones!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            trailing: Icon(
                              item.estadoInicial == 'OPERATIVO'
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: item.estadoInicial == 'OPERATIVO'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onTap: () => _handleItemTap(context, item),
                          ),
                        );
                      },
                    ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: ${serviceExtinguishers.length} extintor${serviceExtinguishers.length != 1 ? 'es' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemTap(
    BuildContext context,
    ServiceExtinguisherEntity item,
  ) async {
    // Cerrar el modal primero
    Navigator.pop(context);

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
      final getExtinguisherUseCase = GetExtinguisherByIdUseCase(
        ExtinguisherRepositoryImpl(),
      );
      final extinguisher = await getExtinguisherUseCase.call(item.extintorId);

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (extinguisher == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo encontrar el extintor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Solo navegar si es mantenimiento (inspección no está implementado)
      if (serviceType == ServiceType.maintenance) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceChecklistPage(
              extinguisher: extinguisher,
              serviceType: serviceType,
              servicioId: servicioId,
              servicioExtintorId: item.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar extintor: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
