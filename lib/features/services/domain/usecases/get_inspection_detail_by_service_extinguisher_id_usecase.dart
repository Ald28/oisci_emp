import '../entities/inspection_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Obtener InspeccionDetalle por servicioExtintorId
class GetInspectionDetailByServiceExtinguisherIdUseCase {
  final ServiceRepository repository;

  GetInspectionDetailByServiceExtinguisherIdUseCase(this.repository);

  Future<InspectionDetailEntity?> call(int servicioExtintorId) async {
    return await repository.getInspectionDetailByServiceExtinguisherId(
      servicioExtintorId,
    );
  }
}
