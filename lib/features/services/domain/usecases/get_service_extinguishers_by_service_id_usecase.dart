import '../entities/service_extinguisher_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Obtener lista de ServicioExtintor por servicioId
class GetServiceExtinguishersByServiceIdUseCase {
  final ServiceRepository repository;

  GetServiceExtinguishersByServiceIdUseCase(this.repository);

  Future<List<ServiceExtinguisherEntity>> call(int servicioId) async {
    return await repository.getServiceExtinguishersByServiceId(servicioId);
  }
}
