import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/services/data/datasources/http_sede_datasource.dart';
import '../../features/services/data/datasources/local_sede_datasource.dart';

/// Servicio para sincronizar sedes: descargar del servidor y guardar localmente
class SedeSyncService {
  final HttpSedeDataSource _httpDataSource;
  final LocalSedeDataSource _localDataSource;

  SedeSyncService({
    HttpSedeDataSource? httpDataSource,
    LocalSedeDataSource? localDataSource,
  })  : _httpDataSource = httpDataSource ?? HttpSedeDataSource(),
        _localDataSource = localDataSource ?? LocalSedeDataSource();

  /// Sincronizar sedes: descargar del servidor y guardar localmente
  /// Retorna true si se sincronizaron exitosamente, false si no hay internet
  Future<bool> syncSedes() async {
    // Verificar conexión a internet
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return false; // No hay internet, no se puede sincronizar
    }

    try {
      // Obtener sedes del servidor
      final sedes = await _httpDataSource.getSedes();

      // Guardar localmente
      await _localDataSource.saveSedes(sedes);

      return true;
    } catch (e) {
      // Si falla, retornar false
      return false;
    }
  }

  /// Verificar si hay sedes guardadas localmente
  Future<bool> hasLocalSedes() async {
    return await _localDataSource.hasSedes();
  }

  /// Obtener cantidad de sedes guardadas localmente
  Future<int> getLocalSedesCount() async {
    return await _localDataSource.getSedesCount();
  }
}

