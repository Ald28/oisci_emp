import '../entities/extinguisher.dart';
import '../repositories/extinguisher_repository.dart';

/// Use Case: Buscar extintor
class SearchExtinguisherUseCase {
  final ExtinguisherRepository repository;

  SearchExtinguisherUseCase(this.repository);

  /// Buscar extintor por código, número de serie o NFC UID
  /// Retorna null si no se encuentra
  Future<Extinguisher?> call(String query) async {
    if (query.trim().isEmpty) {
      return null;
    }
    return await repository.searchExtinguisher(query.trim());
  }
}

