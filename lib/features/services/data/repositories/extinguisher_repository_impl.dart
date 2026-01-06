import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/extinguisher_repository.dart';
import '../../domain/entities/extinguisher.dart';
import '../datasources/extinguisher_datasource.dart';
import '../datasources/http_extinguisher_datasource.dart';
import '../datasources/local_extinguisher_datasource.dart';
import '../models/extinguisher_model.dart';

class ExtinguisherRepositoryImpl implements ExtinguisherRepository {
  final ExtinguisherDataSource? remoteDataSource;
  final ExtinguisherDataSource? localDataSource;

  ExtinguisherRepositoryImpl({
    ExtinguisherDataSource? remoteDataSource,
    ExtinguisherDataSource? localDataSource,
  }) : remoteDataSource = remoteDataSource ?? HttpExtinguisherDataSource(),
       localDataSource = localDataSource ?? LocalExtinguisherDataSource();

  /// Obtener el datasource apropiado según la conectividad
  Future<ExtinguisherDataSource> _getDataSource({
    required bool preferLocal,
  }) async {
    if (preferLocal) {
      return localDataSource!;
    }

    final hasInternet = await InternetConnectionChecker().hasConnection;
    return hasInternet ? remoteDataSource! : localDataSource!;
  }

  @override
  Future<Extinguisher?> searchExtinguisher(String searchTerm) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    // Si hay internet, buscar primero en el servidor
    if (hasInternet) {
      final remoteDataSource = await _getDataSource(preferLocal: false);
      final extinguisher = await remoteDataSource.searchExtinguisher(
        searchTerm,
      );

      // Si se encontró en el servidor, guardarlo localmente para uso offline
      if (extinguisher != null &&
          localDataSource is LocalExtinguisherDataSource) {
        await (localDataSource as LocalExtinguisherDataSource).saveExtinguisher(
          extinguisher as ExtinguisherModel,
        );
      }

      // Si se encontró en el servidor, retornarlo
      if (extinguisher != null) {
        return extinguisher;
      }

      // Si no se encontró en el servidor, buscar también en local (puede estar pendiente de sincronización)
      if (localDataSource != null &&
          localDataSource is LocalExtinguisherDataSource) {
        final localExtinguisher =
            await (localDataSource as LocalExtinguisherDataSource)
                .searchExtinguisher(searchTerm);
        if (localExtinguisher != null) {
          return localExtinguisher;
        }
      }

      // No se encontró ni en servidor ni en local
      return null;
    }

    // Sin internet, buscar solo en SQLite (incluye sincronizados y pendientes)
    final dataSource = await _getDataSource(preferLocal: true);
    return await dataSource.searchExtinguisher(searchTerm);
  }

  @override
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data) async {
    // Determinar qué datasource usar según conectividad
    final hasInternet = await InternetConnectionChecker().hasConnection;
    final dataSource = await _getDataSource(preferLocal: !hasInternet);

    return await dataSource.createExtinguisher(data);
  }
}
