import '../../domain/repositories/extinguisher_repository.dart';
import '../../domain/entities/extinguisher.dart';
import '../datasources/extinguisher_datasource.dart';
import '../datasources/http_extinguisher_datasource.dart';

class ExtinguisherRepositoryImpl implements ExtinguisherRepository {
  final ExtinguisherDataSource dataSource;

  ExtinguisherRepositoryImpl({ExtinguisherDataSource? dataSource})
      : dataSource = dataSource ?? HttpExtinguisherDataSource();

  @override
  Future<Extinguisher?> searchExtinguisher(String searchTerm) async {
    return await dataSource.searchExtinguisher(searchTerm);
  }

  @override
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data) async {
    return await dataSource.createExtinguisher(data);
  }
}

