import '../repositories/statistics_repository.dart';
import '../entities/service_stats_entity.dart';

/// Use case: Obtener estadísticas de servicios por sede y año
class GetServiceStatsUseCase {
  final StatisticsRepository repository;

  GetServiceStatsUseCase(this.repository);

  Future<ServiceStatsEntity> call(int sedeId, int year) async {
    return await repository.getServiceStatsBySedeIdAndYear(sedeId, year);
  }
}
