import 'package:flutter/material.dart';
import '../../domain/entities/service_extinguisher_entity.dart';
import '../../domain/entities/service_type.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import '../../domain/usecases/get_extinguisher_by_id_usecase.dart';
import '../pages/maintenance/maintenance_checklist_page.dart';
import '../pages/inspection/inspection_checklist_page.dart';

/// Modal: Carrito de extintores agregados al servicio
class ServiceExtinguisherCartModal extends StatelessWidget {
  final List<ServiceExtinguisherEntity> serviceExtinguishers;
  final int servicioId;
  final ServiceType serviceType;
  final int?
  currentServicioExtintorId; // ID del extintor actual si estamos en un checklist

  const ServiceExtinguisherCartModal({
    super.key,
    required this.serviceExtinguishers,
    required this.servicioId,
    required this.serviceType,
    this.currentServicioExtintorId,
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
                              (item.codeExtintor != null &&
                                          item.codeExtintor!.isNotEmpty) ||
                                      (item.serialNumberNFC != null &&
                                          item.serialNumberNFC!.isNotEmpty)
                                  ? 'Código: ${item.codeExtintor ?? item.serialNumberNFC}'
                                  : 'Extintor ID: ${item.extintorId}',
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
    // Verificar PRIMERO si ya estamos en la página del mismo extintor
    // Esto evita mostrar loading innecesario
    if (currentServicioExtintorId != null &&
        currentServicioExtintorId == item.id) {
      // Obtener el NavigatorState ANTES de cerrar el modal y hacer await
      final rootNavigator = Navigator.of(context, rootNavigator: true);

      // Cerrar el modal
      Navigator.pop(context);

      // Esperar un momento para que el modal se cierre
      await Future.delayed(const Duration(milliseconds: 100));

      // Obtener el contexto después del await
      final rootContext = rootNavigator.context;

      if (rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(
            content: Text('Ya estás trabajando en este extintor'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Obtener el NavigatorState raíz ANTES de cerrar el modal
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // Cerrar el modal primero
    Navigator.pop(context);

    // Obtener el contexto del Navigator raíz inmediatamente
    final rootContext = rootNavigator.context;
    if (!rootContext.mounted) return;

    // NO mostrar loading aquí - la página de checklist mostrará su propio loading
    // El repositorio ya maneja cache local primero, así que obtener el extinguisher será rápido
    try {
      // Obtener el extinguisher por extintorId
      final getExtinguisherUseCase = GetExtinguisherByIdUseCase(
        ExtinguisherRepositoryImpl(),
      );
      final extinguisher = await getExtinguisherUseCase.call(item.extintorId);

      // Verificar si el contexto sigue siendo válido después del await
      if (!rootContext.mounted) return;

      if (extinguisher == null) {
        if (!rootContext.mounted) return;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text(
              'Error: No se pudo encontrar el extintor (ID: ${item.extintorId}). '
              'Puede que el extintor aún no esté sincronizado.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Navegar directamente - la página mostrará su propio loading
      // Si currentServicioExtintorId no es null, significa que estamos en un checklist
      // En ese caso, usar pushReplacement para evitar apilar páginas
      final isCurrentlyInChecklist = currentServicioExtintorId != null;

      final route = serviceType == ServiceType.maintenance
          ? MaterialPageRoute(
              builder: (_) => MaintenanceChecklistPage(
                extinguisher: extinguisher,
                serviceType: serviceType,
                servicioId: servicioId,
                servicioExtintorId: item.id,
              ),
            )
          : MaterialPageRoute(
              builder: (_) => InspectionChecklistPage(
                extinguisher: extinguisher,
                serviceType: serviceType,
                servicioId: servicioId,
                servicioExtintorId: item.id,
              ),
            );

      // Si ya estamos en un checklist, reemplazar en lugar de apilar
      if (isCurrentlyInChecklist) {
        rootNavigator.pushReplacement(route);
      } else {
        rootNavigator.push(route);
      }
    } catch (e) {
      if (!rootContext.mounted) return;

      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar extintor: ${e.toString()}\n'
            'Extintor ID: ${item.extintorId}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
