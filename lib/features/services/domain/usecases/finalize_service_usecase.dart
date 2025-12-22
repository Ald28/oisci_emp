import '../repositories/services_repository.dart';

/// UseCase: Finalizar servicio + confirmar
class FinalizeServiceUseCase {
  final ServicesRepository repository;

  FinalizeServiceUseCase(this.repository);

  Future<void> call({
    required String serviceId,
    required List<String> completedItems,
    String? observations,
  }) async {
    return await repository.finalizeService(
      serviceId: serviceId,
      completedItems: completedItems,
      observations: observations,
    );
  }
}

