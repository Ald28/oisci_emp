/// Interfaz para datasource de clientes
abstract class ClientDataSource {
  /// Buscar clientes con paginación
  Future<Map<String, dynamic>> searchClients({
    String? search,
    int page = 1,
    int pageSize = 10,
  });
}
