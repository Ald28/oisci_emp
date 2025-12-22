import '../entities/service_order.dart';
import '../entities/service_type.dart';
import '../repositories/services_repository.dart';

/// UseCase: Detectar servicio en proceso
class GetServiceInProgressUseCase {
  final ServicesRepository repository;

  GetServiceInProgressUseCase(this.repository);

  Future<ServiceOrder?> call(ServiceType type) async {
    return await repository.getServiceInProgress(type);
  }
}

