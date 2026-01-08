import '../entities/service_extinguisher_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Agregar extintor a servicio (Etapa 2)
class AddExtinguisherToServiceUseCase {
  final ServiceRepository repository;

  AddExtinguisherToServiceUseCase(this.repository);

  Future<ServiceExtinguisherEntity> call({
    required int servicioId,
    required int extintorId,
    String? estadoInicial,
    String? observaciones,
  }) async {
    return await repository.addExtinguisherToService(
      servicioId: servicioId,
      extintorId: extintorId,
      estadoInicial: estadoInicial,
      observaciones: observaciones,
    );
  }
}
