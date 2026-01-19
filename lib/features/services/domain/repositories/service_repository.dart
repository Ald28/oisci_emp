import '../entities/service_entity.dart';
import '../entities/service_extinguisher_entity.dart';
import '../entities/maintenance_detail_entity.dart';
import '../entities/inspection_detail_entity.dart';

/// Contrato del repositorio de servicios
abstract class ServiceRepository {
  /// Etapa 1: Crear servicio
  Future<ServiceEntity> createService({
    required String type,
    required DateTime dateStart,
    required int sedeId,
    required int userId,
  });

  /// Obtener servicio por ID
  Future<ServiceEntity?> getServiceById(int id);

  /// Finalizar servicio
  Future<ServiceEntity> finalizeService(int servicioId);

  /// Obtener servicios EN_PROCESO por usuarioCreadorId
  Future<List<ServiceEntity>> getServicesInProgress();

  /// Etapa 2: Agregar extintor a servicio
  Future<ServiceExtinguisherEntity> addExtinguisherToService({
    required int servicioId,
    required int extintorId,
    String? estadoInicial,
    String? observaciones,
  });

  /// Obtener ServicioExtintor por servicioId y extintorId
  Future<ServiceExtinguisherEntity?>
  getServiceExtinguisherByServiceAndExtinguisher({
    required int servicioId,
    required int extintorId,
  });

  /// Marcar ServicioExtintor como completado
  Future<void> markServiceExtinguisherCompleted(int servicioExtintorId);

  /// Actualizar observaciones de ServicioExtintor
  Future<void> updateServiceExtinguisherObservations({
    required int servicioExtintorId,
    required String? observaciones,
  });

  /// Obtener todos los ServicioExtintor por servicioId
  Future<List<ServiceExtinguisherEntity>> getServiceExtinguishersByServiceId(
    int servicioId,
  );

  /// Etapa 3: Crear detalle de mantenimiento
  Future<MaintenanceDetailEntity> createMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  });

  /// Obtener MantenimientoDetalle por servicioExtintorId
  Future<MaintenanceDetailEntity?> getMaintenanceDetailByServiceExtinguisherId(
    int servicioExtintorId,
  );

  /// Obtener servicios por sedeId
  Future<List<ServiceEntity>> getServicesBySedeId(int sedeId);

  Future<MaintenanceDetailEntity> updateMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  });

  /// Crear detalle de inspección
  Future<InspectionDetailEntity> createInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
  });

  /// Obtener InspeccionDetalle por servicioExtintorId
  Future<InspectionDetailEntity?> getInspectionDetailByServiceExtinguisherId(
    int servicioExtintorId,
  );

  /// Actualizar InspeccionDetalle
  Future<InspectionDetailEntity> updateInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
  });
}
