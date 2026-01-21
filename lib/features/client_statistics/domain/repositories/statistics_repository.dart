import '../entities/extinguisher_stats_entity.dart';
import '../entities/service_stats_entity.dart';

/// Repositorio para estadísticas
abstract class StatisticsRepository {
  /// Obtener estadísticas de extintores por sede
  Future<ExtinguisherStatsEntity> getExtinguisherStatsBySedeId(int sedeId);

  /// Obtener estadísticas de servicios por sede y año
  Future<ServiceStatsEntity> getServiceStatsBySedeIdAndYear(
    int sedeId,
    int year,
  );
}
