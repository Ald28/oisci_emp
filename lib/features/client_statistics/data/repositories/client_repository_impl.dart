import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_datasource.dart';
import '../datasources/http_client_datasource.dart';

/// Implementación del repositorio de clientes
class ClientRepositoryImpl implements ClientRepository {
  final ClientDataSource _httpDataSource;

  ClientRepositoryImpl({
    ClientDataSource? httpDataSource,
  }) : _httpDataSource = httpDataSource ?? HttpClientDataSource();

  Future<bool> _hasInternet() async {
    return await InternetConnectionChecker().hasConnection;
  }

  @override
  Future<Map<String, dynamic>> searchClients({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar obtener del servidor
        return await _httpDataSource.searchClients(
          search: search,
          page: page,
          pageSize: pageSize,
        );
      } catch (e) {
        // Si falla, retornar lista vacía (los clientes no se guardan offline)
        return {
          'data': <dynamic>[],
          'pagination': {
            'page': page,
            'pageSize': pageSize,
            'total': 0,
            'totalPages': 0,
          },
        };
      }
    } else {
      // Sin internet, retornar lista vacía
      return {
        'data': <dynamic>[],
        'pagination': {
          'page': page,
          'pageSize': pageSize,
          'total': 0,
          'totalPages': 0,
        },
      };
    }
  }
}
