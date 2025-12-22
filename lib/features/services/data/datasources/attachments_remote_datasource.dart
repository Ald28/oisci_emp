import '../models/attachment_dto.dart';

/// Datasource remoto: API para adjuntos/evidencias
abstract class AttachmentsRemoteDataSource {
  /// Subir foto/evidencia
  Future<AttachmentDto> uploadAttachment({
    required String serviceId,
    required String filePath,
    required String type, // 'photo', 'document'
  });

  /// Obtener adjuntos de un servicio
  Future<List<AttachmentDto>> getAttachments(String serviceId);

  /// Eliminar adjunto
  Future<void> deleteAttachment(String attachmentId);
}

