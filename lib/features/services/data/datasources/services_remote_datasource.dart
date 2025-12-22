import '../models/service_order_dto.dart';
import '../models/checklist_result_dto.dart';
import '../models/service_close_request_dto.dart';

/// Datasource remoto: API para servicios
abstract class ServicesRemoteDataSource {
  /// Iniciar un nuevo servicio
  Future<ServiceOrderDto> startService({
    required String extinguisherId,
    required String serviceType, // 'maintenance' | 'inspection'
  });

  /// Obtener servicio en progreso
  Future<ServiceOrderDto?> getServiceInProgress({
    required String serviceType,
  });

  /// Guardar checklist parcial
  Future<void> saveChecklist({
    required String serviceId,
    required List<ChecklistResultDto> results,
  });

  /// Guardar observaciones
  Future<void> saveObservations({
    required String serviceId,
    required String observations,
  });

  /// Finalizar servicio
  Future<void> finalizeService(ServiceCloseRequestDto request);
}

