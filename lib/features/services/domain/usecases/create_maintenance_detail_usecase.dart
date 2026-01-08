import '../entities/maintenance_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Crear detalle de mantenimiento (Etapa 3)
class CreateMaintenanceDetailUseCase {
  final ServiceRepository repository;

  CreateMaintenanceDetailUseCase(this.repository);

  Future<MaintenanceDetailEntity> call({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  }) async {
    return await repository.createMaintenanceDetail(
      servicioExtintorId: servicioExtintorId,
      checklistData: checklistData,
    );
  }
}
