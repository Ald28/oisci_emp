import '../entities/service_order.dart';
import '../entities/checklist_result.dart';
import '../entities/service_type.dart';

/// Contrato del repositorio de servicios
abstract class ServicesRepository {
  /// Iniciar servicio
  Future<ServiceOrder> startService({
    required String extinguisherId,
    required ServiceType type,
  });

  /// Obtener servicio en progreso
  Future<ServiceOrder?> getServiceInProgress(ServiceType type);

  /// Guardar checklist
  Future<void> saveChecklist({
    required String serviceId,
    required List<ChecklistResult> results,
  });

  /// Guardar observaciones
  Future<void> saveObservations({
    required String serviceId,
    required String observations,
  });

  /// Finalizar servicio
  Future<void> finalizeService({
    required String serviceId,
    required List<String> completedItems,
    String? observations,
  });
}

