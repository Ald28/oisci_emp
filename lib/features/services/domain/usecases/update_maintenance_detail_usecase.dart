import '../entities/maintenance_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Actualizar MantenimientoDetalle
class UpdateMaintenanceDetailUseCase {
  final ServiceRepository repository;

  UpdateMaintenanceDetailUseCase(this.repository);

  Future<MaintenanceDetailEntity> call({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  }) async {
    return await repository.updateMaintenanceDetail(
      servicioExtintorId: servicioExtintorId,
      checklistData: checklistData,
    );
  }
}
