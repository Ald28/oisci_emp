import '../entities/extinguisher_entity.dart';
import '../repositories/extinguisher_repository.dart';

/// Use Case: Buscar extintor
class SearchExtinguisherUseCase {
  final ExtinguisherRepository repository;

  SearchExtinguisherUseCase(this.repository);

  Future<Extinguisher?> call(String searchTerm, {int? sedeId}) async {
    if (searchTerm.trim().isEmpty) {
      return null;
    }
    return await repository.searchExtinguisher(searchTerm.trim(), sedeId: sedeId);
  }
}
