import '../entities/attachment.dart';

/// UseCase: Subir fotos/evidencias
class UploadAttachmentUseCase {
  // TODO: Implementar con AttachmentsRepository
  Future<Attachment> call({
    required String serviceId,
    required String filePath,
    required String type,
  }) async {
    throw UnimplementedError();
  }
}

