import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Obtener servicio en proceso por tipo
class GetServiceInProgressUseCase {
  final ServiceRepository repository;

  GetServiceInProgressUseCase(this.repository);

  Future<ServiceEntity?> call(String type) async {
    return await repository.getServiceInProgress(type);
  }
}
