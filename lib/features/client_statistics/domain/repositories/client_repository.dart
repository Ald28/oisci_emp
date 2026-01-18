/// Repositorio de clientes (Domain Layer)
abstract class ClientRepository {
  /// Buscar clientes con paginación
  Future<Map<String, dynamic>> searchClients({
    String? search,
    int page = 1,
    int pageSize = 10,
  });
}
