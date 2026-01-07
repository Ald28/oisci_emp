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

    // Tabla para almacenar sedes (según schema de Prisma)
    await db.execute('''
      CREATE TABLE sede (
        id INTEGER PRIMARY KEY,
        name_sede TEXT NOT NULL,
        address TEXT NOT NULL,
        manager_name TEXT NOT NULL,
        manager_phone TEXT NOT NULL,
        manager_email TEXT NOT NULL,
        city TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        clientId INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Índice único para sede id
    await db.execute('''
      CREATE UNIQUE INDEX idx_sede_id ON sede(id)
    ''');

    // Tabla para almacenar extintores (según schema de Prisma)
    await db.execute('''
      CREATE TABLE extintor (
        id INTEGER PRIMARY KEY,
        codeNFC TEXT,
        serialNumber TEXT,
        type TEXT,
        capacity TEXT,
        agent TEXT,
        cylinderNumber TEXT,
        location TEXT,
        status TEXT,
        photo TEXT,
        sedeId INTEGER NOT NULL,
        usuarioCreadorId INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Índices para búsquedas rápidas
    await db.execute('''
      CREATE UNIQUE INDEX idx_extintor_id ON extintor(id)
    ''');

    await db.execute('''
      CREATE INDEX idx_extintor_codeNFC ON extintor(codeNFC)
    ''');

    await db.execute('''
      CREATE INDEX idx_extintor_serialNumber ON extintor(serialNumber)
    ''');

    // Tabla para cola de sincronización (extintores pendientes)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastSyncError TEXT,
        syncAttempts INTEGER DEFAULT 0,
        lastSyncAttempt TEXT
      )
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
