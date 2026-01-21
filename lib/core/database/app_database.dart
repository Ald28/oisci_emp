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

    return openDatabase(
      path,
      version: 6, // Mantener versión 6, no necesitamos nuevas tablas
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

    // Tabla para servicios
    await db.execute('''
      CREATE TABLE servicio (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        dateStart TEXT NOT NULL,
        dateEnd TEXT,
        sincronizado INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        statusValid TEXT NOT NULL,
        historic TEXT,
        sedeId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        usuarioCreadorId INTEGER NOT NULL,
        usuarioActualizadorId INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER DEFAULT 1
      )
    ''');

    // Índice único para servicio id
    await db.execute('''
      CREATE UNIQUE INDEX idx_servicio_id ON servicio(id)
    ''');

    // Tabla para servicio_extintor
    await db.execute('''
      CREATE TABLE servicio_extintor (
        id INTEGER PRIMARY KEY,
        servicioId INTEGER NOT NULL,
        extintorId INTEGER NOT NULL,
        estadoInicial TEXT,
        estadoFinal TEXT,
        completado INTEGER DEFAULT 0,
        observaciones TEXT,
        usuarioCreadorId INTEGER NOT NULL,
        usuarioActualizadorId INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER DEFAULT 1,
        FOREIGN KEY (servicioId) REFERENCES servicio(id),
        FOREIGN KEY (extintorId) REFERENCES extintor(id)
      )
    ''');

    // Índice único para servicio_extintor id
    await db.execute('''
      CREATE UNIQUE INDEX idx_servicio_extintor_id ON servicio_extintor(id)
    ''');

    // Índice único para (servicioId, extintorId)
    await db.execute('''
      CREATE UNIQUE INDEX idx_servicio_extintor_unique ON servicio_extintor(servicioId, extintorId)
    ''');

    // Tabla para mantenimiento_detalle
    await db.execute('''
      CREATE TABLE mantenimiento_detalle (
        id INTEGER PRIMARY KEY,
        servicioExtintorId INTEGER NOT NULL,
        mantenimiento INTEGER DEFAULT 0,
        recarga INTEGER DEFAULT 0,
        agenteCarga TEXT,
        pruebaHidrostatica INTEGER DEFAULT 0,
        bajaExtintor INTEGER DEFAULT 0,
        motivoBaja TEXT,
        pintura INTEGER DEFAULT 0,
        recargaCartucho INTEGER DEFAULT 0,
        cambioPartes INTEGER DEFAULT 0,
        detallesCambioPartes TEXT,
        usuarioCreadorId INTEGER NOT NULL,
        usuarioActualizadorId INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER DEFAULT 1,
        FOREIGN KEY (servicioExtintorId) REFERENCES servicio_extintor(id)
      )
    ''');

    // Índice único para mantenimiento_detalle id
    await db.execute('''
      CREATE UNIQUE INDEX idx_mantenimiento_detalle_id ON mantenimiento_detalle(id)
    ''');

    // Índice único para servicioExtintorId
    await db.execute('''
      CREATE UNIQUE INDEX idx_mantenimiento_detalle_servicio_extintor ON mantenimiento_detalle(servicioExtintorId)
    ''');

    // Tabla para inspeccion_detalle
    await db.execute('''
      CREATE TABLE inspeccion_detalle (
        id INTEGER PRIMARY KEY,
        servicioExtintorId INTEGER NOT NULL,
        foto1Url TEXT,
        foto2Url TEXT,
        foto3Url TEXT,
        foto1Path TEXT,
        foto2Path TEXT,
        foto3Path TEXT,
        visibilidad TEXT,
        visualizacion TEXT,
        accesibilidad TEXT,
        altura TEXT,
        situacion TEXT,
        conservacion TEXT,
        inscripciones TEXT,
        recorrido TEXT,
        peso TEXT,
        observaciones TEXT,
        usuarioCreadorId INTEGER NOT NULL,
        usuarioActualizadorId INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        synced INTEGER DEFAULT 1,
        FOREIGN KEY (servicioExtintorId) REFERENCES servicio_extintor(id)
      )
    ''');

    // Índice único para inspeccion_detalle id
    await db.execute('''
      CREATE UNIQUE INDEX idx_inspeccion_detalle_id ON inspeccion_detalle(id)
    ''');

    // Índice único para servicioExtintorId
    await db.execute('''
      CREATE UNIQUE INDEX idx_inspeccion_detalle_servicio_extintor ON inspeccion_detalle(servicioExtintorId)
    ''');

    // Tabla para almacenar clientes
    await db.execute('''
      CREATE TABLE client (
        id INTEGER PRIMARY KEY,
        clientCode TEXT NOT NULL,
        razonSocial TEXT NOT NULL,
        ruc TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        userId INTEGER NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Índice único para client id
    await db.execute('''
      CREATE UNIQUE INDEX idx_client_id ON client(id)
    ''');

    // Índice para búsqueda rápida por RUC
    await db.execute('''
      CREATE INDEX idx_client_ruc ON client(ruc)
    ''');

    // Índice para búsqueda rápida por razón social
    await db.execute('''
      CREATE INDEX idx_client_razon_social ON client(razonSocial)
    ''');
  }

  /// Migración de la base de datos
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Agregar tablas de servicios
      await db.execute('''
        CREATE TABLE IF NOT EXISTS servicio (
          id INTEGER PRIMARY KEY,
          type TEXT NOT NULL,
          dateStart TEXT NOT NULL,
          dateEnd TEXT,
          sincronizado INTEGER DEFAULT 0,
          status TEXT NOT NULL,
          statusValid TEXT NOT NULL,
          historic TEXT,
          sedeId INTEGER NOT NULL,
          userId INTEGER NOT NULL,
          usuarioCreadorId INTEGER NOT NULL,
          usuarioActualizadorId INTEGER,
          createdAt TEXT,
          updatedAt TEXT,
          synced INTEGER DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_servicio_id ON servicio(id)
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS servicio_extintor (
          id INTEGER PRIMARY KEY,
          servicioId INTEGER NOT NULL,
          extintorId INTEGER NOT NULL,
          estadoInicial TEXT,
          estadoFinal TEXT,
          completado INTEGER DEFAULT 0,
          observaciones TEXT,
          usuarioCreadorId INTEGER NOT NULL,
          usuarioActualizadorId INTEGER,
          createdAt TEXT,
          updatedAt TEXT,
          synced INTEGER DEFAULT 1,
          FOREIGN KEY (servicioId) REFERENCES servicio(id),
          FOREIGN KEY (extintorId) REFERENCES extintor(id)
        )
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_servicio_extintor_id ON servicio_extintor(id)
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_servicio_extintor_unique ON servicio_extintor(servicioId, extintorId)
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS mantenimiento_detalle (
          id INTEGER PRIMARY KEY,
          servicioExtintorId INTEGER NOT NULL,
          mantenimiento INTEGER DEFAULT 0,
          recarga INTEGER DEFAULT 0,
          agenteCarga TEXT,
          pruebaHidrostatica INTEGER DEFAULT 0,
          bajaExtintor INTEGER DEFAULT 0,
          motivoBaja TEXT,
          pintura INTEGER DEFAULT 0,
          recargaCartucho INTEGER DEFAULT 0,
          cambioPartes INTEGER DEFAULT 0,
          usuarioCreadorId INTEGER NOT NULL,
          usuarioActualizadorId INTEGER,
          createdAt TEXT,
          updatedAt TEXT,
          synced INTEGER DEFAULT 1,
          FOREIGN KEY (servicioExtintorId) REFERENCES servicio_extintor(id)
        )
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_mantenimiento_detalle_id ON mantenimiento_detalle(id)
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_mantenimiento_detalle_servicio_extintor ON mantenimiento_detalle(servicioExtintorId)
      ''');
    }

    if (oldVersion < 3) {
      // Agregar campo detallesCambioPartes a mantenimiento_detalle
      await db.execute('''
        ALTER TABLE mantenimiento_detalle ADD COLUMN detallesCambioPartes TEXT
      ''');
    }

    if (oldVersion < 4) {
      // Agregar tabla inspeccion_detalle
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inspeccion_detalle (
          id INTEGER PRIMARY KEY,
          servicioExtintorId INTEGER NOT NULL,
          foto1Url TEXT,
          foto2Url TEXT,
          foto3Url TEXT,
          visibilidad TEXT,
          visualizacion TEXT,
          accesibilidad TEXT,
          altura TEXT,
          situacion TEXT,
          conservacion TEXT,
          inscripciones TEXT,
          recorrido TEXT,
          peso TEXT,
          observaciones TEXT,
          usuarioCreadorId INTEGER NOT NULL,
          usuarioActualizadorId INTEGER,
          createdAt TEXT,
          updatedAt TEXT,
          synced INTEGER DEFAULT 1,
          FOREIGN KEY (servicioExtintorId) REFERENCES servicio_extintor(id)
        )
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_inspeccion_detalle_id ON inspeccion_detalle(id)
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_inspeccion_detalle_servicio_extintor ON inspeccion_detalle(servicioExtintorId)
      ''');
    }

    if (oldVersion < 5) {
      // Agregar campos para paths locales de imágenes en inspeccion_detalle
      await db.execute('''
        ALTER TABLE inspeccion_detalle ADD COLUMN foto1Path TEXT
      ''');
      await db.execute('''
        ALTER TABLE inspeccion_detalle ADD COLUMN foto2Path TEXT
      ''');
      await db.execute('''
        ALTER TABLE inspeccion_detalle ADD COLUMN foto3Path TEXT
      ''');
    }

    if (oldVersion < 6) {
      // Agregar tabla de clientes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS client (
          id INTEGER PRIMARY KEY,
          clientCode TEXT NOT NULL,
          razonSocial TEXT NOT NULL,
          ruc TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          userId INTEGER NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_client_id ON client(id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_client_ruc ON client(ruc)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_client_razon_social ON client(razonSocial)
      ''');
    }
  }

  /// Cerrar la base de datos
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
