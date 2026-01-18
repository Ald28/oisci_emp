import '../repositories/client_repository.dart';

/// Use case: Buscar clientes con paginación
class SearchClientsUseCase {
  final ClientRepository repository;

  SearchClientsUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await repository.searchClients(
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }
}
