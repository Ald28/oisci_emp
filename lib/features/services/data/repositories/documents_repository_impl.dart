import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/network_checker.dart';
import '../../domain/entities/cached_document_entity.dart';
import '../../domain/entities/doc_type.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_local_datasource.dart';
import '../datasources/documents_remote_datasource.dart';
import '../models/cached_document_model.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final NetworkChecker networkChecker;
  final DocumentsRemoteDataSource remote;
  final DocumentsLocalDataSource local;

  DocumentsRepositoryImpl({
    required this.networkChecker,
    required this.remote,
    required this.local,
  });

  @override
  Future<List<CachedDocumentEntity>> getForServicios(
    List<int> servicioIds,
  ) async {
    final cached = await local.getAllByServicioIds(servicioIds);

    final map = <String, CachedDocumentEntity>{};
    for (final c in cached) {
      map['${c.servicioId}_${c.docType.key}'] = c;
    }

    final result = <CachedDocumentEntity>[];
    for (final id in servicioIds) {
      for (final t in [DocType.inspeccionMensual, DocType.fotografico]) {
        result.add(
          map['${id}_${t.key}'] ??
              CachedDocumentEntity(servicioId: id, docType: t),
        );
      }
    }
    return result;
  }

  @override
  Future<CachedDocumentEntity> download({
    required int servicioId,
    required DocType type,
    required DateTime servicioUpdatedAt,
  }) async {
    final hasNet = await networkChecker.hasConnection;

    // Si no hay internet => devolver local si existe
    if (!hasNet) {
      final localDoc = await local.getByServicioAndType(servicioId, type.key);
      if (localDoc == null || !localDoc.isAvailableOffline) {
        throw Exception('Sin internet y no hay archivo descargado.');
      }
      return localDoc;
    }

    // Si existe y ya está actualizado (usamos servicio.updatedAt como “version”)
    final existing = await local.getByServicioAndType(servicioId, type.key);
    if (existing?.remoteUpdatedAt != null &&
        !servicioUpdatedAt.isAfter(existing!.remoteUpdatedAt!)) {
      return existing;
    }

    final bytes = type == DocType.inspeccionMensual
        ? await remote.downloadInspeccionMensualPdf(servicioId)
        : await remote.downloadFotograficoPdf(servicioId);

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/certificados');
    if (!await folder.exists()) await folder.create(recursive: true);

    final file = File('${folder.path}/${type.key}_$servicioId.pdf');
    await file.writeAsBytes(bytes, flush: true);

    final model = CachedDocumentModel(
      servicioId: servicioId,
      docType: type,
      filePath: file.path,
      remoteUpdatedAt: servicioUpdatedAt,
      downloadedAt: DateTime.now(),
      fileSize: bytes.length,
    );

    await local.upsert(model);
    return model;
  }
}
