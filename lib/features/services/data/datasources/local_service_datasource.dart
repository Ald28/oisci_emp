import 'dart:convert';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/database/app_database.dart';
import '../models/service_model.dart';
import '../models/service_extinguisher_model.dart';
import '../models/maintenance_detail_model.dart';

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
  Future<void> finalizeService(int servicioId) async {
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
  }

  /// Crear ServicioExtintor (Etapa 2)
  Future<ServiceExtinguisherModel> createServiceExtinguisher({
    required int servicioId,
    required int extintorId,
    String? estadoInicial,
    String? observaciones,
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
  Future<void> updateServiceExtinguisherObservations({
    required int servicioExtintorId,
    required String? observaciones,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();
    await db.update(
      'servicio_extintor',
      {'observaciones': observaciones, 'updatedAt': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [servicioExtintorId],
    );
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
        e.codeNFC,
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
}
