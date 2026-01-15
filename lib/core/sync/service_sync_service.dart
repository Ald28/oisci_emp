import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/services/data/datasources/local_service_datasource.dart';
import '../../features/services/data/datasources/http_service_datasource.dart';
import '../../features/services/data/models/maintenance_detail_model.dart';
import '../database/app_database.dart';

/// Servicio de sincronización para enviar servicios pendientes al servidor
class ServiceSyncService {
  final LocalServiceDataSource _localDataSource;
  final HttpServiceDataSource _httpDataSource;

  ServiceSyncService({
    LocalServiceDataSource? localDataSource,
    HttpServiceDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalServiceDataSource(),
       _httpDataSource = httpDataSource ?? HttpServiceDataSource();

  /// Sincronizar todos los servicios pendientes
  /// Retorna el número de servicios sincronizados exitosamente
  Future<int> syncPendingServices() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0;
    }

    int syncedCount = 0;
    final db = await AppDatabase.database;

    // Paso 1: Sincronizar CREATE_SERVICE primero
    final pendingServices = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE',
    );
    for (final item in pendingServices) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final service = await _httpDataSource.createService(data);

        // Buscar el servicio temporal por su ID negativo
        // El ID negativo está en la tabla servicio, no en sync_queue
        final tempServiceId = await _findTempServiceId(data, db);
        if (tempServiceId != null) {
          // Actualizar el servicio local: reemplazar ID negativo con positivo
          await _updateServiceId(db, tempServiceId, service.id);
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
      }
    }

    // Paso 2: Sincronizar CREATE_SERVICE_EXTINGUISHER
    final pendingServiceExtinguishers = await _localDataSource
        .getPendingSyncItems('CREATE_SERVICE_EXTINGUISHER');
    for (final item in pendingServiceExtinguishers) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        var servicioId = data['servicioId'] as int;

        // Mapear servicioId negativo a positivo si es necesario
        if (servicioId < 0) {
          final realServicioId = await _findRealServiceId(servicioId, db);
          if (realServicioId == null) {
            // El servicio padre aún no está sincronizado, esperar
            continue;
          }
          servicioId = realServicioId;
        }

        final serviceExtinguisher = await _httpDataSource
            .addExtinguisherToService(
              servicioId: servicioId,
              data: {
                'extintorId': data['extintorId'],
                'estadoInicial': data['estadoInicial'],
                'observaciones': data['observaciones'],
              },
            );

        // Buscar el servicio_extintor temporal por su ID negativo
        final tempServiceExtinguisherId = await _findTempServiceExtinguisherId(
          servicioId,
          data['extintorId'] as int,
          db,
        );
        if (tempServiceExtinguisherId != null) {
          // Actualizar servicio_extintor: reemplazar ID negativo con positivo
          await _updateServiceExtinguisherId(
            db,
            tempServiceExtinguisherId,
            serviceExtinguisher.id,
          );
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
      }
    }

    // Paso 3: Sincronizar CREATE_MAINTENANCE_DETAIL
    final pendingMaintenanceDetails = await _localDataSource
        .getPendingSyncItems('CREATE_MAINTENANCE_DETAIL');
    for (final item in pendingMaintenanceDetails) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        var servicioExtintorId = data['servicioExtintorId'] as int;

        // Mapear servicioExtintorId negativo a positivo si es necesario
        if (servicioExtintorId < 0) {
          final realServicioExtintorId = await _findRealServiceExtinguisherId(
            servicioExtintorId,
            db,
          );
          if (realServicioExtintorId == null) {
            // El servicio_extintor padre aún no está sincronizado, esperar
            continue;
          }
          servicioExtintorId = realServicioExtintorId;
        }

        // Preparar datos del checklist
        final checklistData = <String, dynamic>{
          'mantenimiento': data['mantenimiento'] ?? false,
          'recarga': data['recarga'] ?? false,
          'agenteCarga': data['agenteCarga'],
          'pruebaHidrostatica': data['pruebaHidrostatica'] ?? false,
          'bajaExtintor': data['bajaExtintor'] ?? false,
          'motivoBaja': data['motivoBaja'],
          'pintura': data['pintura'] ?? false,
          'recargaCartucho': data['recargaCartucho'] ?? false,
          'cambioPartes': data['cambioPartes'] ?? false,
          'detallesCambioPartes': data['detallesCambioPartes'],
        };

        final maintenanceDetail = await _httpDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          data: checklistData,
        );

        // Buscar el mantenimiento_detalle temporal usando el servicioExtintorId original (negativo) del payload
        final originalServicioExtintorId = data['servicioExtintorId'] as int;
        int? tempMaintenanceDetailId = await _findTempMaintenanceDetailId(
          originalServicioExtintorId, // Usar el ID original del payload
          db,
        );

        // Si no se encuentra con servicioExtintorId negativo (porque ya fue actualizado por _updateServiceExtinguisherId),
        // buscar con el servicioExtintorId positivo mapeado
        if (tempMaintenanceDetailId == null &&
            servicioExtintorId > 0 &&
            originalServicioExtintorId < 0) {
          final mdWithPositive = await db.query(
            'mantenimiento_detalle',
            where: 'servicioExtintorId = ? AND id < 0',
            whereArgs: [servicioExtintorId],
            limit: 1,
          );
          if (mdWithPositive.isNotEmpty) {
            tempMaintenanceDetailId = mdWithPositive.first['id'] as int;
          }
        }
        if (tempMaintenanceDetailId != null) {
          // Actualizar mantenimiento_detalle: reemplazar ID negativo con positivo
          await _updateMaintenanceDetailId(
            db,
            tempMaintenanceDetailId,
            maintenanceDetail.id,
            maintenanceDetailFromServer: maintenanceDetail,
          );
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
      }
    }

    return syncedCount;
  }

  /// Encontrar el ID temporal (negativo) del servicio basado en los datos del payload
  Future<int?> _findTempServiceId(
    Map<String, dynamic> data,
    Database db,
  ) async {
    final result = await db.query(
      'servicio',
      where: 'type = ? AND dateStart = ? AND sedeId = ? AND id < 0',
      whereArgs: [data['type'], data['dateStart'], data['sedeId']],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  /// Encontrar el ID real (positivo) del servicio sincronizado basado en el ID temporal
  /// Si el servicio temporal ya no existe (fue sincronizado), busca el servicio_extintor
  /// que tenía referencia al ID negativo y obtiene su servicioId actualizado
  Future<int?> _findRealServiceId(int tempId, Database db) async {
    // Primero intentar buscar el servicio temporal (puede que aún no se haya sincronizado)
    final tempService = await db.query(
      'servicio',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );

    if (tempService.isNotEmpty) {
      // El servicio temporal todavía existe, buscar el sincronizado por los campos
      final type = tempService.first['type'] as String;
      final dateStart = tempService.first['dateStart'] as String;
      final sedeId = tempService.first['sedeId'] as int;

      // Buscar el servicio sincronizado correspondiente (mismo tipo, fecha, sede, pero ID positivo)
      final syncedService = await db.query(
        'servicio',
        where: 'type = ? AND dateStart = ? AND sedeId = ? AND id > 0',
        whereArgs: [type, dateStart, sedeId],
        limit: 1,
      );

      if (syncedService.isNotEmpty) {
        return syncedService.first['id'] as int;
      }
    }

    // Si el servicio temporal ya no existe, significa que fue sincronizado y eliminado
    // Buscar servicio_extintor que aún tenga referencia al ID negativo original
    // Si ya fue actualizado por _updateServiceId, el servicioId ya será positivo
    // Buscar cualquier servicio_extintor que tenga servicioId positivo y que haya sido creado
    // recientemente, pero esto es difícil sin más información.

    // Mejor estrategia: buscar servicio_extintor con servicioId negativo que coincida,
    // y verificar si hay un servicio sincronizado que coincida con los datos
    // Pero como ya actualizamos las referencias en _updateServiceId, si el servicio fue sincronizado,
    // los servicio_extintor ya deberían tener servicioId positivo

    // Buscar servicio_extintor que tenga servicioId = tempId (si aún no se actualizó)
    // o buscar servicio_extintor que tenga servicioId positivo pero que originalmente
    // apuntaba al tempId (esto es difícil sin un campo de mapeo)

    // La mejor solución: buscar en servicio_extintor y si encuentro uno con servicioId positivo,
    // ese es el ID real. Pero necesito saber cuál servicio_extintor corresponde.

    // Alternativa más simple: buscar todos los servicios con ID positivo que fueron creados
    // recientemente y ver si alguno coincide, pero esto no es confiable.

    // Solución más robusta: cuando sincronizamos CREATE_SERVICE_EXTINGUISHER, el payload
    // tiene servicioId negativo, pero después de actualizar el servicio, los servicio_extintor
    // ya tienen servicioId positivo. Así que si busco servicio_extintor con servicioId = tempId
    // y no encuentro nada, pero busco servicio_extintor con servicioId > 0 que tenga
    // el mismo extintorId y createdAt similar, puedo obtener el servicioId.

    // Por ahora, si el servicio temporal no existe, buscar cualquier servicio_extintor
    // que tenga servicioId positivo reciente (pero esto no es confiable).

    // La solución correcta: cuando llamo a _findRealServiceId desde syncSingleService
    // para CREATE_SERVICE_EXTINGUISHER, el payload tiene el servicioId negativo.
    // En ese caso, después de que el servicio se sincroniza, los servicio_extintor
    // ya deberían tener servicioId positivo porque _updateServiceId actualiza las referencias.

    // Entonces, si el servicio temporal no existe, debería buscar servicio_extintor
    // que tenga servicioId positivo reciente. Pero para ser más preciso, puedo buscar
    // servicio_extintor que tenga el extintorId del payload y obtener su servicioId.

    // Pero no tengo el extintorId aquí en _findRealServiceId...

    // Solución temporal: si el servicio temporal no existe, retornar null y
    // confiar en que _updateServiceId actualizó las referencias correctamente.
    // Si las referencias fueron actualizadas, cuando busco servicio_extintor
    // con servicioId negativo en syncSingleService, no lo encontraré, pero
    // el servicioId en el payload es negativo, así que necesito mapearlo.

    // Mejor solución: en syncSingleService para CREATE_SERVICE_EXTINGUISHER,
    // antes de mapear el servicioId, verificar si ya hay servicio_extintor
    // con servicioId positivo que corresponda.

    // Por ahora, si el servicio temporal no existe, retornar null
    // y el código que llama manejará el error apropiadamente
    return null;
  }

  /// Encontrar el ID real (positivo) de un extintor temporal (negativo)
  Future<int?> _findRealExtinguisherId(int tempId, Database db) async {
    // Buscar el extintor temporal
    final tempExtinguisher = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );

    if (tempExtinguisher.isNotEmpty) {
      // El extintor temporal todavía existe, buscar el sincronizado por serialNumber
      final serialNumber = tempExtinguisher.first['serialNumber'] as String?;

      if (serialNumber != null) {
        // Buscar el extintor sincronizado correspondiente (mismo serialNumber, pero ID positivo)
        final syncedExtinguisher = await db.query(
          'extintor',
          where: 'serialNumber = ? AND id > 0',
          whereArgs: [serialNumber],
          limit: 1,
        );

        if (syncedExtinguisher.isNotEmpty) {
          return syncedExtinguisher.first['id'] as int;
        }
      }
    }

    // Si el extintor temporal ya no existe, significa que fue sincronizado
    // En ese caso, buscar en servicio_extintor cualquier registro que tenga
    // extintorId positivo y que haya sido actualizado recientemente
    // Pero esto no es confiable sin más información, así que retornar null
    // El código que llama deberá manejar este caso apropiadamente
    return null;
  }

  /// Actualizar el ID del servicio de negativo a positivo
  /// También actualiza las referencias en servicio_extintor
  Future<void> _updateServiceId(Database db, int oldId, int newId) async {
    // En SQLite no se puede actualizar PRIMARY KEY directamente, necesitamos usar una transacción
    // Leer todos los datos del servicio temporal
    final tempService = await db.query(
      'servicio',
      where: 'id = ?',
      whereArgs: [oldId],
      limit: 1,
    );

    if (tempService.isEmpty) return;

    final serviceData = tempService.first;

    // Insertar con el nuevo ID y eliminar el viejo, actualizando referencias
    await db.transaction((txn) async {
      // Insertar con nuevo ID
      await txn.insert('servicio', {
        'id': newId,
        'type': serviceData['type'],
        'dateStart': serviceData['dateStart'],
        'dateEnd': serviceData['dateEnd'],
        'sincronizado': 1,
        'status': serviceData['status'],
        'statusValid': serviceData['statusValid'],
        'historic': serviceData['historic'],
        'sedeId': serviceData['sedeId'],
        'userId': serviceData['userId'],
        'usuarioCreadorId': serviceData['usuarioCreadorId'],
        'usuarioActualizadorId': serviceData['usuarioActualizadorId'],
        'createdAt': serviceData['createdAt'],
        'updatedAt': serviceData['updatedAt'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Actualizar referencias en servicio_extintor (servicioId negativo -> positivo)
      await txn.update(
        'servicio_extintor',
        {'servicioId': newId},
        where: 'servicioId = ?',
        whereArgs: [oldId],
      );

      // Actualizar referencias en sync_queue para FINALIZE_SERVICE
      // Necesitamos actualizar el payload JSON que contiene servicioId
      final finalizeItems = await txn.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['FINALIZE_SERVICE'],
      );

      for (final item in finalizeItems) {
        try {
          final payloadStr = item['payload'] as String?;
          if (payloadStr != null) {
            final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
            final payloadServicioId = payload['servicioId'] as int?;

            // Si el servicioId en el payload coincide con el oldId, actualizarlo
            if (payloadServicioId == oldId) {
              payload['servicioId'] = newId;
              await txn.update(
                'sync_queue',
                {'payload': jsonEncode(payload)},
                where: 'id = ?',
                whereArgs: [item['id']],
              );
            }
          }
        } catch (e) {
          // Si hay error al parsear el JSON, continuar con el siguiente item
          continue;
        }
      }

      // Eliminar el registro temporal
      await txn.delete('servicio', where: 'id = ?', whereArgs: [oldId]);
    });
  }

  /// Encontrar el ID temporal (negativo) del servicio_extintor
  Future<int?> _findTempServiceExtinguisherId(
    int servicioId,
    int extintorId,
    Database db,
  ) async {
    final result = await db.query(
      'servicio_extintor',
      where: 'servicioId = ? AND extintorId = ? AND id < 0',
      whereArgs: [servicioId, extintorId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  /// Encontrar el ID real (positivo) del servicio_extintor sincronizado
  /// Si el registro temporal ya no existe (fue sincronizado y eliminado),
  /// busca el servicio_extintor sincronizado usando mantenimiento_detalle
  Future<int?> _findRealServiceExtinguisherId(int tempId, Database db) async {
    // Primero intentar buscar el servicio_extintor temporal (puede que aún no se haya sincronizado)
    final tempServiceExtinguisher = await db.query(
      'servicio_extintor',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );

    if (tempServiceExtinguisher.isNotEmpty) {
      // El servicio_extintor temporal todavía existe, buscar el sincronizado por los campos
      var servicioId = tempServiceExtinguisher.first['servicioId'] as int;
      final extintorId = tempServiceExtinguisher.first['extintorId'] as int;
      final createdAt = tempServiceExtinguisher.first['createdAt'] as String;

      // Mapear servicioId si es negativo
      if (servicioId < 0) {
        final realServicioId = await _findRealServiceId(servicioId, db);
        if (realServicioId == null) return null;
        servicioId = realServicioId;
      }

      // Buscar el servicio_extintor sincronizado correspondiente
      final syncedServiceExtinguisher = await db.query(
        'servicio_extintor',
        where: 'servicioId = ? AND extintorId = ? AND createdAt = ? AND id > 0',
        whereArgs: [servicioId, extintorId, createdAt],
        limit: 1,
      );

      if (syncedServiceExtinguisher.isNotEmpty) {
        return syncedServiceExtinguisher.first['id'] as int;
      }
    }

    // Si el servicio_extintor temporal ya no existe, significa que fue sincronizado y eliminado
    // Cuando _updateServiceExtinguisherId actualiza las referencias, cambia servicioExtintorId
    // de negativo (tempId) a positivo (newId) en mantenimiento_detalle.
    //
    // Estrategia mejorada: buscar directamente en mantenimiento_detalle que tenga servicioExtintorId positivo
    // (ya actualizado por _updateServiceExtinguisherId) y que aún no esté sincronizado (id < 0).
    // Luego, usar ese servicioExtintorId positivo para obtener el servicio_extintor sincronizado.
    // Esto es más directo y evita ambigüedades cuando hay múltiples servicio_extintor sincronizados.
    //
    // Primero, intentar buscar un mantenimiento_detalle pendiente que tenga servicioExtintorId positivo.
    // Si encontramos uno, ese servicioExtintorId debería ser el ID real del servicio_extintor sincronizado.
    final pendingMaintenanceDetails = await db.query(
      'mantenimiento_detalle',
      where: 'id < 0',
      orderBy: 'createdAt DESC',
      limit: 10, // Buscar los más recientes
    );

    // Para cada mantenimiento_detalle pendiente, verificar si su servicioExtintorId
    // corresponde a un servicio_extintor sincronizado
    for (final md in pendingMaintenanceDetails) {
      final servicioExtintorId = md['servicioExtintorId'] as int;
      if (servicioExtintorId > 0) {
        // Verificar que el servicio_extintor existe y está sincronizado
        final se = await db.query(
          'servicio_extintor',
          where: 'id = ? AND id > 0',
          whereArgs: [servicioExtintorId],
          limit: 1,
        );
        if (se.isNotEmpty) {
          // Este es el servicio_extintor sincronizado que buscamos
          return servicioExtintorId;
        }
      }
    }

    // Si no encontramos ninguno, buscar usando JOIN como fallback
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT se.id AS realServicioExtintorId
      FROM servicio_extintor se
      JOIN mantenimiento_detalle md ON se.id = md.servicioExtintorId
      WHERE se.id > 0 
        AND md.id < 0
      ORDER BY se.createdAt DESC
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      return result.first['realServicioExtintorId'] as int;
    }

    return null;
  }

  /// Actualizar el ID del servicio_extintor de negativo a positivo
  /// También actualiza las referencias en mantenimiento_detalle
  Future<void> _updateServiceExtinguisherId(
    Database db,
    int oldId,
    int newId,
  ) async {
    final tempServiceExtinguisher = await db.query(
      'servicio_extintor',
      where: 'id = ?',
      whereArgs: [oldId],
      limit: 1,
    );

    if (tempServiceExtinguisher.isEmpty) return;

    final serviceExtinguisherData = tempServiceExtinguisher.first;
    var servicioId = serviceExtinguisherData['servicioId'] as int;

    // Mapear servicioId si es negativo
    if (servicioId < 0) {
      final realServicioId = await _findRealServiceId(servicioId, db);
      if (realServicioId == null) return;
      servicioId = realServicioId;
    }

    await db.transaction((txn) async {
      await txn.insert('servicio_extintor', {
        'id': newId,
        'servicioId': servicioId,
        'extintorId': serviceExtinguisherData['extintorId'],
        'estadoInicial': serviceExtinguisherData['estadoInicial'],
        'estadoFinal': serviceExtinguisherData['estadoFinal'],
        'completado': serviceExtinguisherData['completado'],
        'observaciones': serviceExtinguisherData['observaciones'],
        'usuarioCreadorId': serviceExtinguisherData['usuarioCreadorId'],
        'usuarioActualizadorId':
            serviceExtinguisherData['usuarioActualizadorId'],
        'createdAt': serviceExtinguisherData['createdAt'],
        'updatedAt': serviceExtinguisherData['updatedAt'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Actualizar referencias en mantenimiento_detalle
      await txn.update(
        'mantenimiento_detalle',
        {'servicioExtintorId': newId},
        where: 'servicioExtintorId = ?',
        whereArgs: [oldId],
      );

      // Actualizar referencias en sync_queue para UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS
      // Necesitamos actualizar el payload JSON que contiene servicioExtintorId
      final observationItems = await txn.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS'],
      );

      for (final item in observationItems) {
        try {
          final payloadStr = item['payload'] as String?;
          if (payloadStr != null) {
            final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
            final payloadServicioExtintorId =
                payload['servicioExtintorId'] as int?;

            // Si el servicioExtintorId en el payload coincide con el oldId, actualizarlo
            if (payloadServicioExtintorId == oldId) {
              payload['servicioExtintorId'] = newId;
              await txn.update(
                'sync_queue',
                {'payload': jsonEncode(payload)},
                where: 'id = ?',
                whereArgs: [item['id']],
              );
            }
          }
        } catch (e) {
          // Si hay error al parsear el JSON, continuar con el siguiente item
          continue;
        }
      }

      await txn.delete(
        'servicio_extintor',
        where: 'id = ?',
        whereArgs: [oldId],
      );
    });
  }

  /// Encontrar el ID temporal (negativo) del mantenimiento_detalle
  Future<int?> _findTempMaintenanceDetailId(
    int servicioExtintorId,
    Database db,
  ) async {
    final result = await db.query(
      'mantenimiento_detalle',
      where: 'servicioExtintorId = ? AND id < 0',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  /// Actualizar el ID del mantenimiento_detalle de negativo a positivo
  /// Usa los datos del servidor (maintenanceDetailFromServer) si se proporciona, sino usa los datos locales
  Future<void> _updateMaintenanceDetailId(
    Database db,
    int oldId,
    int newId, {
    MaintenanceDetailModel? maintenanceDetailFromServer,
  }) async {
    final tempMaintenanceDetail = await db.query(
      'mantenimiento_detalle',
      where: 'id = ?',
      whereArgs: [oldId],
      limit: 1,
    );

    if (tempMaintenanceDetail.isEmpty) return;

    final maintenanceDetailData = tempMaintenanceDetail.first;
    var servicioExtintorId = maintenanceDetailData['servicioExtintorId'] as int;

    // Mapear servicioExtintorId si es negativo
    if (servicioExtintorId < 0) {
      final realServicioExtintorId = await _findRealServiceExtinguisherId(
        servicioExtintorId,
        db,
      );
      if (realServicioExtintorId == null) return;
      servicioExtintorId = realServicioExtintorId;
    }

    // Usar datos del servidor si están disponibles, sino usar datos locales
    final mantenimiento =
        maintenanceDetailFromServer?.mantenimiento ??
        ((maintenanceDetailData['mantenimiento'] as int? ?? 0) == 1);
    final recarga =
        maintenanceDetailFromServer?.recarga ??
        ((maintenanceDetailData['recarga'] as int? ?? 0) == 1);
    final agenteCarga =
        maintenanceDetailFromServer?.agenteCarga ??
        maintenanceDetailData['agenteCarga'] as String?;
    final pruebaHidrostatica =
        maintenanceDetailFromServer?.pruebaHidrostatica ??
        ((maintenanceDetailData['pruebaHidrostatica'] as int? ?? 0) == 1);
    final bajaExtintor =
        maintenanceDetailFromServer?.bajaExtintor ??
        ((maintenanceDetailData['bajaExtintor'] as int? ?? 0) == 1);
    final motivoBaja =
        maintenanceDetailFromServer?.motivoBaja ??
        maintenanceDetailData['motivoBaja'] as String?;
    final pintura =
        maintenanceDetailFromServer?.pintura ??
        ((maintenanceDetailData['pintura'] as int? ?? 0) == 1);
    final recargaCartucho =
        maintenanceDetailFromServer?.recargaCartucho ??
        ((maintenanceDetailData['recargaCartucho'] as int? ?? 0) == 1);
    final cambioPartes =
        maintenanceDetailFromServer?.cambioPartes ??
        ((maintenanceDetailData['cambioPartes'] as int? ?? 0) == 1);
    final detallesCambioPartes =
        maintenanceDetailFromServer?.detallesCambioPartes ??
        maintenanceDetailData['detallesCambioPartes'] as String?;
    final usuarioCreadorId =
        maintenanceDetailFromServer?.usuarioCreadorId ??
        maintenanceDetailData['usuarioCreadorId'] as int;
    final usuarioActualizadorId =
        maintenanceDetailFromServer?.usuarioActualizadorId ??
        maintenanceDetailData['usuarioActualizadorId'] as int?;
    final createdAt = maintenanceDetailFromServer?.createdAt != null
        ? maintenanceDetailFromServer!.createdAt!.toIso8601String()
        : maintenanceDetailData['createdAt'] as String?;
    final updatedAt = maintenanceDetailFromServer?.updatedAt != null
        ? maintenanceDetailFromServer!.updatedAt!.toIso8601String()
        : DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('mantenimiento_detalle', {
        'id': newId,
        'servicioExtintorId': servicioExtintorId,
        'mantenimiento': mantenimiento ? 1 : 0,
        'recarga': recarga ? 1 : 0,
        'agenteCarga': agenteCarga,
        'pruebaHidrostatica': pruebaHidrostatica ? 1 : 0,
        'bajaExtintor': bajaExtintor ? 1 : 0,
        'motivoBaja': motivoBaja,
        'pintura': pintura ? 1 : 0,
        'recargaCartucho': recargaCartucho ? 1 : 0,
        'cambioPartes': cambioPartes ? 1 : 0,
        'detallesCambioPartes': detallesCambioPartes,
        'usuarioCreadorId': usuarioCreadorId,
        'usuarioActualizadorId': usuarioActualizadorId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'mantenimiento_detalle',
        where: 'id = ?',
        whereArgs: [oldId],
      );
    });
  }

  /// Obtener todos los servicios pendientes
  Future<List<Map<String, dynamic>>> getPendingServices() async {
    final allPending = <Map<String, dynamic>>[];

    // Obtener servicios pendientes
    final services = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE',
    );
    allPending.addAll(services);

    // Obtener servicio_extintor pendientes
    final serviceExtinguishers = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE_EXTINGUISHER',
    );
    allPending.addAll(serviceExtinguishers);

    // Obtener mantenimiento_detalle pendientes
    final maintenanceDetails = await _localDataSource.getPendingSyncItems(
      'CREATE_MAINTENANCE_DETAIL',
    );
    allPending.addAll(maintenanceDetails);

    // Obtener actualizaciones de mantenimiento_detalle pendientes
    final updateMaintenanceDetails = await _localDataSource.getPendingSyncItems(
      'UPDATE_MAINTENANCE_DETAIL',
    );
    allPending.addAll(updateMaintenanceDetails);

    // Obtener actualizaciones de observaciones de servicio_extintor pendientes
    final updateObservations = await _localDataSource.getPendingSyncItems(
      'UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS',
    );
    allPending.addAll(updateObservations);

    // Obtener finalizaciones de servicio pendientes
    final finalizeServices = await _localDataSource.getPendingSyncItems(
      'FINALIZE_SERVICE',
    );
    allPending.addAll(finalizeServices);

    // Ordenar por createdAt
    allPending.sort((a, b) {
      final aDate = a['createdAt'] as String? ?? '';
      final bDate = b['createdAt'] as String? ?? '';
      return aDate.compareTo(bDate);
    });

    return allPending;
  }

  /// Obtener la cantidad de servicios pendientes
  Future<int> getPendingCount() async {
    final pending = await getPendingServices();
    return pending.length;
  }

  /// Verificar si hay servicios pendientes
  Future<bool> hasPendingServices() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Sincronizar todos los servicios pendientes con progreso
  /// Retorna un Stream con el progreso de sincronización
  Stream<Map<String, dynamic>> syncPendingServicesWithProgress() async* {
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

    // Obtener todos los servicios pendientes
    final pendingItems = await getPendingServices();

    if (pendingItems.isEmpty) {
      yield {'step': 'No hay servicios pendientes', 'progress': 1.0};
      return;
    }

    final totalItems = pendingItems.length;
    int syncedCount = 0;

    for (int i = 0; i < pendingItems.length; i++) {
      final item = pendingItems[i];
      try {
        final success = await syncSingleService(item['id'] as int);
        if (success) {
          syncedCount++;
        }

        // Emitir progreso
        yield {
          'step': 'Sincronizando servicio ${i + 1} de $totalItems',
          'progress': ((i + 1) / totalItems),
          'total': totalItems,
          'synced': syncedCount,
        };
      } catch (e) {
        final errorMessage = e.toString();
        yield {
          'step': 'Error en servicio ${i + 1} de $totalItems',
          'progress': ((i + 1) / totalItems),
          'total': totalItems,
          'synced': syncedCount,
          'error':
              'Error al sincronizar: ${errorMessage.substring(0, errorMessage.length > 50 ? 50 : errorMessage.length)}...',
        };
      }
    }

    // Completado
    yield {
      'step': 'Sincronización completada',
      'progress': 1.0,
      'total': totalItems,
      'synced': syncedCount,
    };
  }

  /// Sincronizar un servicio individual por ID de la cola
  Future<bool> syncSingleService(int queueId) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      await _localDataSource.updateSyncError(
        queueId,
        'No hay conexión a internet',
      );
      return false;
    }

    try {
      final db = await AppDatabase.database;
      final item = await db.query(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [queueId],
        limit: 1,
      );

      if (item.isEmpty) return false;

      final queueItem = item.first;
      final type = queueItem['type'] as String;
      final data =
          jsonDecode(queueItem['payload'] as String) as Map<String, dynamic>;

      if (type == 'CREATE_SERVICE') {
        final service = await _httpDataSource.createService(data);
        final tempServiceId = await _findTempServiceId(data, db);
        if (tempServiceId != null) {
          await _updateServiceId(db, tempServiceId, service.id);
        }
        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'CREATE_SERVICE_EXTINGUISHER') {
        var servicioId = data['servicioId'] as int;
        var extintorId = data['extintorId'] as int;

        // Mapear servicioId negativo a positivo si es necesario
        if (servicioId < 0) {
          final realServicioId = await _findRealServiceId(servicioId, db);
          if (realServicioId == null) {
            // Si no se encuentra por el método normal, buscar por servicio_extintor
            // que tenga servicioId positivo pero que originalmente apuntaba al negativo
            final serviceExtinguishers = await db.query(
              'servicio_extintor',
              where: 'extintorId = ? AND servicioId > 0',
              whereArgs: [extintorId],
              orderBy: 'createdAt DESC',
              limit: 5,
            );

            // Si encontramos servicio_extintor con servicioId positivo, usar ese servicioId
            // Esto funciona porque cuando se sincroniza el servicio, _updateServiceId
            // actualiza las referencias en servicio_extintor
            if (serviceExtinguishers.isNotEmpty) {
              // Buscar el más reciente que probablemente corresponde
              final latest = serviceExtinguishers.first;
              servicioId = latest['servicioId'] as int;
            } else {
              await _localDataSource.updateSyncError(
                queueId,
                'El servicio padre aún no está sincronizado',
              );
              return false;
            }
          } else {
            servicioId = realServicioId;
          }
        }

        // Mapear extintorId negativo a positivo si es necesario
        if (extintorId < 0) {
          final realExtintorId = await _findRealExtinguisherId(extintorId, db);
          if (realExtintorId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El extintor aún no está sincronizado',
            );
            return false;
          }
          extintorId = realExtintorId;
        }

        final serviceExtinguisher = await _httpDataSource
            .addExtinguisherToService(
              servicioId: servicioId,
              data: {
                'extintorId': extintorId,
                'estadoInicial': data['estadoInicial'],
                'observaciones': data['observaciones'],
              },
            );

        // Buscar el servicio_extintor temporal usando el servicioId original (negativo) del payload
        final originalServicioId = data['servicioId'] as int;
        int? tempServiceExtinguisherId = await _findTempServiceExtinguisherId(
          originalServicioId, // Usar el ID original del payload
          data['extintorId'] as int,
          db,
        );

        // Si no se encuentra con servicioId negativo (porque ya fue actualizado por _updateServiceId),
        // buscar con el servicioId positivo mapeado
        if (tempServiceExtinguisherId == null &&
            servicioId > 0 &&
            originalServicioId < 0) {
          final seWithPositive = await db.query(
            'servicio_extintor',
            where: 'servicioId = ? AND extintorId = ? AND id < 0',
            whereArgs: [servicioId, data['extintorId'] as int],
            limit: 1,
          );
          if (seWithPositive.isNotEmpty) {
            tempServiceExtinguisherId = seWithPositive.first['id'] as int;
          }
        }

        if (tempServiceExtinguisherId != null) {
          await _updateServiceExtinguisherId(
            db,
            tempServiceExtinguisherId,
            serviceExtinguisher.id,
          );
        }
        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'CREATE_MAINTENANCE_DETAIL') {
        final originalServicioExtintorId = data['servicioExtintorId'] as int;
        var servicioExtintorId = originalServicioExtintorId;

        if (servicioExtintorId < 0) {
          final realServicioExtintorId = await _findRealServiceExtinguisherId(
            servicioExtintorId,
            db,
          );
          if (realServicioExtintorId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio_extintor padre aún no está sincronizado',
            );
            return false;
          }
          servicioExtintorId = realServicioExtintorId;
        }

        final checklistData = <String, dynamic>{
          'mantenimiento': data['mantenimiento'] ?? false,
          'recarga': data['recarga'] ?? false,
          'agenteCarga': data['agenteCarga'],
          'pruebaHidrostatica': data['pruebaHidrostatica'] ?? false,
          'bajaExtintor': data['bajaExtintor'] ?? false,
          'motivoBaja': data['motivoBaja'],
          'pintura': data['pintura'] ?? false,
          'recargaCartucho': data['recargaCartucho'] ?? false,
          'cambioPartes': data['cambioPartes'] ?? false,
          'detallesCambioPartes': data['detallesCambioPartes'],
        };

        final maintenanceDetail = await _httpDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          data: checklistData,
        );

        // Buscar el mantenimiento_detalle temporal usando el servicioExtintorId original (negativo) del payload
        int? tempMaintenanceDetailId = await _findTempMaintenanceDetailId(
          originalServicioExtintorId, // Usar el ID original del payload
          db,
        );

        // Si no se encuentra con servicioExtintorId negativo (porque ya fue actualizado por _updateServiceExtinguisherId),
        // buscar con el servicioExtintorId positivo mapeado
        if (tempMaintenanceDetailId == null &&
            servicioExtintorId > 0 &&
            originalServicioExtintorId < 0) {
          final mdWithPositive = await db.query(
            'mantenimiento_detalle',
            where: 'servicioExtintorId = ? AND id < 0',
            whereArgs: [servicioExtintorId],
            limit: 1,
          );
          if (mdWithPositive.isNotEmpty) {
            tempMaintenanceDetailId = mdWithPositive.first['id'] as int;
          }
        }

        if (tempMaintenanceDetailId != null) {
          await _updateMaintenanceDetailId(
            db,
            tempMaintenanceDetailId,
            maintenanceDetail.id,
            maintenanceDetailFromServer: maintenanceDetail,
          );
        }
        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'UPDATE_MAINTENANCE_DETAIL') {
        final servicioExtintorId = data['servicioExtintorId'] as int;

        final checklistData = <String, dynamic>{
          'mantenimiento': data['mantenimiento'] ?? false,
          'recarga': data['recarga'] ?? false,
          'agenteCarga': data['agenteCarga'],
          'pruebaHidrostatica': data['pruebaHidrostatica'] ?? false,
          'bajaExtintor': data['bajaExtintor'] ?? false,
          'motivoBaja': data['motivoBaja'],
          'pintura': data['pintura'] ?? false,
          'recargaCartucho': data['recargaCartucho'] ?? false,
          'cambioPartes': data['cambioPartes'] ?? false,
          'detallesCambioPartes': data['detallesCambioPartes'],
        };

        await _httpDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          data: checklistData,
        );

        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS') {
        var servicioExtintorId = data['servicioExtintorId'] as int;
        final observaciones = data['observaciones'] as String?;

        // Validar que las observaciones no estén vacías
        if (observaciones == null || observaciones.trim().isEmpty) {
          // Si las observaciones están vacías, eliminar de la cola sin sincronizar
          await _localDataSource.deleteQueueItem(queueId);
          return true;
        }

        // Mapear servicioExtintorId negativo a positivo si es necesario
        if (servicioExtintorId < 0) {
          final realServicioExtintorId = await _findRealServiceExtinguisherId(
            servicioExtintorId,
            db,
          );
          if (realServicioExtintorId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio_extintor padre aún no está sincronizado',
            );
            return false;
          }
          servicioExtintorId = realServicioExtintorId;
        }

        await _httpDataSource.updateServiceExtinguisherObservations(
          servicioExtintorId: servicioExtintorId,
          observaciones: observaciones,
        );

        // Actualizar localmente sin agregar a sync_queue
        await _localDataSource.updateServiceExtinguisherObservations(
          servicioExtintorId: servicioExtintorId,
          observaciones: observaciones,
          addToSyncQueue: false,
        );

        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'FINALIZE_SERVICE') {
        var servicioId = data['servicioId'] as int;

        // Mapear servicioId negativo a positivo si es necesario
        if (servicioId < 0) {
          final realServicioId = await _findRealServiceId(servicioId, db);
          if (realServicioId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio padre aún no está sincronizado',
            );
            return false;
          }
          servicioId = realServicioId;
        }

        await _httpDataSource.finalizeService(servicioId);

        // Actualizar también localmente (sin agregar a sync_queue)
        await _localDataSource.finalizeService(
          servicioId,
          addToSyncQueue: false,
        );

        await _localDataSource.deleteQueueItem(queueId);
        return true;
      }

      return false;
    } catch (e) {
      await _localDataSource.updateSyncError(queueId, e.toString());
      return false;
    }
  }
}
