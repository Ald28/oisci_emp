import '../../domain/repositories/services_repository.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/checklist_result.dart';
import '../../domain/entities/service_type.dart';
import '../datasources/services_remote_datasource.dart';

/// Implementación del repositorio de servicios
class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;

  ServicesRepositoryImpl(this.remoteDataSource);

  @override
  Future<ServiceOrder> startService({
    required String extinguisherId,
    required ServiceType type,
  }) async {
    // TODO: Implementar conversión DTO -> Entity
    throw UnimplementedError();
  }

  @override
  Future<ServiceOrder?> getServiceInProgress(ServiceType type) async {
    // TODO: Implementar
    throw UnimplementedError();
  }

  @override
  Future<void> saveChecklist({
    required String serviceId,
    required List<ChecklistResult> results,
  }) async {
    // TODO: Implementar
    throw UnimplementedError();
  }

  @override
  Future<void> saveObservations({
    required String serviceId,
    required String observations,
  }) async {
    // TODO: Implementar
    throw UnimplementedError();
  }

  @override
  Future<void> finalizeService({
    required String serviceId,
    required List<String> completedItems,
    String? observations,
  }) async {
    // TODO: Implementar
    throw UnimplementedError();
  }
}

