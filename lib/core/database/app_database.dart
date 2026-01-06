import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Base de datos SQLite para almacenar datos del usuario y otros datos locales
class AppDatabase {
  static Database? _db;

  /// Obtener instancia de la base de datos
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  /// Inicializar la base de datos
  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'oisci_app.db');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Crear las tablas necesarias
  static Future<void> _onCreate(Database db, int version) async {
    // Tabla para almacenar datos del usuario logeado
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        accessToken TEXT,
        refreshToken TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Índice único para userId (solo un usuario puede estar guardado)
    await db.execute('''
      CREATE UNIQUE INDEX idx_user_userId ON user(userId)
    ''');
  }

  /// Cerrar la base de datos
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
