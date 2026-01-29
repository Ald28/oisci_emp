import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/services/data/datasources/local_service_datasource.dart';
import '../../features/services/data/datasources/http_service_datasource.dart';
import '../../features/services/data/models/maintenance_detail_model.dart';
import '../../features/services/data/models/inspection_detail_model.dart';
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

        try {
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
          final tempServiceExtinguisherId =
              await _findTempServiceExtinguisherId(
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
        } on DioException catch (e) {
          // Si el error es que el extintor ya está agregado, buscar el registro existente
          final errorMessage = e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message'] as String?
              : e.message;

          if (errorMessage != null &&
              (errorMessage.toLowerCase().contains('ya está agregado') ||
                  errorMessage.toLowerCase().contains('duplicate') ||
                  errorMessage.toLowerCase().contains('unique'))) {
            // El extintor ya está agregado en el servidor
            // Buscar el servicio_extintor existente en la base de datos local
            final existing = await db.query(
              'servicio_extintor',
              where: 'servicioId = ? AND extintorId = ? AND id > 0',
              whereArgs: [servicioId, data['extintorId'] as int],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              // Ya existe un registro sincronizado, actualizar el temporal si existe
              final existingId = existing.first['id'] as int;
              final tempServiceExtinguisherId =
                  await _findTempServiceExtinguisherId(
                    servicioId,
                    data['extintorId'] as int,
                    db,
                  );

              if (tempServiceExtinguisherId != null &&
                  tempServiceExtinguisherId != existingId) {
                // Eliminar el registro temporal duplicado
                await db.delete(
                  'servicio_extintor',
                  where: 'id = ?',
                  whereArgs: [tempServiceExtinguisherId],
                );
              }

              // Eliminar de la cola porque ya existe en el servidor
              await _localDataSource.deleteQueueItem(item['id'] as int);
              syncedCount++;
            } else {
              // No encontrado localmente, guardar error pero no bloquear
              await _localDataSource.updateSyncError(
                item['id'] as int,
                'Este extintor ya está agregado al servicio (existe en el servidor)',
              );
            }
          } else {
            // Otro tipo de error, guardar normalmente
            await _localDataSource.updateSyncError(
              item['id'] as int,
              e.toString(),
            );
          }
        } catch (e) {
          await _localDataSource.updateSyncError(
            item['id'] as int,
            e.toString(),
          );
        }
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

    // Paso 4: Sincronizar CREATE_INSPECTION_DETAIL
    final pendingInspectionDetails = await _localDataSource.getPendingSyncItems(
      'CREATE_INSPECTION_DETAIL',
    );
    for (final item in pendingInspectionDetails) {
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

        // Convertir paths locales a Files si existen
        File? foto1File;
        File? foto2File;
        File? foto3File;

        final foto1Path = data['foto1Path'] as String?;
        final foto2Path = data['foto2Path'] as String?;
        final foto3Path = data['foto3Path'] as String?;

        if (foto1Path != null && File(foto1Path).existsSync()) {
          foto1File = File(foto1Path);
        }
        if (foto2Path != null && File(foto2Path).existsSync()) {
          foto2File = File(foto2Path);
        }
        if (foto3Path != null && File(foto3Path).existsSync()) {
          foto3File = File(foto3Path);
        }

        final inspectionData = <String, dynamic>{
          'foto1Url': data['foto1Url'] as String?,
          'foto2Url': data['foto2Url'] as String?,
          'foto3Url': data['foto3Url'] as String?,
          'accesibilidad': data['accesibilidad'],
          'observaciones': data['observaciones'],
          'ubicacion': data['ubicacion'],
          'instalacion': data['instalacion'],
          'instrucciones': data['instrucciones'],
          'clasificacion': data['clasificacion'],
          'recarga': data['recarga'],
          'certificacion': data['certificacion'],
          'presion': data['presion'],
          'seguridad': data['seguridad'],
          'estado': data['estado'],
          'carga': data['carga'],
          'soporte': data['soporte'],
          'activacion': data['activacion'],
          'manguera': data['manguera'],
          'boquilla': data['boquilla'],
          'abrazadera': data['abrazadera'],
        };

        // Agregar Files si existen (se subirán junto con el checklist)
        if (foto1File != null) inspectionData['foto1'] = foto1File;
        if (foto2File != null) inspectionData['foto2'] = foto2File;
        if (foto3File != null) inspectionData['foto3'] = foto3File;

        final inspectionDetail = await _httpDataSource.createInspectionDetail(
          servicioExtintorId: servicioExtintorId,
          data: inspectionData,
        );

        // Buscar el inspeccion_detalle temporal usando el servicioExtintorId original (negativo) del payload
        final originalServicioExtintorId = data['servicioExtintorId'] as int;
        int? tempInspectionDetailId = await _findTempInspectionDetailId(
          originalServicioExtintorId, // Usar el ID original del payload
          db,
        );

        // Si no se encuentra con servicioExtintorId negativo (porque ya fue actualizado por _updateServiceExtinguisherId),
        // buscar con el servicioExtintorId positivo mapeado
        if (tempInspectionDetailId == null &&
            servicioExtintorId > 0 &&
            originalServicioExtintorId < 0) {
          final idWithPositive = await db.query(
            'inspeccion_detalle',
            where: 'servicioExtintorId = ? AND id < 0',
            whereArgs: [servicioExtintorId],
            limit: 1,
          );
          if (idWithPositive.isNotEmpty) {
            tempInspectionDetailId = idWithPositive.first['id'] as int;
          }
        }

        if (tempInspectionDetailId != null) {
          // Actualizar inspeccion_detalle: reemplazar ID negativo con positivo
          await _updateInspectionDetailId(
            db,
            tempInspectionDetailId,
            inspectionDetail.id,
            inspectionDetailFromServer: inspectionDetail,
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
  /// Si el servicio temporal ya no existe (fue sincronizado), busca servicios sincronizados
  /// recientemente que coincidan con el tipo y sede
  Future<int?> _findRealServiceId(
    int tempId,
    Database db, {
    String? type,
    int? sedeId,
  }) async {
    // Primero intentar buscar el servicio temporal (puede que aún no se haya sincronizado)
    final tempService = await db.query(
      'servicio',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );

    if (tempService.isNotEmpty) {
      // El servicio temporal todavía existe, buscar el sincronizado por los campos
      final serviceType = tempService.first['type'] as String;
      final dateStart = tempService.first['dateStart'] as String;
      final serviceSedeId = tempService.first['sedeId'] as int;

      // Buscar el servicio sincronizado correspondiente (mismo tipo, fecha, sede, pero ID positivo)
      final syncedService = await db.query(
        'servicio',
        where: 'type = ? AND dateStart = ? AND sedeId = ? AND id > 0',
        whereArgs: [serviceType, dateStart, serviceSedeId],
        limit: 1,
      );

      if (syncedService.isNotEmpty) {
        return syncedService.first['id'] as int;
      }
    }

    // Si el servicio temporal ya no existe, buscar servicios sincronizados recientemente
    // que coincidan con el tipo y sede (si se proporcionan)
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (type != null && sedeId != null) {
      whereClause = 'type = ? AND sedeId = ? AND id > 0';
      whereArgs = [type, sedeId];
    } else if (type != null) {
      whereClause = 'type = ? AND id > 0';
      whereArgs = [type];
    } else if (sedeId != null) {
      whereClause = 'sedeId = ? AND id > 0';
      whereArgs = [sedeId];
    } else {
      whereClause = 'id > 0';
      whereArgs = [];
    }

    // Buscar servicios sincronizados recientemente (últimos 10) ordenados por createdAt DESC
    final recentServices = await db.query(
      'servicio',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
      limit: 10,
    );

    if (recentServices.isNotEmpty) {
      // Usar el servicio más reciente que coincida
      // Esto funciona porque los servicios se sincronizan en orden cronológico
      return recentServices.first['id'] as int;
    }

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
      final row = tempExtinguisher.first;
      final serialNumberNFC = row['serialNumberNFC'] as String?;

      if (serialNumberNFC != null && serialNumberNFC.isNotEmpty) {
        final syncedExtinguisher = await db.query(
          'extintor',
          where: 'serialNumberNFC = ? AND id > 0',
          whereArgs: [serialNumberNFC],
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

      // Actualizar referencias en sync_queue para CREATE_SERVICE_EXTINGUISHER
      // Necesitamos actualizar el payload JSON que contiene servicioId
      final serviceExtinguisherItems = await txn.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['CREATE_SERVICE_EXTINGUISHER'],
      );

      for (final item in serviceExtinguisherItems) {
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
    var extintorId = serviceExtinguisherData['extintorId'] as int;

    // Mapear servicioId si es negativo
    if (servicioId < 0) {
      final realServicioId = await _findRealServiceId(servicioId, db);
      if (realServicioId == null) return;
      servicioId = realServicioId;
    }

    // Mapear extintorId si es negativo (el extintor puede haberse sincronizado antes)
    if (extintorId < 0) {
      final realExtintorId = await _findRealExtinguisherId(extintorId, db);
      if (realExtintorId != null) {
        extintorId = realExtintorId;
      }
      // Si no se encuentra el extintor sincronizado, mantener el ID negativo
      // (el extintor aún no se ha sincronizado)
    }

    await db.transaction((txn) async {
      await txn.insert('servicio_extintor', {
        'id': newId,
        'servicioId': servicioId,
        'extintorId': extintorId,
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

      // Actualizar referencias en inspeccion_detalle
      await txn.update(
        'inspeccion_detalle',
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

      // Actualizar referencias en sync_queue para CREATE_INSPECTION_DETAIL y UPDATE_INSPECTION_DETAIL
      // Necesitamos actualizar el payload JSON que contiene servicioExtintorId
      final inspectionItems = await txn.query(
        'sync_queue',
        where: 'type IN (?, ?)',
        whereArgs: ['CREATE_INSPECTION_DETAIL', 'UPDATE_INSPECTION_DETAIL'],
      );

      for (final item in inspectionItems) {
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

  /// Buscar InspeccionDetalle temporal por servicioExtintorId
  Future<int?> _findTempInspectionDetailId(
    int servicioExtintorId,
    Database db,
  ) async {
    final result = await db.query(
      'inspeccion_detalle',
      where: 'servicioExtintorId = ? AND id < 0',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  /// Actualizar ID de InspeccionDetalle después de sincronización
  Future<void> _updateInspectionDetailId(
    Database db,
    int oldId,
    int newId, {
    InspectionDetailModel? inspectionDetailFromServer,
  }) async {
    final tempInspectionDetail = await db.query(
      'inspeccion_detalle',
      where: 'id = ?',
      whereArgs: [oldId],
      limit: 1,
    );

    if (tempInspectionDetail.isEmpty) return;

    final inspectionDetailData = tempInspectionDetail.first;
    var servicioExtintorId = inspectionDetailData['servicioExtintorId'] as int;

    // Mapear servicioExtintorId si es negativo
    if (servicioExtintorId < 0) {
      final realServicioExtinguisherId = await _findRealServiceExtinguisherId(
        servicioExtintorId,
        db,
      );
      if (realServicioExtinguisherId == null) return;
      servicioExtintorId = realServicioExtinguisherId;
    }

    // Usar datos del servidor si están disponibles, sino usar datos locales
    final foto1Url =
        inspectionDetailFromServer?.foto1Url ??
        inspectionDetailData['foto1Url'] as String?;
    final foto2Url =
        inspectionDetailFromServer?.foto2Url ??
        inspectionDetailData['foto2Url'] as String?;
    final foto3Url =
        inspectionDetailFromServer?.foto3Url ??
        inspectionDetailData['foto3Url'] as String?;
    final accesibilidad =
        inspectionDetailFromServer?.accesibilidad ??
        inspectionDetailData['accesibilidad'] as String?;
    final observaciones =
        inspectionDetailFromServer?.observaciones ??
        inspectionDetailData['observaciones'] as String?;
    final ubicacion =
        inspectionDetailFromServer?.ubicacion ??
        inspectionDetailData['ubicacion'] as String?;
    final instalacion =
        inspectionDetailFromServer?.instalacion ??
        inspectionDetailData['instalacion'] as String?;
    final instrucciones =
        inspectionDetailFromServer?.instrucciones ??
        inspectionDetailData['instrucciones'] as String?;
    final clasificacion =
        inspectionDetailFromServer?.clasificacion ??
        inspectionDetailData['clasificacion'] as String?;
    final recarga =
        inspectionDetailFromServer?.recarga ??
        inspectionDetailData['recarga'] as String?;
    final certificacion =
        inspectionDetailFromServer?.certificacion ??
        inspectionDetailData['certificacion'] as String?;
    final presion =
        inspectionDetailFromServer?.presion ??
        inspectionDetailData['presion'] as String?;
    final seguridad =
        inspectionDetailFromServer?.seguridad ??
        inspectionDetailData['seguridad'] as String?;
    final estado =
        inspectionDetailFromServer?.estado ??
        inspectionDetailData['estado'] as String?;
    final carga =
        inspectionDetailFromServer?.carga ??
        inspectionDetailData['carga'] as String?;
    final soporte =
        inspectionDetailFromServer?.soporte ??
        inspectionDetailData['soporte'] as String?;
    final activacion =
        inspectionDetailFromServer?.activacion ??
        inspectionDetailData['activacion'] as String?;
    final manguera =
        inspectionDetailFromServer?.manguera ??
        inspectionDetailData['manguera'] as String?;
    final boquilla =
        inspectionDetailFromServer?.boquilla ??
        inspectionDetailData['boquilla'] as String?;
    final abrazadera =
        inspectionDetailFromServer?.abrazadera ??
        inspectionDetailData['abrazadera'] as String?;
    final usuarioCreadorId =
        inspectionDetailFromServer?.usuarioCreadorId ??
        inspectionDetailData['usuarioCreadorId'] as int;
    final usuarioActualizadorId =
        inspectionDetailFromServer?.usuarioActualizadorId ??
        inspectionDetailData['usuarioActualizadorId'] as int?;
    final createdAt = inspectionDetailFromServer?.createdAt != null
        ? inspectionDetailFromServer!.createdAt!.toIso8601String()
        : inspectionDetailData['createdAt'] as String?;
    final updatedAt = inspectionDetailFromServer?.updatedAt != null
        ? inspectionDetailFromServer!.updatedAt!.toIso8601String()
        : DateTime.now().toIso8601String();

    // Obtener paths locales del registro temporal (si existen)
    final foto1Path = inspectionDetailData['foto1Path'] as String?;
    final foto2Path = inspectionDetailData['foto2Path'] as String?;
    final foto3Path = inspectionDetailData['foto3Path'] as String?;

    await db.transaction((txn) async {
      await txn.insert('inspeccion_detalle', {
        'id': newId,
        'servicioExtintorId': servicioExtintorId,
        'foto1Url': foto1Url,
        'foto2Url': foto2Url,
        'foto3Url': foto3Url,
        'foto1Path': foto1Path,
        'foto2Path': foto2Path,
        'foto3Path': foto3Path,
        'accesibilidad': accesibilidad,
        'observaciones': observaciones,
        'ubicacion': ubicacion,
        'instalacion': instalacion,
        'instrucciones': instrucciones,
        'clasificacion': clasificacion,
        'recarga': recarga,
        'certificacion': certificacion,
        'presion': presion,
        'seguridad': seguridad,
        'estado': estado,
        'carga': carga,
        'soporte': soporte,
        'activacion': activacion,
        'manguera': manguera,
        'boquilla': boquilla,
        'abrazadera': abrazadera,
        'usuarioCreadorId': usuarioCreadorId,
        'usuarioActualizadorId': usuarioActualizadorId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'inspeccion_detalle',
        where: 'id = ?',
        whereArgs: [oldId],
      );

      // Si hay foto1Url, actualizar también Extintor.photo (como lo hace el backend)
      // También guardar el path local si existe para modo offline
      if (foto1Url != null && foto1Url.isNotEmpty) {
        // Obtener el extintorId desde servicio_extintor
        final servicioExtintor = await txn.query(
          'servicio_extintor',
          where: 'id = ?',
          whereArgs: [servicioExtintorId],
          limit: 1,
        );

        if (servicioExtintor.isNotEmpty) {
          final extintorId = servicioExtintor.first['extintorId'] as int?;
          if (extintorId != null) {
            // Verificar si ya existe photoPath en el extintor para preservarlo
            final existingExtintor = await txn.query(
              'extintor',
              where: 'id = ?',
              whereArgs: [extintorId],
              limit: 1,
            );

            // Preservar photoPath existente si no se está actualizando con uno nuevo
            String? finalPhotoPath = foto1Path;
            if (existingExtintor.isNotEmpty) {
              final existingPhotoPath =
                  existingExtintor.first['photoPath'] as String?;
              // Si hay un path nuevo, usarlo; si no, preservar el existente
              if (foto1Path == null || foto1Path.isEmpty) {
                finalPhotoPath = existingPhotoPath;
              }
            }

            // Actualizar Extintor.photo y photoPath
            final updateData = <String, dynamic>{
              'photo': foto1Url,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            // Solo actualizar photoPath si hay uno nuevo o si existe uno para preservar
            if (finalPhotoPath != null) {
              updateData['photoPath'] = finalPhotoPath;
            }

            await txn.update(
              'extintor',
              updateData,
              where: 'id = ?',
              whereArgs: [extintorId],
            );
          }
        }
      }
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

    // Obtener inspecciones_detalle pendientes
    final inspectionDetails = await _localDataSource.getPendingSyncItems(
      'CREATE_INSPECTION_DETAIL',
    );
    allPending.addAll(inspectionDetails);

    // Obtener actualizaciones de inspeccion_detalle pendientes
    final updateInspectionDetails = await _localDataSource.getPendingSyncItems(
      'UPDATE_INSPECTION_DETAIL',
    );
    allPending.addAll(updateInspectionDetails);

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
        // Estrategia profesional y eficiente:
        // 1. Si el servicio_extintor ya tiene servicioId positivo (actualizado por _updateServiceId),
        //    usar ese directamente (más eficiente - 1 query)
        // 2. Si no, buscar el servicio temporal y su correspondiente sincronizado
        final originalServicioId = servicioId; // Guardar el ID original
        if (servicioId < 0) {
          int? realServicioId;

          // Estrategia más eficiente: buscar directamente el servicio_extintor que tiene
          // el servicioId negativo original. Si _updateServiceId ya lo actualizó,
          // tendrá servicioId positivo y podemos obtenerlo directamente
          final seWithOriginalId = await db.query(
            'servicio_extintor',
            where: 'servicioId = ? AND extintorId = ?',
            whereArgs: [originalServicioId, extintorId],
            orderBy: 'createdAt DESC',
            limit: 1,
          );

          if (seWithOriginalId.isNotEmpty) {
            final seServicioId = seWithOriginalId.first['servicioId'] as int;
            // Si el servicioId ya es positivo, significa que _updateServiceId ya lo actualizó
            if (seServicioId > 0) {
              realServicioId = seServicioId;
            } else {
              // Aún tiene servicioId negativo, buscar el servicio temporal y su sincronizado
              final tempService = await db.query(
                'servicio',
                where: 'id = ?',
                whereArgs: [originalServicioId],
                limit: 1,
              );

              if (tempService.isNotEmpty) {
                // Buscar el servicio sincronizado por campos exactos
                final serviceType = tempService.first['type'] as String;
                final dateStart = tempService.first['dateStart'] as String;
                final serviceSedeId = tempService.first['sedeId'] as int;

                final syncedService = await db.query(
                  'servicio',
                  where: 'type = ? AND dateStart = ? AND sedeId = ? AND id > 0',
                  whereArgs: [serviceType, dateStart, serviceSedeId],
                  limit: 1,
                );

                if (syncedService.isNotEmpty) {
                  realServicioId = syncedService.first['id'] as int;
                }
              }
            }
          } else {
            // No encontramos servicio_extintor con servicioId negativo original
            // Puede que ya fue actualizado o eliminado. Buscar por extintorId y servicioId positivo
            final seWithPositive = await db.query(
              'servicio_extintor',
              where: 'extintorId = ? AND servicioId > 0',
              whereArgs: [extintorId],
              orderBy: 'createdAt DESC',
              limit: 5,
            );

            // Buscar el servicio que corresponde verificando el createdAt
            for (final se in seWithPositive) {
              final seServicioId = se['servicioId'] as int;
              final seCreatedAt = se['createdAt'] as String;

              final servicio = await db.query(
                'servicio',
                where: 'id = ?',
                whereArgs: [seServicioId],
                limit: 1,
              );

              if (servicio.isNotEmpty) {
                final servicioCreatedAt = servicio.first['createdAt'] as String;
                final seTime = DateTime.parse(seCreatedAt);
                final servicioTime = DateTime.parse(servicioCreatedAt);
                final diff = seTime.difference(servicioTime).abs().inSeconds;

                // Si el servicio fue creado cerca del servicio_extintor (dentro de 5 segundos)
                if (diff <= 5) {
                  realServicioId = seServicioId;
                  break;
                }
              }
            }
          }

          // Fallback: usar _findRealServiceId si aún no encontramos
          if (realServicioId == null) {
            final tempService = await db.query(
              'servicio',
              where: 'id = ?',
              whereArgs: [originalServicioId],
              limit: 1,
            );

            String? serviceType;
            int? serviceSedeId;
            if (tempService.isNotEmpty) {
              serviceType = tempService.first['type'] as String?;
              serviceSedeId = tempService.first['sedeId'] as int?;
            }

            realServicioId = await _findRealServiceId(
              originalServicioId,
              db,
              type: serviceType,
              sedeId: serviceSedeId,
            );
          }

          if (realServicioId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio padre aún no está sincronizado',
            );
            return false;
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

        try {
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
          // buscar con el servicioId positivo mapeado que acabamos de encontrar
          if (tempServiceExtinguisherId == null &&
              servicioId > 0 &&
              originalServicioId < 0) {
            // Buscar servicio_extintor que tenga el servicioId positivo mapeado y el extintorId,
            // y que aún tenga ID negativo (no sincronizado)
            final seWithPositive = await db.query(
              'servicio_extintor',
              where: 'servicioId = ? AND extintorId = ? AND id < 0',
              whereArgs: [servicioId, data['extintorId'] as int],
              limit: 1,
            );
            if (seWithPositive.isNotEmpty) {
              tempServiceExtinguisherId = seWithPositive.first['id'] as int;
            } else {
              // Si tampoco se encuentra, buscar cualquier servicio_extintor con este extintorId
              // que tenga ID negativo y que haya sido creado recientemente
              // Esto maneja el caso donde _updateServiceId ya actualizó el servicioId
              final seAny = await db.query(
                'servicio_extintor',
                where: 'extintorId = ? AND id < 0',
                whereArgs: [data['extintorId'] as int],
                orderBy: 'createdAt DESC',
                limit: 5,
              );

              // Buscar el que corresponde al servicioId mapeado
              for (final se in seAny) {
                final seServicioId = se['servicioId'] as int;
                // Si el servicioId coincide con el mapeado, usar este
                if (seServicioId == servicioId) {
                  tempServiceExtinguisherId = se['id'] as int;
                  break;
                }
              }
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
        } on DioException catch (e) {
          // Si el error es que el extintor ya está agregado, buscar el registro existente
          final errorMessage = e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message'] as String?
              : e.message;

          if (errorMessage != null &&
              (errorMessage.toLowerCase().contains('ya está agregado') ||
                  errorMessage.toLowerCase().contains('duplicate') ||
                  errorMessage.toLowerCase().contains('unique'))) {
            // El extintor ya está agregado en el servidor
            // Buscar el servicio_extintor existente en la base de datos local
            final existing = await db.query(
              'servicio_extintor',
              where: 'servicioId = ? AND extintorId = ? AND id > 0',
              whereArgs: [servicioId, extintorId],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              // Ya existe un registro sincronizado, actualizar el temporal si existe
              final existingId = existing.first['id'] as int;
              final originalServicioId = data['servicioId'] as int;
              int? tempServiceExtinguisherId =
                  await _findTempServiceExtinguisherId(
                    originalServicioId,
                    data['extintorId'] as int,
                    db,
                  );

              if (tempServiceExtinguisherId != null &&
                  tempServiceExtinguisherId != existingId) {
                // Eliminar el registro temporal duplicado
                await db.delete(
                  'servicio_extintor',
                  where: 'id = ?',
                  whereArgs: [tempServiceExtinguisherId],
                );
              }

              // Eliminar de la cola porque ya existe en el servidor
              await _localDataSource.deleteQueueItem(queueId);
              return true;
            } else {
              // No encontrado localmente, guardar error pero no bloquear
              await _localDataSource.updateSyncError(
                queueId,
                'Este extintor ya está agregado al servicio (existe en el servidor)',
              );
              return false;
            }
          } else {
            // Otro tipo de error, guardar normalmente
            await _localDataSource.updateSyncError(queueId, e.toString());
            return false;
          }
        } catch (e) {
          await _localDataSource.updateSyncError(queueId, e.toString());
          return false;
        }
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
      } else if (type == 'CREATE_INSPECTION_DETAIL') {
        final originalServicioExtintorId = data['servicioExtintorId'] as int;
        var servicioExtintorId = originalServicioExtintorId;

        if (servicioExtintorId < 0) {
          final realServicioExtinguisherId =
              await _findRealServiceExtinguisherId(servicioExtintorId, db);
          if (realServicioExtinguisherId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio_extintor padre aún no está sincronizado',
            );
            return false;
          }
          servicioExtintorId = realServicioExtinguisherId;
        }

        // Convertir paths locales a Files si existen
        File? foto1File;
        File? foto2File;
        File? foto3File;

        final foto1Path = data['foto1Path'] as String?;
        final foto2Path = data['foto2Path'] as String?;
        final foto3Path = data['foto3Path'] as String?;

        if (foto1Path != null && File(foto1Path).existsSync()) {
          foto1File = File(foto1Path);
        }
        if (foto2Path != null && File(foto2Path).existsSync()) {
          foto2File = File(foto2Path);
        }
        if (foto3Path != null && File(foto3Path).existsSync()) {
          foto3File = File(foto3Path);
        }

        final inspectionData = <String, dynamic>{
          'foto1Url': data['foto1Url'] as String?,
          'foto2Url': data['foto2Url'] as String?,
          'foto3Url': data['foto3Url'] as String?,
          'accesibilidad': data['accesibilidad'],
          'observaciones': data['observaciones'],
          'ubicacion': data['ubicacion'],
          'instalacion': data['instalacion'],
          'instrucciones': data['instrucciones'],
          'clasificacion': data['clasificacion'],
          'recarga': data['recarga'],
          'certificacion': data['certificacion'],
          'presion': data['presion'],
          'seguridad': data['seguridad'],
          'estado': data['estado'],
          'carga': data['carga'],
          'soporte': data['soporte'],
          'activacion': data['activacion'],
          'manguera': data['manguera'],
          'boquilla': data['boquilla'],
          'abrazadera': data['abrazadera'],
        };

        // Agregar Files si existen (se subirán junto con el checklist)
        if (foto1File != null) inspectionData['foto1'] = foto1File;
        if (foto2File != null) inspectionData['foto2'] = foto2File;
        if (foto3File != null) inspectionData['foto3'] = foto3File;

        final inspectionDetail = await _httpDataSource.createInspectionDetail(
          servicioExtintorId: servicioExtintorId,
          data: inspectionData,
        );

        // Buscar el inspeccion_detalle temporal usando el servicioExtintorId original (negativo) del payload
        int? tempInspectionDetailId = await _findTempInspectionDetailId(
          originalServicioExtintorId, // Usar el ID original del payload
          db,
        );

        // Si no se encuentra con servicioExtintorId negativo (porque ya fue actualizado por _updateServiceExtinguisherId),
        // buscar con el servicioExtintorId positivo mapeado
        if (tempInspectionDetailId == null &&
            servicioExtintorId > 0 &&
            originalServicioExtintorId < 0) {
          final idWithPositive = await db.query(
            'inspeccion_detalle',
            where: 'servicioExtintorId = ? AND id < 0',
            whereArgs: [servicioExtintorId],
            limit: 1,
          );
          if (idWithPositive.isNotEmpty) {
            tempInspectionDetailId = idWithPositive.first['id'] as int;
          }
        }

        if (tempInspectionDetailId != null) {
          await _updateInspectionDetailId(
            db,
            tempInspectionDetailId,
            inspectionDetail.id,
            inspectionDetailFromServer: inspectionDetail,
          );
        }
        await _localDataSource.deleteQueueItem(queueId);
        return true;
      } else if (type == 'UPDATE_INSPECTION_DETAIL') {
        var servicioExtintorId = data['servicioExtintorId'] as int;

        // Mapear servicioExtintorId negativo a positivo si es necesario
        if (servicioExtintorId < 0) {
          final realServicioExtinguisherId =
              await _findRealServiceExtinguisherId(servicioExtintorId, db);
          if (realServicioExtinguisherId == null) {
            await _localDataSource.updateSyncError(
              queueId,
              'El servicio_extintor padre aún no está sincronizado',
            );
            return false;
          }
          servicioExtintorId = realServicioExtinguisherId;
        }

        // Convertir paths locales a Files si existen
        File? foto1File;
        File? foto2File;
        File? foto3File;

        final foto1Path = data['foto1Path'] as String?;
        final foto2Path = data['foto2Path'] as String?;
        final foto3Path = data['foto3Path'] as String?;

        if (foto1Path != null && File(foto1Path).existsSync()) {
          foto1File = File(foto1Path);
        }
        if (foto2Path != null && File(foto2Path).existsSync()) {
          foto2File = File(foto2Path);
        }
        if (foto3Path != null && File(foto3Path).existsSync()) {
          foto3File = File(foto3Path);
        }

        final inspectionData = <String, dynamic>{
          'foto1Url': data['foto1Url'] as String?,
          'foto2Url': data['foto2Url'] as String?,
          'foto3Url': data['foto3Url'] as String?,
          'accesibilidad': data['accesibilidad'],
          'observaciones': data['observaciones'],
          'ubicacion': data['ubicacion'],
          'instalacion': data['instalacion'],
          'instrucciones': data['instrucciones'],
          'clasificacion': data['clasificacion'],
          'recarga': data['recarga'],
          'certificacion': data['certificacion'],
          'presion': data['presion'],
          'seguridad': data['seguridad'],
          'estado': data['estado'],
          'carga': data['carga'],
          'soporte': data['soporte'],
          'activacion': data['activacion'],
          'manguera': data['manguera'],
          'boquilla': data['boquilla'],
          'abrazadera': data['abrazadera'],
        };

        // Agregar Files si existen (se subirán junto con el checklist)
        if (foto1File != null) inspectionData['foto1'] = foto1File;
        if (foto2File != null) inspectionData['foto2'] = foto2File;
        if (foto3File != null) inspectionData['foto3'] = foto3File;

        final updatedInspectionDetail = await _httpDataSource
            .updateInspectionDetail(
              servicioExtintorId: servicioExtintorId,
              data: inspectionData,
            );

        // Actualizar localmente con las URLs del servidor
        await _localDataSource.updateInspectionDetail(
          servicioExtintorId: servicioExtintorId,
          inspectionData: {
            ...inspectionData,
            'foto1Url': updatedInspectionDetail.foto1Url,
            'foto2Url': updatedInspectionDetail.foto2Url,
            'foto3Url': updatedInspectionDetail.foto3Url,
            // Limpiar paths locales después de sincronizar (ya no son necesarios)
            'foto1Path': null,
            'foto2Path': null,
            'foto3Path': null,
          },
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
