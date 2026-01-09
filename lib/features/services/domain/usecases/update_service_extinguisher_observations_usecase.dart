import '../repositories/service_repository.dart';

/// Use case: Actualizar observaciones de ServicioExtintor
class UpdateServiceExtinguisherObservationsUseCase {
  final ServiceRepository repository;

  UpdateServiceExtinguisherObservationsUseCase(this.repository);

  Future<void> call({
    required int servicioExtintorId,
    required String? observaciones,
  }) async {
    await repository.updateServiceExtinguisherObservations(
      servicioExtintorId: servicioExtintorId,
      observaciones: observaciones,
    );
  }
}
