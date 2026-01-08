import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

/// Use case: Crear servicio (Etapa 1)
class CreateServiceUseCase {
  final ServiceRepository repository;

  CreateServiceUseCase(this.repository);

  Future<ServiceEntity> call({
    required String type,
    required DateTime dateStart,
    required int sedeId,
    required int userId,
  }) async {
    return await repository.createService(
      type: type,
      dateStart: dateStart,
      sedeId: sedeId,
      userId: userId,
    );
  }
}
