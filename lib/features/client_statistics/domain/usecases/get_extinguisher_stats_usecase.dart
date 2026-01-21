import '../repositories/statistics_repository.dart';
import '../entities/extinguisher_stats_entity.dart';

/// Use case: Obtener estadísticas de extintores por sede
class GetExtinguisherStatsUseCase {
  final StatisticsRepository repository;

  GetExtinguisherStatsUseCase(this.repository);

  Future<ExtinguisherStatsEntity> call(int sedeId) async {
    return await repository.getExtinguisherStatsBySedeId(sedeId);
  }
}
