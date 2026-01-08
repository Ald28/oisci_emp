import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Finalizar servicio
class FinalizeServiceUseCase {
  final ServiceRepository repository;

  FinalizeServiceUseCase(this.repository);

  Future<ServiceEntity> call(int servicioId) async {
    return await repository.finalizeService(servicioId);
  }
}
