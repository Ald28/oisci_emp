import '../entities/cached_document_entity.dart';
import '../entities/doc_type.dart';
import '../repositories/documents_repository.dart';

class DownloadDocumentUseCase {
  final DocumentsRepository repo;
  DownloadDocumentUseCase(this.repo);

  Future<CachedDocumentEntity> call({
    required int servicioId,
    required DocType type,
    required DateTime servicioUpdatedAt,
  }) {
    return repo.download(
      servicioId: servicioId,
      type: type,
      servicioUpdatedAt: servicioUpdatedAt,
    );
  }
}
