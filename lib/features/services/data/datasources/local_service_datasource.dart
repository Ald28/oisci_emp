import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/database/app_database.dart';
import '../models/service_model.dart';
import '../models/service_extinguisher_model.dart';
import '../models/maintenance_detail_model.dart';
import '../models/inspection_detail_model.dart';

/// DataSource local usando SQLite para almacenar servicios
class LocalServiceDataSource {
  /// Crear servicio (Etapa 1)
  Future<ServiceModel> createService({
    required String type,
    required DateTime dateStart,
    required int sedeId,
    required int userId,
  }) async {
    final db = await AppDatabase.database;
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception('No se encontró el ID del usuario en la sesión');
    }

    final usuarioCreadorId = int.parse(userIdStr);
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;

    await db.insert('servicio', {
      'id': tempId,
      'type': type,
      'dateStart': dateStart.toIso8601String(),
      'dateEnd': null,
      'sincronizado': 0,
      'status': 'EN_PROCESO',
      'statusValid': 'APROBADO',
      'historic': null,
      'sedeId': sedeId,
      'userId': userId,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'synced': 0,
    });

    // Agregar a sync_queue
    await db.insert('sync_queue', {
      'type': 'CREATE_SERVICE',
      'payload': jsonEncode({
        'type': type,
        'dateStart': dateStart.toIso8601String(),
        'sedeId': sedeId,
        'userId': userId,
      }),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    return ServiceModel(
      id: tempId,
      type: type,
      dateStart: dateStart,
      status: 'EN_PROCESO',
      sedeId: sedeId,
      userId: userId,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
      sincronizado: false,
    );
  }

  /// Obtener servicio por ID
  Future<ServiceModel?> getServiceById(int id) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'servicio',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServiceModel.fromMap(result.first);
  }

  /// Obtener servicio en proceso por tipo
  Future<ServiceModel?> getServiceInProgress(String type) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'servicio',
      where: 'type = ? AND status = ?',
      whereArgs: [type, 'EN_PROCESO'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServiceModel.fromMap(result.first);
  }

  /// Obtener todos los servicios en proceso (para notificaciones offline)
  Future<List<ServiceModel>> getServicesInProgress() async {
    final db = await AppDatabase.database;
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      return [];
    }

    final usuarioCreadorId = int.parse(userIdStr);
    final results = await db.query(
      'servicio',
      where: 'status = ? AND usuarioCreadorId = ?',
      whereArgs: ['EN_PROCESO', usuarioCreadorId],
      orderBy: 'createdAt DESC',
    );

    return results.map((map) => ServiceModel.fromMap(map)).toList();
  }

  /// Guardar servicio sincronizado desde el servidor (sin agregar a sync_queue)
  Future<void> saveService(ServiceModel service) async {
    final db = await AppDatabase.database;
    await db.insert(
      'servicio',
      ServiceModel(
        id: service.id,
        type: service.type,
        dateStart: service.dateStart,
        dateEnd: service.dateEnd,
        status: service.status,
        statusValid: service.statusValid,
        historic: service.historic,
        sedeId: service.sedeId,
        userId: service.userId,
        usuarioCreadorId: service.usuarioCreadorId,
        usuarioActualizadorId: service.usuarioActualizadorId,
        createdAt: service.createdAt,
        updatedAt: service.updatedAt,
        sincronizado: true,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualizar servicio después de sincronización
  Future<void> updateServiceAfterSync({
    required int tempId,
    required ServiceModel service,
  }) async {
    final db = await AppDatabase.database;
    await db.update(
      'servicio',
      ServiceModel(
        id: service.id,
        type: service.type,
        dateStart: service.dateStart,
        dateEnd: service.dateEnd,
        status: service.status,
        statusValid: service.statusValid,
        historic: service.historic,
        sedeId: service.sedeId,
        userId: service.userId,
        usuarioCreadorId: service.usuarioCreadorId,
        usuarioActualizadorId: service.usuarioActualizadorId,
        createdAt: service.createdAt,
        updatedAt: service.updatedAt,
        sincronizado: true,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  /// Finalizar servicio (actualizar status a FINALIZADO y dateEnd)
  /// Si addToSyncQueue es true, agrega a sync_queue para sincronización offline
  Future<void> finalizeService(
    int servicioId, {
    bool addToSyncQueue = true,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();
    await db.update(
      'servicio',
      {
        'status': 'FINALIZADO',
        'dateEnd': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [servicioId],
    );

    // Agregar a sync_queue para sincronización offline solo si se solicita
    if (addToSyncQueue) {
      await db.insert('sync_queue', {
        'type': 'FINALIZE_SERVICE',
        'payload': jsonEncode({'servicioId': servicioId}),
        'createdAt': now.toIso8601String(),
        'lastSyncError': null,
        'syncAttempts': 0,
        'lastSyncAttempt': null,
      });
    }
  }

  /// Crear ServicioExtintor (Etapa 2)
  Future<ServiceExtinguisherModel> createServiceExtinguisher({
    required int servicioId,
    required int extintorId,
    String? estadoInicial,
    String? observaciones,
  }) async {
    final db = await AppDatabase.database;

    // Verificar si el extintor ya está agregado al servicio
    final existing = await getServiceExtinguisherByServiceAndExtinguisher(
      servicioId: servicioId,
      extintorId: extintorId,
    );

    if (existing != null) {
      throw Exception('Este extintor ya está agregado al servicio');
    }

    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception('No se encontró el ID del usuario en la sesión');
    }

    final usuarioCreadorId = int.parse(userIdStr);
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;

    try {
      await db.insert('servicio_extintor', {
        'id': tempId,
        'servicioId': servicioId,
        'extintorId': extintorId,
        'estadoInicial': estadoInicial,
        'estadoFinal': null,
        'completado': 0,
        'observaciones': observaciones,
        'usuarioCreadorId': usuarioCreadorId,
        'usuarioActualizadorId': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'synced': 0,
      });
    } catch (e) {
      // Capturar error de UNIQUE constraint y lanzar mensaje amigable
      if (e.toString().contains('UNIQUE constraint') ||
          e.toString().contains('SQLITE_CONSTRAINT_UNIQUE')) {
        throw Exception('Este extintor ya está agregado al servicio');
      }
      rethrow;
    }

    // Agregar a sync_queue
    await db.insert('sync_queue', {
      'type': 'CREATE_SERVICE_EXTINGUISHER',
      'payload': jsonEncode({
        'servicioId': servicioId,
        'extintorId': extintorId,
        'estadoInicial': estadoInicial,
        'observaciones': observaciones,
      }),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    return ServiceExtinguisherModel(
      id: tempId,
      servicioId: servicioId,
      extintorId: extintorId,
      estadoInicial: estadoInicial,
      observaciones: observaciones,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Obtener ServicioExtintor por ID
  Future<ServiceExtinguisherModel?> getServiceExtinguisherById(int id) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'servicio_extintor',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServiceExtinguisherModel.fromMap(result.first);
  }

  /// Obtener ServicioExtintor por servicioId y extintorId
  Future<ServiceExtinguisherModel?>
  getServiceExtinguisherByServiceAndExtinguisher({
    required int servicioId,
    required int extintorId,
  }) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'servicio_extintor',
      where: 'servicioId = ? AND extintorId = ?',
      whereArgs: [servicioId, extintorId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ServiceExtinguisherModel.fromMap(result.first);
  }

  /// Guardar ServicioExtintor sincronizado desde el servidor (sin agregar a sync_queue)
  Future<void> saveServiceExtinguisher(
    ServiceExtinguisherModel serviceExtinguisher,
  ) async {
    final db = await AppDatabase.database;
    await db.insert(
      'servicio_extintor',
      ServiceExtinguisherModel(
        id: serviceExtinguisher.id,
        servicioId: serviceExtinguisher.servicioId,
        extintorId: serviceExtinguisher.extintorId,
        estadoInicial: serviceExtinguisher.estadoInicial,
        estadoFinal: serviceExtinguisher.estadoFinal,
        completado: serviceExtinguisher.completado,
        observaciones: serviceExtinguisher.observaciones,
        usuarioCreadorId: serviceExtinguisher.usuarioCreadorId,
        usuarioActualizadorId: serviceExtinguisher.usuarioActualizadorId,
        createdAt: serviceExtinguisher.createdAt,
        updatedAt: serviceExtinguisher.updatedAt,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualizar ServicioExtintor después de sincronización
  Future<void> updateServiceExtinguisherAfterSync({
    required int tempId,
    required ServiceExtinguisherModel serviceExtinguisher,
  }) async {
    final db = await AppDatabase.database;
    await db.update(
      'servicio_extintor',
      ServiceExtinguisherModel(
        id: serviceExtinguisher.id,
        servicioId: serviceExtinguisher.servicioId,
        extintorId: serviceExtinguisher.extintorId,
        estadoInicial: serviceExtinguisher.estadoInicial,
        estadoFinal: serviceExtinguisher.estadoFinal,
        completado: serviceExtinguisher.completado,
        observaciones: serviceExtinguisher.observaciones,
        usuarioCreadorId: serviceExtinguisher.usuarioCreadorId,
        usuarioActualizadorId: serviceExtinguisher.usuarioActualizadorId,
        createdAt: serviceExtinguisher.createdAt,
        updatedAt: serviceExtinguisher.updatedAt,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  /// Marcar ServicioExtintor como completado
  Future<void> markServiceExtinguisherCompleted(int servicioExtintorId) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();
    await db.update(
      'servicio_extintor',
      {'completado': 1, 'updatedAt': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [servicioExtintorId],
    );
  }

  /// Crear MantenimientoDetalle (Etapa 3)
  Future<MaintenanceDetailModel> createMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  }) async {
    final db = await AppDatabase.database;
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception('No se encontró el ID del usuario en la sesión');
    }

    final usuarioCreadorId = int.parse(userIdStr);
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;

    await db.insert('mantenimiento_detalle', {
      'id': tempId,
      'servicioExtintorId': servicioExtintorId,
      'mantenimiento': (checklistData['mantenimiento'] as bool? ?? false)
          ? 1
          : 0,
      'recarga': (checklistData['recarga'] as bool? ?? false) ? 1 : 0,
      'agenteCarga': checklistData['agenteCarga'] as String?,
      'pruebaHidrostatica':
          (checklistData['pruebaHidrostatica'] as bool? ?? false) ? 1 : 0,
      'bajaExtintor': (checklistData['bajaExtintor'] as bool? ?? false) ? 1 : 0,
      'motivoBaja': checklistData['motivoBaja'] as String?,
      'pintura': (checklistData['pintura'] as bool? ?? false) ? 1 : 0,
      'recargaCartucho': (checklistData['recargaCartucho'] as bool? ?? false)
          ? 1
          : 0,
      'cambioPartes': (checklistData['cambioPartes'] as bool? ?? false) ? 1 : 0,
      'detallesCambioPartes': checklistData['detallesCambioPartes'] as String?,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'synced': 0,
    });

    // Agregar a sync_queue
    await db.insert('sync_queue', {
      'type': 'CREATE_MAINTENANCE_DETAIL',
      'payload': jsonEncode({
        'servicioExtintorId': servicioExtintorId,
        ...checklistData,
      }),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    return MaintenanceDetailModel(
      id: tempId,
      servicioExtintorId: servicioExtintorId,
      mantenimiento: checklistData['mantenimiento'] as bool? ?? false,
      recarga: checklistData['recarga'] as bool? ?? false,
      agenteCarga: checklistData['agenteCarga'] as String?,
      pruebaHidrostatica: checklistData['pruebaHidrostatica'] as bool? ?? false,
      bajaExtintor: checklistData['bajaExtintor'] as bool? ?? false,
      motivoBaja: checklistData['motivoBaja'] as String?,
      pintura: checklistData['pintura'] as bool? ?? false,
      recargaCartucho: checklistData['recargaCartucho'] as bool? ?? false,
      cambioPartes: checklistData['cambioPartes'] as bool? ?? false,
      detallesCambioPartes: checklistData['detallesCambioPartes'] as String?,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Obtener MantenimientoDetalle por servicioExtintorId
  Future<MaintenanceDetailModel?> getMaintenanceDetailByServiceExtinguisherId(
    int servicioExtintorId,
  ) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'mantenimiento_detalle',
      where: 'servicioExtintorId = ?',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return MaintenanceDetailModel.fromMap(result.first);
  }

  /// Actualizar MantenimientoDetalle
  /// Si addToSyncQueue es true, agrega a sync_queue para sincronización offline
  Future<MaintenanceDetailModel> updateMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
    bool addToSyncQueue = true,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();

    // Buscar el mantenimiento existente
    final existing = await db.query(
      'mantenimiento_detalle',
      where: 'servicioExtintorId = ?',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw Exception('MantenimientoDetalle no encontrado');
    }

    final mantenimientoId = existing.first['id'] as int;

    // Actualizar el registro
    await db.update(
      'mantenimiento_detalle',
      {
        'mantenimiento': (checklistData['mantenimiento'] as bool? ?? false)
            ? 1
            : 0,
        'recarga': (checklistData['recarga'] as bool? ?? false) ? 1 : 0,
        'agenteCarga': checklistData['agenteCarga'] as String?,
        'pruebaHidrostatica':
            (checklistData['pruebaHidrostatica'] as bool? ?? false) ? 1 : 0,
        'bajaExtintor': (checklistData['bajaExtintor'] as bool? ?? false)
            ? 1
            : 0,
        'motivoBaja': checklistData['motivoBaja'] as String?,
        'pintura': (checklistData['pintura'] as bool? ?? false) ? 1 : 0,
        'recargaCartucho': (checklistData['recargaCartucho'] as bool? ?? false)
            ? 1
            : 0,
        'cambioPartes': (checklistData['cambioPartes'] as bool? ?? false)
            ? 1
            : 0,
        'detallesCambioPartes':
            checklistData['detallesCambioPartes'] as String?,
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [mantenimientoId],
    );

    // Obtener el registro actualizado
    final updated = await db.query(
      'mantenimiento_detalle',
      where: 'id = ?',
      whereArgs: [mantenimientoId],
      limit: 1,
    );

    // Agregar a sync_queue para sincronización offline si el mantenimiento_detalle ya existe en el servidor
    // (solo agregar si el id es positivo, es decir, ya fue sincronizado antes) y si se solicita
    if (addToSyncQueue && mantenimientoId > 0) {
      await db.insert('sync_queue', {
        'type': 'UPDATE_MAINTENANCE_DETAIL',
        'payload': jsonEncode({
          'servicioExtintorId': servicioExtintorId,
          ...checklistData,
        }),
        'createdAt': now.toIso8601String(),
        'lastSyncError': null,
        'syncAttempts': 0,
        'lastSyncAttempt': null,
      });
    }

    return MaintenanceDetailModel.fromMap(updated.first);
  }

  /// Guardar MantenimientoDetalle sincronizado desde el servidor (sin agregar a sync_queue)
  Future<void> saveMaintenanceDetail(
    MaintenanceDetailModel maintenanceDetail,
  ) async {
    final db = await AppDatabase.database;
    await db.insert(
      'mantenimiento_detalle',
      MaintenanceDetailModel(
        id: maintenanceDetail.id,
        servicioExtintorId: maintenanceDetail.servicioExtintorId,
        mantenimiento: maintenanceDetail.mantenimiento,
        recarga: maintenanceDetail.recarga,
        agenteCarga: maintenanceDetail.agenteCarga,
        pruebaHidrostatica: maintenanceDetail.pruebaHidrostatica,
        bajaExtintor: maintenanceDetail.bajaExtintor,
        motivoBaja: maintenanceDetail.motivoBaja,
        pintura: maintenanceDetail.pintura,
        recargaCartucho: maintenanceDetail.recargaCartucho,
        cambioPartes: maintenanceDetail.cambioPartes,
        detallesCambioPartes: maintenanceDetail.detallesCambioPartes,
        usuarioCreadorId: maintenanceDetail.usuarioCreadorId,
        usuarioActualizadorId: maintenanceDetail.usuarioActualizadorId,
        createdAt: maintenanceDetail.createdAt,
        updatedAt: maintenanceDetail.updatedAt,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualizar MantenimientoDetalle después de sincronización
  Future<void> updateMaintenanceDetailAfterSync({
    required int tempId,
    required MaintenanceDetailModel maintenanceDetail,
  }) async {
    final db = await AppDatabase.database;
    await db.update(
      'mantenimiento_detalle',
      MaintenanceDetailModel(
        id: maintenanceDetail.id,
        servicioExtintorId: maintenanceDetail.servicioExtintorId,
        mantenimiento: maintenanceDetail.mantenimiento,
        recarga: maintenanceDetail.recarga,
        agenteCarga: maintenanceDetail.agenteCarga,
        pruebaHidrostatica: maintenanceDetail.pruebaHidrostatica,
        bajaExtintor: maintenanceDetail.bajaExtintor,
        motivoBaja: maintenanceDetail.motivoBaja,
        pintura: maintenanceDetail.pintura,
        recargaCartucho: maintenanceDetail.recargaCartucho,
        cambioPartes: maintenanceDetail.cambioPartes,
        detallesCambioPartes: maintenanceDetail.detallesCambioPartes,
        usuarioCreadorId: maintenanceDetail.usuarioCreadorId,
        usuarioActualizadorId: maintenanceDetail.usuarioActualizadorId,
        createdAt: maintenanceDetail.createdAt,
        updatedAt: maintenanceDetail.updatedAt,
      ).toMap(),
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  /// Obtener items pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingSyncItems(String type) async {
    final db = await AppDatabase.database;
    return await db.query(
      'sync_queue',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'createdAt ASC',
    );
  }

  /// Eliminar item de la cola de sincronización
  Future<void> deleteQueueItem(int id) async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Actualizar error de sincronización
  Future<void> updateSyncError(int id, String error) async {
    final db = await AppDatabase.database;
    final current = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (current.isNotEmpty) {
      final currentAttempts = current.first['syncAttempts'] as int? ?? 0;
      await db.update(
        'sync_queue',
        {
          'lastSyncError': error,
          'syncAttempts': currentAttempts + 1,
          'lastSyncAttempt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Actualizar observaciones de ServicioExtintor
  /// Si addToSyncQueue es true, agrega a sync_queue para sincronización offline
  Future<void> updateServiceExtinguisherObservations({
    required int servicioExtintorId,
    required String? observaciones,
    bool addToSyncQueue = true,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();

    // Verificar si el servicio_extintor existe
    final existing = await db.query(
      'servicio_extintor',
      where: 'id = ?',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw Exception('ServicioExtintor no encontrado');
    }

    // Actualizar el registro
    await db.update(
      'servicio_extintor',
      {'observaciones': observaciones, 'updatedAt': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [servicioExtintorId],
    );

    // Agregar a sync_queue para sincronización offline si se solicita
    // Solo agregar si hay observaciones (no vacías ni null)
    // Se agrega incluso si el ID es negativo, porque cuando se sincronice el servicio_extintor,
    // se actualizará la referencia en sync_queue
    if (addToSyncQueue &&
        observaciones != null &&
        observaciones.trim().isNotEmpty) {
      await db.insert('sync_queue', {
        'type': 'UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS',
        'payload': jsonEncode({
          'servicioExtintorId': servicioExtintorId,
          'observaciones': observaciones,
        }),
        'createdAt': now.toIso8601String(),
        'lastSyncError': null,
        'syncAttempts': 0,
        'lastSyncAttempt': null,
      });
    }
  }

  /// Obtener todos los ServicioExtintor por servicioId (con información del extintor)
  Future<List<Map<String, dynamic>>> getServiceExtinguishersByServiceId(
    int servicioId,
  ) async {
    final db = await AppDatabase.database;

    // JOIN entre servicio_extintor y extintor
    final results = await db.rawQuery(
      '''
      SELECT 
        se.*,
        e.serialNumber,
        e.location,
        e.cylinderNumber,
        e.type,
        e.agent,
        e.capacity,
        e.status as extintorStatus
      FROM servicio_extintor se
      LEFT JOIN extintor e ON se.extintorId = e.id
      WHERE se.servicioId = ?
      ORDER BY se.createdAt ASC
    ''',
      [servicioId],
    );

    return results;
  }

  /// Crear InspeccionDetalle (offline - agrega a sync_queue)
  Future<InspectionDetailModel> createInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
  }) async {
    final db = await AppDatabase.database;
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception('No se encontró el ID del usuario en la sesión');
    }

    final usuarioCreadorId = int.parse(userIdStr);
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;

    await db.insert('inspeccion_detalle', {
      'id': tempId,
      'servicioExtintorId': servicioExtintorId,
      'foto1Url': inspectionData['foto1Url'] as String?,
      'foto2Url': inspectionData['foto2Url'] as String?,
      'foto3Url': inspectionData['foto3Url'] as String?,
      'foto1Path': inspectionData['foto1Path'] as String?,
      'foto2Path': inspectionData['foto2Path'] as String?,
      'foto3Path': inspectionData['foto3Path'] as String?,
      'accesibilidad': inspectionData['accesibilidad'] as String?,
      'observaciones': inspectionData['observaciones'] as String?,
      'ubicacion': inspectionData['ubicacion'] as String?,
      'instalacion': inspectionData['instalacion'] as String?,
      'instrucciones': inspectionData['instrucciones'] as String?,
      'clasificacion': inspectionData['clasificacion'] as String?,
      'recarga': inspectionData['recarga'] as String?,
      'certificacion': inspectionData['certificacion'] as String?,
      'presion': inspectionData['presion'] as String?,
      'seguridad': inspectionData['seguridad'] as String?,
      'estado': inspectionData['estado'] as String?,
      'carga': inspectionData['carga'] as String?,
      'soporte': inspectionData['soporte'] as String?,
      'activacion': inspectionData['activacion'] as String?,
      'manguera': inspectionData['manguera'] as String?,
      'boquilla': inspectionData['boquilla'] as String?,
      'abrazadera': inspectionData['abrazadera'] as String?,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'synced': 0,
    });

    // Si hay foto1Url o foto1Path, actualizar también Extintor.photo y photoPath
    final foto1Url = inspectionData['foto1Url'] as String?;
    final foto1Path = inspectionData['foto1Path'] as String?;
    if ((foto1Url != null && foto1Url.isNotEmpty) ||
        (foto1Path != null && foto1Path.isNotEmpty)) {
      await _updateExtinguisherPhotoFromServicioExtintorId(
        db,
        servicioExtintorId,
        foto1Url ?? '',
        foto1Path,
      );
    }

    // Agregar a sync_queue
    await db.insert('sync_queue', {
      'type': 'CREATE_INSPECTION_DETAIL',
      'payload': jsonEncode({
        'servicioExtintorId': servicioExtintorId,
        ...inspectionData,
      }),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    return InspectionDetailModel(
      id: tempId,
      servicioExtintorId: servicioExtintorId,
      foto1Url: inspectionData['foto1Url'] as String?,
      foto2Url: inspectionData['foto2Url'] as String?,
      foto3Url: inspectionData['foto3Url'] as String?,
      accesibilidad: inspectionData['accesibilidad'] as String?,
      observaciones: inspectionData['observaciones'] as String?,
      ubicacion: inspectionData['ubicacion'] as String?,
      instalacion: inspectionData['instalacion'] as String?,
      instrucciones: inspectionData['instrucciones'] as String?,
      clasificacion: inspectionData['clasificacion'] as String?,
      recarga: inspectionData['recarga'] as String?,
      certificacion: inspectionData['certificacion'] as String?,
      presion: inspectionData['presion'] as String?,
      seguridad: inspectionData['seguridad'] as String?,
      estado: inspectionData['estado'] as String?,
      carga: inspectionData['carga'] as String?,
      soporte: inspectionData['soporte'] as String?,
      activacion: inspectionData['activacion'] as String?,
      manguera: inspectionData['manguera'] as String?,
      boquilla: inspectionData['boquilla'] as String?,
      abrazadera: inspectionData['abrazadera'] as String?,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Obtener InspeccionDetalle por servicioExtintorId
  Future<InspectionDetailModel?> getInspectionDetailByServiceExtinguisherId(
    int servicioExtintorId,
  ) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'inspeccion_detalle',
      where: 'servicioExtintorId = ?',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return InspectionDetailModel.fromMap(result.first);
  }

  /// Actualizar InspeccionDetalle
  /// Si addToSyncQueue es true, agrega a sync_queue para sincronización offline
  Future<InspectionDetailModel> updateInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> inspectionData,
    bool addToSyncQueue = true,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();

    // Buscar la inspección existente
    final existing = await db.query(
      'inspeccion_detalle',
      where: 'servicioExtintorId = ?',
      whereArgs: [servicioExtintorId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw Exception('InspeccionDetalle no encontrado');
    }

    final inspeccionId = existing.first['id'] as int;

    // Actualizar el registro (solo con campos que existen en el schema actual)
    await db.update(
      'inspeccion_detalle',
      {
        'foto1Url': inspectionData['foto1Url'] as String?,
        'foto2Url': inspectionData['foto2Url'] as String?,
        'foto3Url': inspectionData['foto3Url'] as String?,
        'foto1Path': inspectionData['foto1Path'] as String?,
        'foto2Path': inspectionData['foto2Path'] as String?,
        'foto3Path': inspectionData['foto3Path'] as String?,
        'accesibilidad': inspectionData['accesibilidad'] as String?,
        'observaciones': inspectionData['observaciones'] as String?,
        'ubicacion': inspectionData['ubicacion'] as String?,
        'instalacion': inspectionData['instalacion'] as String?,
        'instrucciones': inspectionData['instrucciones'] as String?,
        'clasificacion': inspectionData['clasificacion'] as String?,
        'recarga': inspectionData['recarga'] as String?,
        'certificacion': inspectionData['certificacion'] as String?,
        'presion': inspectionData['presion'] as String?,
        'seguridad': inspectionData['seguridad'] as String?,
        'estado': inspectionData['estado'] as String?,
        'carga': inspectionData['carga'] as String?,
        'soporte': inspectionData['soporte'] as String?,
        'activacion': inspectionData['activacion'] as String?,
        'manguera': inspectionData['manguera'] as String?,
        'boquilla': inspectionData['boquilla'] as String?,
        'abrazadera': inspectionData['abrazadera'] as String?,
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [inspeccionId],
    );

    // Si hay foto1Url o foto1Path, actualizar también Extintor.photo y photoPath
    final foto1Url = inspectionData['foto1Url'] as String?;
    final foto1Path = inspectionData['foto1Path'] as String?;
    if ((foto1Url != null && foto1Url.isNotEmpty) ||
        (foto1Path != null && foto1Path.isNotEmpty)) {
      await _updateExtinguisherPhotoFromServicioExtintorId(
        db,
        servicioExtintorId,
        foto1Url ?? '',
        foto1Path,
      );
    }

    // Obtener el registro actualizado
    final updated = await db.query(
      'inspeccion_detalle',
      where: 'id = ?',
      whereArgs: [inspeccionId],
      limit: 1,
    );

    // Agregar a sync_queue para sincronización offline si la inspección ya existe en el servidor
    // (solo agregar si el id es positivo, es decir, ya fue sincronizado antes) y si se solicita
    if (addToSyncQueue && inspeccionId > 0) {
      await db.insert('sync_queue', {
        'type': 'UPDATE_INSPECTION_DETAIL',
        'payload': jsonEncode({
          'servicioExtintorId': servicioExtintorId,
          ...inspectionData,
        }),
        'createdAt': now.toIso8601String(),
        'lastSyncError': null,
        'syncAttempts': 0,
        'lastSyncAttempt': null,
      });
    }

    return InspectionDetailModel.fromMap(updated.first);
  }

  /// Guardar InspeccionDetalle sincronizado desde el servidor (sin agregar a sync_queue)
  Future<void> saveInspectionDetail(
    InspectionDetailModel inspectionDetail,
  ) async {
    final db = await AppDatabase.database;
    // Obtener paths locales existentes si hay (para preservarlos)
    final existing = await db.query(
      'inspeccion_detalle',
      where: 'servicioExtintorId = ?',
      whereArgs: [inspectionDetail.servicioExtintorId],
      limit: 1,
    );

    String? foto1Path;
    String? foto2Path;
    String? foto3Path;

    if (existing.isNotEmpty) {
      foto1Path = existing.first['foto1Path'] as String?;
      foto2Path = existing.first['foto2Path'] as String?;
      foto3Path = existing.first['foto3Path'] as String?;
    }

    final map = inspectionDetail.toMap();
    // Preservar paths locales si existen (solo en modo offline)
    // Si hay URLs del servidor, no preservar paths locales
    if (foto1Path != null && inspectionDetail.foto1Url == null) {
      map['foto1Path'] = foto1Path;
    }
    if (foto2Path != null && inspectionDetail.foto2Url == null) {
      map['foto2Path'] = foto2Path;
    }
    if (foto3Path != null && inspectionDetail.foto3Url == null) {
      map['foto3Path'] = foto3Path;
    }

    // Asegurar que las URLs se guarden correctamente
    map['foto1Url'] = inspectionDetail.foto1Url;
    map['foto2Url'] = inspectionDetail.foto2Url;
    map['foto3Url'] = inspectionDetail.foto3Url;

    await db.insert(
      'inspeccion_detalle',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Si hay foto1Url o foto1Path, actualizar también Extintor.photo y photoPath.
    // Importante: aquí usamos el path FINAL que quedó guardado (map['foto1Path']),
    // porque en sincronización inicial podemos venir con un foto1Path recién descargado.
    final finalFoto1Path = map['foto1Path'] as String?;
    if ((inspectionDetail.foto1Url != null &&
            inspectionDetail.foto1Url!.isNotEmpty) ||
        (finalFoto1Path != null && finalFoto1Path.isNotEmpty)) {
      await _updateExtinguisherPhotoFromServicioExtintorId(
        db,
        inspectionDetail.servicioExtintorId,
        inspectionDetail.foto1Url ?? '',
        finalFoto1Path,
      );
    }
  }

  /// Actualizar Extintor.photo cuando se guarda foto1Url en InspeccionDetalle
  /// Esto replica el comportamiento del backend que actualiza Extintor.photo
  /// También guarda el path local si existe para modo offline
  Future<void> _updateExtinguisherPhotoFromServicioExtintorId(
    Database db,
    int servicioExtintorId,
    String foto1Url,
    String? foto1Path,
  ) async {
    try {
      // Obtener el extintorId desde servicio_extintor
      final servicioExtintor = await db.query(
        'servicio_extintor',
        where: 'id = ?',
        whereArgs: [servicioExtintorId],
        limit: 1,
      );

      if (servicioExtintor.isNotEmpty) {
        final extintorId = servicioExtintor.first['extintorId'] as int?;
        if (extintorId != null) {
          // Si no se pasó foto1Path, buscarlo en InspeccionDetalle
          String? pathToUse = foto1Path;
          if (pathToUse == null) {
            final inspeccionDetalle = await db.query(
              'inspeccion_detalle',
              where: 'servicioExtintorId = ?',
              whereArgs: [servicioExtintorId],
              limit: 1,
            );

            if (inspeccionDetalle.isNotEmpty) {
              pathToUse = inspeccionDetalle.first['foto1Path'] as String?;
            }
          }

          // Verificar si ya existe photoPath en el extintor para preservarlo
          final existingExtintor = await db.query(
            'extintor',
            where: 'id = ?',
            whereArgs: [extintorId],
            limit: 1,
          );

          // Preservar photoPath existente si no se está actualizando con uno nuevo
          String? finalPhotoPath = pathToUse;
          if (existingExtintor.isNotEmpty) {
            final existingPhotoPath =
                existingExtintor.first['photoPath'] as String?;
            // Si hay un path nuevo, usarlo; si no, preservar el existente
            if (pathToUse == null || pathToUse.isEmpty) {
              finalPhotoPath = existingPhotoPath;
            }
          }

          // Actualizar Extintor.photo y photoPath
          // Solo actualizar photo si hay URL, pero siempre actualizar photoPath si hay path
          final updateData = <String, dynamic>{
            'updatedAt': DateTime.now().toIso8601String(),
          };

          if (foto1Url.isNotEmpty) {
            updateData['photo'] = foto1Url;
          }
          // Actualizar photoPath solo si hay uno nuevo, o preservar el existente
          if (finalPhotoPath != null) {
            updateData['photoPath'] = finalPhotoPath;
          }

          await db.update(
            'extintor',
            updateData,
            where: 'id = ?',
            whereArgs: [extintorId],
          );
        }
      }
    } catch (e) {
      // Si hay error al actualizar, no lanzar excepción
      // (no queremos que falle la operación principal)
      // Se puede loggear el error si es necesario
    }
  }

  /// Actualizar InspeccionDetalle después de sincronización
  Future<void> updateInspectionDetailAfterSync({
    required int tempId,
    required InspectionDetailModel inspectionDetail,
  }) async {
    final db = await AppDatabase.database;
    await db.update(
      'inspeccion_detalle',
      inspectionDetail.toMap(),
      where: 'id = ?',
      whereArgs: [tempId],
    );
  }

  /// Obtener servicios por sedeId
  Future<List<ServiceModel>> getServicesBySedeId(int sedeId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'servicio',
      where: 'sedeId = ?',
      whereArgs: [sedeId],
      orderBy: 'dateStart DESC',
    );

    return results.map((map) => ServiceModel.fromMap(map)).toList();
  }
}
