import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/extinguisher_repository.dart';
import '../../domain/entities/extinguisher.dart';
import '../datasources/extinguisher_datasource.dart';
import '../datasources/http_extinguisher_datasource.dart';
import '../datasources/local_extinguisher_datasource.dart';

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
    // La búsqueda siempre requiere internet (los extintores pendientes no se pueden buscar)
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return null; // Sin internet no se puede buscar
    }

    final dataSource = await _getDataSource(preferLocal: false);
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
