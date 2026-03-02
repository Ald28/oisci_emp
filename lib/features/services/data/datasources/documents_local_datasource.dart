import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/cached_document_model.dart';

class DocumentsLocalDataSource {
  Future<Database> get _db async => AppDatabase.database;

  Future<void> upsert(CachedDocumentModel doc) async {
    final db = await _db;
    await db.insert(
      'cached_documents',
      doc.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CachedDocumentModel?> getByServicioAndType(
    int servicioId,
    String docType,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'cached_documents',
      where: 'servicioId = ? AND docType = ?',
      whereArgs: [servicioId, docType],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CachedDocumentModel.fromJson(rows.first);
  }

  Future<List<CachedDocumentModel>> getAllByServicioIds(
    List<int> servicioIds,
  ) async {
    if (servicioIds.isEmpty) return [];
    final db = await _db;
    final inArgs = List.filled(servicioIds.length, '?').join(',');
    final rows = await db.query(
      'cached_documents',
      where: 'servicioId IN ($inArgs)',
      whereArgs: servicioIds,
    );
    return rows.map(CachedDocumentModel.fromJson).toList();
  }
}
