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
      version:
          14, // Versión 11: codeExtintor y serialNumberNFC, 12: foto4Url, 13: foto4Path, 14: nueva tala documentos
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
        codeExtintor TEXT,
        serialNumberNFC TEXT,
        type TEXT,
        capacity TEXT,
        agent TEXT,
        cylinderNumber TEXT,
        location TEXT,
        status TEXT,
        photo TEXT,
        photoPath TEXT,
        pressure TEXT,
        brand TEXT,
        model TEXT,
        rating TEXT,
        yearManufacture TEXT,
        dateHydrostatic TEXT,
        dateMaintenance TEXT,
        rechargeDate TEXT,
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
      CREATE INDEX idx_extintor_codeExtintor ON extintor(codeExtintor)
    ''');
    await db.execute('''
      CREATE INDEX idx_extintor_serialNumberNFC ON extintor(serialNumberNFC)
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
        foto4Url TEXT,
        foto1Path TEXT,
        foto2Path TEXT,
        foto3Path TEXT,
        foto4Path TEXT,
        accesibilidad TEXT,
        observaciones TEXT,
        ubicacion TEXT,
        instalacion TEXT,
        instrucciones TEXT,
        clasificacion TEXT,
        recarga TEXT,
        certificacion TEXT,
        presion TEXT,
        seguridad TEXT,
        estado TEXT,
        carga TEXT,
        soporte TEXT,
        activacion TEXT,
        manguera TEXT,
        boquilla TEXT,
        abrazadera TEXT,
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

    // Tabla para almacenar metadatos de sincronización
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Tabla para almacenar PDFs descargados (certificados/reportes) para uso offline
    await db.execute('''
      CREATE TABLE cached_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        servicioId INTEGER NOT NULL,
        docType TEXT NOT NULL,
        filePath TEXT,
        remoteUpdatedAt TEXT,
        downloadedAt TEXT,
        fileSize INTEGER,
        UNIQUE(servicioId, docType)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cached_documents_servicioId ON cached_documents(servicioId)
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
          foto4Url TEXT,
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
    }

    if (oldVersion < 7) {
      // Agregar campo photoPath a extintor para almacenar paths locales de imágenes
      // Usar try-catch para evitar errores si la columna ya existe
      try {
        await db.execute('''
          ALTER TABLE extintor ADD COLUMN photoPath TEXT
        ''');
      } catch (e) {
        // Si la columna ya existe, ignorar el error
        // Esto puede pasar si la migración se ejecuta múltiples veces
      }

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

    if (oldVersion < 8) {
      // Agregar tabla sync_metadata para sincronización incremental
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 9) {
      // Agregar nuevos campos a extintor
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN pressure TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN brand TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN model TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN rating TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE extintor ADD COLUMN yearManufacture TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE extintor ADD COLUMN dateHydrostatic TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE extintor ADD COLUMN dateMaintenance TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }

      // Agregar nuevos campos a inspeccion_detalle
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN ubicacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN acceso TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN fijacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute('ALTER TABLE inspeccion_detalle ADD COLUMN uso TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN clase TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN recarga TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN hidrostatica TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN presion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN precinto TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN cilindro TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN carga TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN soporte TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN manija TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN manguera TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN tobera TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN abrazadera TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
    }

    if (oldVersion < 10) {
      // Agregar rechargeDate a extintor (siguiendo el patrón de versiones anteriores)
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN rechargeDate TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }

      // Agregar nuevos campos a inspeccion_detalle (siguiendo el patrón de versión 9)
      // Los campos eliminados (visibilidad, visualizacion, acceso, altura, etc.)
      // permanecerán en la base de datos pero no se usarán
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN instalacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN instrucciones TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN clasificacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN certificacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN seguridad TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN estado TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN activacion TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN boquilla TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
    }

    if (oldVersion < 11) {
      // Agregar columnas codeExtintor y serialNumberNFC
      try {
        await db.execute('ALTER TABLE extintor ADD COLUMN codeExtintor TEXT');
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      try {
        await db.execute(
          'ALTER TABLE extintor ADD COLUMN serialNumberNFC TEXT',
        );
      } catch (e) {
        // Ignorar si la columna ya existe
      }
      // Migrar valor previo a serialNumberNFC (solo si la tabla tenía columna legacy)
      try {
        await db.execute(
          'UPDATE extintor SET serialNumberNFC = serialNumber WHERE serialNumberNFC IS NULL AND serialNumber IS NOT NULL',
        );
      } catch (e) {
        // Ignorar si la tabla no tenía la columna legacy (instalación nueva)
      }
    }

    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE inspeccion_detalle ADD COLUMN foto4Url TEXT',
      );
    }

    if (oldVersion < 13) {
      try {
        await db.execute(
          'ALTER TABLE inspeccion_detalle ADD COLUMN foto4Path TEXT',
        );
      } catch (e) {
        // Ignorar si ya existe
      }
    }

    if (oldVersion < 14) {
      await db.execute('''
          CREATE TABLE IF NOT EXISTS cached_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            servicioId INTEGER NOT NULL,
            docType TEXT NOT NULL,
            filePath TEXT,
            remoteUpdatedAt TEXT,
            downloadedAt TEXT,
            fileSize INTEGER,
            UNIQUE(servicioId, docType)
          )
        ''');

      await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cached_documents_servicioId ON cached_documents(servicioId)
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
