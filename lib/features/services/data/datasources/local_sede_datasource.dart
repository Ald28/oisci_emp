import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/sede_model.dart';
import 'sede_datasource.dart';

/// DataSource local usando SQLite para almacenar sedes
class LocalSedeDataSource implements SedeDataSource {
  @override
  Future<List<SedeModel>> getSedes() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'sede',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'name_sede ASC',
    );

    return result.map((map) => SedeModel.fromMap(map)).toList();
  }

  /// Guardar sedes localmente (desde el servidor)
  Future<void> saveSedes(List<SedeModel> sedes) async {
    final db = await AppDatabase.database;

    // Iniciar transacción para mejor rendimiento
    await db.transaction((txn) async {
      // Limpiar sedes existentes
      await txn.delete('sede');

      // Guardar nuevas sedes usando INSERT OR REPLACE
      for (final sede in sedes) {
        await txn.insert(
          'sede',
          sede.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Verificar si hay sedes guardadas localmente
  Future<bool> hasSedes() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sede');
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Obtener cantidad de sedes guardadas
  Future<int> getSedesCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sede');
    return result.first['count'] as int;
  }
}
