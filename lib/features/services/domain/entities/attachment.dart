/// Entidad: Evidencia/Adjunto (fotos, documentos)
class Attachment {
  final String id;
  final String serviceId;
  final String type; // 'photo', 'document', etc.
  final String url;
  final String? localPath;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.serviceId,
    required this.type,
    required this.url,
    this.localPath,
    required this.createdAt,
  });
}

