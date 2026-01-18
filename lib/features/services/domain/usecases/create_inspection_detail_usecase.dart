import '../entities/inspection_detail_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Crear detalle de inspección
class CreateInspectionDetailUseCase {
  final ServiceRepository repository;

  CreateInspectionDetailUseCase(this.repository);

  Future<InspectionDetailEntity> call({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
  }) async {
    return await repository.createInspectionDetail(
      servicioExtintorId: servicioExtintorId,
      inspectionData: inspectionData,
    );
  }
}
