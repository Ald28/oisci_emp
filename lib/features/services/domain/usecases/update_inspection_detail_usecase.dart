import '../entities/inspection_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Actualizar InspeccionDetalle
class UpdateInspectionDetailUseCase {
  final ServiceRepository repository;

  UpdateInspectionDetailUseCase(this.repository);

  Future<InspectionDetailEntity> call({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
  }) async {
    return await repository.updateInspectionDetail(
      servicioExtintorId: servicioExtintorId,
      inspectionData: inspectionData,
    );
  }
}
