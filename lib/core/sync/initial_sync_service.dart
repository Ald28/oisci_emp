import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'extinguisher_sync_service.dart';
import 'sede_sync_service.dart';
import 'client_sync_service.dart';
import '../database/app_database.dart';

/// Servicio para descarga inicial de datos después del primer login
class InitialSyncService {
  final ExtinguisherSyncService _extinguisherSyncService;
  final SedeSyncService _sedeSyncService;
  final ClientSyncService _clientSyncService;

  InitialSyncService({
    ExtinguisherSyncService? extinguisherSyncService,
    SedeSyncService? sedeSyncService,
    ClientSyncService? clientSyncService,
  }) : _extinguisherSyncService =
           extinguisherSyncService ?? ExtinguisherSyncService(),
       _sedeSyncService = sedeSyncService ?? SedeSyncService(),
       _clientSyncService = clientSyncService ?? ClientSyncService();

  /// Verificar si es necesario hacer descarga inicial
  /// Retorna true si no hay datos locales o hay muy pocos
  Future<bool> needsInitialSync() async {
    final db = await AppDatabase.database;

    // Verificar si hay sedes guardadas
    final sedesCount = await db.rawQuery('SELECT COUNT(*) as count FROM sede');
    final sedes = sedesCount.first['count'] as int? ?? 0;

    // Verificar si hay extintores guardados (sincronizados, no pendientes)
    final extintoresCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM extintor WHERE synced = 1',
    );
    final extintores = extintoresCount.first['count'] as int? ?? 0;

    // Verificar si hay clientes guardados
    final clientesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM client',
    );
    final clientes = clientesCount.first['count'] as int? ?? 0;

    // Si no hay sedes, extintores o clientes, necesita descarga inicial
    return sedes == 0 || extintores == 0 || clientes == 0;
  }

  /// Realizar descarga inicial de todos los datos
  /// Retorna un mapa con el progreso: {'step': nombre, 'progress': 0.0-1.0}
  Stream<Map<String, dynamic>> syncInitialData() async* {
    // Verificar conexión a internet
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      yield {
        'step': 'Sin conexión',
        'progress': 0.0,
        'error': 'No hay conexión a internet',
      };
      return;
    }

    try {
      // Paso 1: Descargar sedes (0% → 20% del progreso)
      yield {'step': 'Descargando sedes...', 'progress': 0.0};
      final sedesSuccess = await _sedeSyncService.syncSedes();
      if (!sedesSuccess) {
        yield {
          'step': 'Error',
          'progress': 0.0,
          'error': 'Error al descargar sedes',
        };
        return;
      }
      yield {'step': 'Sedes descargadas', 'progress': 0.2};

      // Paso 2: Descargar extintores (20% → 80% del progreso)
      yield {'step': 'Descargando extintores...', 'progress': 0.2};

      // Verificar conexión antes de descargar extintores
      final hasInternet2 = await InternetConnectionChecker().hasConnection;
      if (!hasInternet2) {
        yield {
          'step': 'Error',
          'progress': 0.2,
          'error': 'Conexión perdida durante la descarga',
        };
        return;
      }

      try {
        final extinguisherSuccess = await _extinguisherSyncService
            .syncExtinguishers();
        if (!extinguisherSuccess) {
          yield {
            'step': 'Error',
            'progress': 0.2,
            'error': 'Error al descargar extintores',
          };
          return;
        }
      } catch (e) {
        yield {
          'step': 'Error',
          'progress': 0.2,
          'error': e.toString().replaceAll('Exception: ', ''),
        };
        return;
      }
      yield {'step': 'Extintores descargados', 'progress': 0.8};

      // Paso 3: Descargar clientes (80% → 100% del progreso)
      yield {'step': 'Descargando clientes...', 'progress': 0.8};

      // Verificar conexión antes de descargar clientes
      final hasInternet3 = await InternetConnectionChecker().hasConnection;
      if (!hasInternet3) {
        yield {
          'step': 'Error',
          'progress': 0.8,
          'error': 'Conexión perdida durante la descarga',
        };
        return;
      }

      try {
        final clientsSuccess = await _clientSyncService.syncClients();
        if (!clientsSuccess) {
          yield {
            'step': 'Error',
            'progress': 0.8,
            'error': 'Error al descargar clientes',
          };
          return;
        }
      } catch (e) {
        yield {
          'step': 'Error',
          'progress': 0.8,
          'error': e.toString().replaceAll('Exception: ', ''),
        };
        return;
      }

      // Completado
      yield {'step': 'Sincronización completada', 'progress': 1.0};
    } catch (e) {
      yield {
        'step': 'Error',
        'progress': 0.0,
        'error': 'Error durante la sincronización: ${e.toString()}',
      };
    }
  }
}
