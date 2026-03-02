import '../../domain/entities/cached_document_entity.dart';
import '../../domain/entities/doc_type.dart';

class CachedDocumentModel extends CachedDocumentEntity {
  const CachedDocumentModel({
    required super.servicioId,
    required super.docType,
    super.filePath,
    super.remoteUpdatedAt,
    super.downloadedAt,
    super.fileSize,
  });

  Map<String, dynamic> toJson() => {
    'servicioId': servicioId,
    'docType': docType.key,
    'filePath': filePath,
    'remoteUpdatedAt': remoteUpdatedAt?.toIso8601String(),
    'downloadedAt': downloadedAt?.toIso8601String(),
    'fileSize': fileSize,
  };

  static CachedDocumentModel fromJson(Map<String, dynamic> json) {
    final key = json['docType'] as String;
    final type = key == 'INSPECCION_MENSUAL'
        ? DocType.inspeccionMensual
        : DocType.fotografico;

    return CachedDocumentModel(
      servicioId: json['servicioId'] as int,
      docType: type,
      filePath: json['filePath'] as String?,
      remoteUpdatedAt: json['remoteUpdatedAt'] != null
          ? DateTime.tryParse(json['remoteUpdatedAt'] as String)
          : null,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String)
          : null,
      fileSize: json['fileSize'] as int?,
    );
  }
}
