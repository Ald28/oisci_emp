import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/sede_repository.dart';
import '../../domain/entities/sede.dart';
import '../datasources/sede_datasource.dart';
import '../datasources/http_sede_datasource.dart';
import '../datasources/local_sede_datasource.dart';
import '../models/sede_model.dart';

class SedeRepositoryImpl implements SedeRepository {
  final SedeDataSource? remoteDataSource;
  final LocalSedeDataSource? localDataSource;

  SedeRepositoryImpl({
    SedeDataSource? remoteDataSource,
    LocalSedeDataSource? localDataSource,
  }) : remoteDataSource = remoteDataSource ?? HttpSedeDataSource(),
       localDataSource = localDataSource ?? LocalSedeDataSource();

  /// Obtener el datasource apropiado según la conectividad
  Future<SedeDataSource> _getDataSource({required bool preferLocal}) async {
    if (preferLocal) {
      return localDataSource!;
    }

    final hasInternet = await InternetConnectionChecker().hasConnection;
    return hasInternet ? remoteDataSource! : localDataSource!;
  }

  @override
  Future<List<Sede>> getSedes() async {
    // Determinar qué datasource usar según conectividad
    final hasInternet = await InternetConnectionChecker().hasConnection;
    final dataSource = await _getDataSource(preferLocal: !hasInternet);

    final sedes = await dataSource.getSedes();

    // Si hay internet y se obtuvieron sedes del servidor, guardarlas localmente
    if (hasInternet && sedes.isNotEmpty) {
      final sedesModels = sedes.map((s) => s as SedeModel).toList();
      await localDataSource!.saveSedes(sedesModels);
    }

    return sedes;
  }
}
