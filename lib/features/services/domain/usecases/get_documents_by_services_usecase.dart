import '../entities/cached_document_entity.dart';
import '../repositories/documents_repository.dart';

class GetDocumentsByServicesUseCase {
  final DocumentsRepository repo;
  GetDocumentsByServicesUseCase(this.repo);

  Future<List<CachedDocumentEntity>> call(List<int> servicioIds) {
    return repo.getForServicios(servicioIds);
  }
}
