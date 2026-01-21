import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/entities/extinguisher_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import '../datasources/http_statistics_datasource.dart';
import '../datasources/local_statistics_datasource.dart';

/// Implementación del repositorio de estadísticas
/// Online: Usa endpoints del backend (mejor rendimiento y consistencia)
/// Offline: Calcula desde las tablas existentes en SQLite
class StatisticsRepositoryImpl implements StatisticsRepository {
  final HttpStatisticsDataSource _httpDataSource;
  final LocalStatisticsDataSource _localDataSource;

  StatisticsRepositoryImpl({
    HttpStatisticsDataSource? httpDataSource,
    LocalStatisticsDataSource? localDataSource,
  })  : _httpDataSource = httpDataSource ?? HttpStatisticsDataSource(),
        _localDataSource = localDataSource ?? LocalStatisticsDataSource();

  Future<bool> _hasInternet() async {
    return await InternetConnectionChecker().hasConnection;
  }

  @override
  Future<ExtinguisherStatsEntity> getExtinguisherStatsBySedeId(int sedeId) async {
    final hasInternet = await _hasInternet();

    // Si hay internet, intentar obtener primero desde el backend
    if (hasInternet) {
      try {
        final remoteStats = await _httpDataSource.getExtinguisherStatsBySedeId(sedeId);
        return remoteStats;
      } catch (_) {
        // Si falla HTTP, continuamos con el cálculo local como fallback
      }
    }

    // Sin internet o si falló el request, calcular desde la base de datos local
    return await _localDataSource.calculateExtinguisherStatsBySedeId(sedeId);
  }

  @override
  Future<ServiceStatsEntity> getServiceStatsBySedeIdAndYear(
    int sedeId,
    int year,
  ) async {
    final hasInternet = await _hasInternet();

    // Si hay internet, intentar obtener primero desde el backend
    if (hasInternet) {
      try {
        final remoteStats = await _httpDataSource.getServiceStatsBySedeIdAndYear(
          sedeId,
          year,
        );
        return remoteStats;
      } catch (_) {
        // Si falla HTTP, continuamos con el cálculo local como fallback
      }
    }

    // Sin internet o si falló el request, calcular desde la base de datos local
    return await _localDataSource.calculateServiceStatsBySedeIdAndYear(
      sedeId,
      year,
    );
  }
}
