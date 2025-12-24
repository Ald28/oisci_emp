import '../../domain/repositories/sede_repository.dart';
import '../../domain/entities/sede.dart';
import '../datasources/sede_datasource.dart';
import '../datasources/http_sede_datasource.dart';

class SedeRepositoryImpl implements SedeRepository {
  final SedeDataSource dataSource;

  SedeRepositoryImpl({SedeDataSource? dataSource})
      : dataSource = dataSource ?? HttpSedeDataSource();

  @override
  Future<List<Sede>> getSedes() async {
    return await dataSource.getSedes();
  }
}

