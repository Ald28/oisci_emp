import '../../../services/domain/entities/service_entity.dart';
import '../../../services/domain/repositories/service_repository.dart';

/// Use case: Obtener servicios por sedeId
class GetServicesBySedeUseCase {
  final ServiceRepository repository;

  GetServicesBySedeUseCase(this.repository);

  Future<List<ServiceEntity>> call(int sedeId) async {
    return await repository.getServicesBySedeId(sedeId);
  }
}
