import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Obtener servicios EN_PROCESO por usuarioCreadorId
class GetServicesInProgressUseCase {
  final ServiceRepository repository;

  GetServicesInProgressUseCase(this.repository);

  Future<List<ServiceEntity>> call() async {
    return await repository.getServicesInProgress();
  }
}
