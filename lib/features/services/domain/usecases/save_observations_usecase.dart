import '../repositories/services_repository.dart';

/// UseCase: Guardar observaciones
class SaveObservationsUseCase {
  final ServicesRepository repository;

  SaveObservationsUseCase(this.repository);

  Future<void> call({
    required String serviceId,
    required String observations,
  }) async {
    return await repository.saveObservations(
      serviceId: serviceId,
      observations: observations,
    );
  }
}

