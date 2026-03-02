import 'doc_type.dart';

class CachedDocumentEntity {
  final int servicioId;
  final DocType docType;
  final String? filePath;
  final DateTime? remoteUpdatedAt;
  final DateTime? downloadedAt;
  final int? fileSize;

  bool get isAvailableOffline => filePath != null && filePath!.isNotEmpty;

  const CachedDocumentEntity({
    required this.servicioId,
    required this.docType,
    this.filePath,
    this.remoteUpdatedAt,
    this.downloadedAt,
    this.fileSize,
  });
}
