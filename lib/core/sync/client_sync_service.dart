import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dio/dio.dart';
import '../../features/client_statistics/data/datasources/local_client_datasource.dart';
import '../../features/client_statistics/data/datasources/http_client_datasource.dart';
import '../../features/client_statistics/data/models/client_model.dart';

/// Servicio para sincronizar clientes: descargar del servidor y guardar localmente
class ClientSyncService {
  final LocalClientDataSource _localDataSource;
  final HttpClientDataSource _httpDataSource;

  ClientSyncService({
    LocalClientDataSource? localDataSource,
    HttpClientDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalClientDataSource(),
       _httpDataSource = httpDataSource ?? HttpClientDataSource();

  /// Sincronizar clientes: descargar del servidor y guardar localmente
  /// Retorna true si se sincronizaron exitosamente, false si no hay internet
  Future<bool> syncClients() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return false;
    }

    try {
      // Obtener todos los clientes del servidor
      // El endpoint /users/clients retorna { data: [...], pagination: {...} }
      List<ClientModel> allClients = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final result = await _httpDataSource.searchClients(
          search: null, // Obtener todos sin filtro
          page: currentPage,
          pageSize: 100, // Obtener más por página para reducir llamadas
        );

        final clientsList = result['data'] as List<dynamic>;
        // Los clientes ya vienen como ClientModel del HttpClientDataSource
        final clients = clientsList.whereType<ClientModel>().toList();

        allClients.addAll(clients);

        final pagination = result['pagination'] as Map<String, dynamic>;
        totalPages = pagination['totalPages'] as int? ?? 1;
        currentPage++;
      } while (currentPage <= totalPages);

      // Guardar todos los clientes localmente (sincronización completa, reemplazar todos)
      await _localDataSource.saveClients(allClients, replaceAll: true);

      return true;
    } on DioException catch (e) {
      // Capturar errores de Dio y lanzar con mensaje más claro
      String errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        errorMessage =
            errorData['message'] as String? ??
            errorData['error'] as String? ??
            'Error al descargar clientes';
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data as String;
      } else {
        errorMessage =
            'Error al descargar clientes: ${e.message ?? 'Error desconocido'}';
      }

      // Si es un error 404, el endpoint no existe
      if (e.response?.statusCode == 404) {
        errorMessage =
            'Endpoint no encontrado. Verifique que el backend tenga el endpoint /users/clients';
      }

      throw Exception(errorMessage);
    } catch (e) {
      // Relanzar otros errores con el mensaje original
      rethrow;
    }
  }

  /// Verificar si hay clientes guardados localmente
  Future<bool> hasLocalClients() async {
    return await _localDataSource.hasClients();
  }

  /// Obtener cantidad de clientes guardados localmente
  Future<int> getLocalClientsCount() async {
    return await _localDataSource.getClientsCount();
  }
}
