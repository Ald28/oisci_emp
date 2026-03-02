import '../entities/cached_document_entity.dart';
import '../entities/doc_type.dart';

abstract class DocumentsRepository {
  Future<List<CachedDocumentEntity>> getForServicios(List<int> servicioIds);

  Future<CachedDocumentEntity> download({
    required int servicioId,
    required DocType type,
    required DateTime servicioUpdatedAt,
  });
}
