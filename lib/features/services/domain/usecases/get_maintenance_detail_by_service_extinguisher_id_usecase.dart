import '../entities/maintenance_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Obtener MantenimientoDetalle por servicioExtintorId
class GetMaintenanceDetailByServiceExtinguisherIdUseCase {
  final ServiceRepository repository;

  GetMaintenanceDetailByServiceExtinguisherIdUseCase(this.repository);

  Future<MaintenanceDetailEntity?> call(int servicioExtintorId) async {
    return await repository.getMaintenanceDetailByServiceExtinguisherId(
      servicioExtintorId,
    );
  }
}
