import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_datasource.dart';
import '../datasources/http_client_datasource.dart';
import '../datasources/local_client_datasource.dart';
import '../models/client_model.dart';

/// Implementación del repositorio de clientes
class ClientRepositoryImpl implements ClientRepository {
  final ClientDataSource _httpDataSource;
  final LocalClientDataSource _localDataSource;

  ClientRepositoryImpl({
    ClientDataSource? httpDataSource,
    LocalClientDataSource? localDataSource,
  }) : _httpDataSource = httpDataSource ?? HttpClientDataSource(),
       _localDataSource = localDataSource ?? LocalClientDataSource();

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
        final result = await _httpDataSource.searchClients(
          search: search,
          page: page,
          pageSize: pageSize,
        );

        // Guardar los clientes obtenidos localmente para uso offline
        final clientsList = result['data'] as List<dynamic>;
        if (clientsList.isNotEmpty) {
          // Los clientes ya vienen como ClientModel del HttpClientDataSource
          // Solo necesitamos extraerlos y guardarlos
          final clients = clientsList.whereType<ClientModel>().toList();

          if (clients.isNotEmpty) {
            // Guardar los clientes obtenidos en local (merge, no reemplazar todos)
            // Esto permite que estén disponibles offline sin perder otros clientes
            await _localDataSource.saveClients(clients, replaceAll: false);
          }
        }

        // Retornar el resultado tal cual (ya contiene ClientModel en data)
        return result;
      } catch (e) {
        // Si falla, intentar obtener de SQLite
        return await _localDataSource.searchClients(
          search: search,
          page: page,
          pageSize: pageSize,
        );
      }
    } else {
      // Sin internet, obtener de SQLite
      return await _localDataSource.searchClients(
        search: search,
        page: page,
        pageSize: pageSize,
      );
    }
  }
}
