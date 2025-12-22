import '../entities/service_order.dart';
import '../entities/service_type.dart';
import '../repositories/services_repository.dart';

/// UseCase: Iniciar servicio para extintor
class StartServiceUseCase {
  final ServicesRepository repository;

  StartServiceUseCase(this.repository);

  Future<ServiceOrder> call({
    required String extinguisherId,
    required ServiceType type,
  }) async {
    return await repository.startService(
      extinguisherId: extinguisherId,
      type: type,
    );
  }
}

