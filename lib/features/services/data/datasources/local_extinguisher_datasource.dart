import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../models/extinguisher_model.dart';
import 'extinguisher_datasource.dart';

/// DataSource local usando SQLite para almacenar extintores
class LocalExtinguisherDataSource implements ExtinguisherDataSource {
  @override
  Future<Extinguisher?> searchExtinguisher(
    String searchTerm, {
    int? sedeId,
  }) async {
    final db = await AppDatabase.database;

    // Buscar en extintor por serialNumberNFC o codeExtintor
    String whereClause = '(e.serialNumberNFC = ? OR e.codeExtintor = ?)';
    List<dynamic> whereArgs = [searchTerm, searchTerm];

    // Si se proporciona sedeId, filtrar también por sede
    if (sedeId != null) {
      whereClause += ' AND e.sedeId = ?';
      whereArgs.add(sedeId);
    }

    // Hacer JOIN con la tabla sede para obtener el nombre
    final result = await db.rawQuery('''
      SELECT 
        e.*,
        s.name_sede as sede_name
      FROM extintor e
      LEFT JOIN sede s ON e.sedeId = s.id
      WHERE $whereClause
      LIMIT 1
    ''', whereArgs);

    if (result.isNotEmpty) {
      // fromMap ahora maneja el campo sede_name del JOIN
      return ExtinguisherModel.fromMap(result.first);
    }

    // No se encontró
    return null;
  }

  /// Obtener extintor por ID
  @override
  Future<Extinguisher?> getExtinguisherById(int extintorId) async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [extintorId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ExtinguisherModel.fromMap(result.first);
  }

  @override
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data) async {
    final db = await AppDatabase.database;

    // Validar que sedeId esté presente
    final sedeIdValue = data['sedeId'];
    if (sedeIdValue == null) {
      throw Exception('sedeId es requerido para registrar un extintor');
    }

    int sedeId;
    if (sedeIdValue is int) {
      sedeId = sedeIdValue;
    } else if (sedeIdValue is String) {
      sedeId = int.tryParse(sedeIdValue) ?? 0;
      if (sedeId == 0) {
        throw Exception('sedeId debe ser un número válido');
      }
    } else {
      throw Exception('sedeId debe ser un número válido');
    }

    // Obtener usuarioCreadorId de la sesión
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception(
        'No se encontró el ID del usuario en la sesión. Por favor, inicia sesión nuevamente.',
      );
    }

    int usuarioCreadorId;
    try {
      usuarioCreadorId = int.parse(userIdStr);
      if (usuarioCreadorId <= 0) {
        throw Exception('ID de usuario inválido');
      }
    } catch (e) {
      throw Exception(
        'El ID del usuario no es válido. Por favor, inicia sesión nuevamente.',
      );
    }

    // Generar ID temporal negativo único para extintores offline
    // Los IDs negativos no colisionan con IDs del servidor (siempre positivos)
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch;

    // Guardar inmediatamente en extintor con synced = 0 (pendiente de sincronizar)
    // Esto permite que esté disponible para búsqueda offline inmediatamente
    await db.insert('extintor', {
      'id': tempId,
      'codeExtintor': data['codeExtintor'] as String?,
      'serialNumberNFC': data['serialNumberNFC'] as String?,
      'type': data['type'] as String?,
      'capacity': data['capacity'] as String?,
      'agent': data['agent'] as String?,
      'cylinderNumber': data['cylinderNumber'] as String?,
      'location': data['location'] as String?,
      'status': data['status'] as String?,
      'photo': data['photo'] as String?,
      'photoPath': data['photoPath'] as String?,
      'pressure': data['pressure'] as String?,
      'brand': data['brand'] as String?,
      'model': data['model'] as String?,
      'rating': data['rating'] as String?,
      'yearManufacture': data['yearManufacture'] as String?,
      'dateHydrostatic': data['dateHydrostatic'] is DateTime
          ? (data['dateHydrostatic'] as DateTime).toIso8601String()
          : data['dateHydrostatic'] as String?,
      'dateMaintenance': data['dateMaintenance'] is DateTime
          ? (data['dateMaintenance'] as DateTime).toIso8601String()
          : data['dateMaintenance'] as String?,
      'rechargeDate': data['rechargeDate'] is DateTime
          ? (data['rechargeDate'] as DateTime).toIso8601String()
          : data['rechargeDate'] as String?,
      'sedeId': sedeId,
      'usuarioCreadorId': usuarioCreadorId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'synced': 0, // Pendiente de sincronizar
    });

    // También guardar en sync_queue para rastreo de sincronización.
    // Incluimos tempId en el payload para poder identificar y fusionar
    // cambios posteriores (UPDATE) mientras el extintor siga con ID negativo.
    await db.insert('sync_queue', {
      'type': 'CREATE_EXTINGUISHER',
      'payload': jsonEncode({'tempId': tempId, ...data}),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    // Retornar el Extinguisher con ID temporal
    return ExtinguisherModel(
      id: tempId,
      codeExtintor: data['codeExtintor'] as String?,
      serialNumberNFC: data['serialNumberNFC'] as String?,
      type: data['type'] as String?,
      capacity: data['capacity'] as String?,
      agent: data['agent'] as String?,
      cylinderNumber: data['cylinderNumber'] as String?,
      location: data['location'] as String?,
      status: data['status'] as String?,
      photo: data['photo'] as String?,
      photoPath: data['photoPath'] as String?,
      pressure: data['pressure'] as String?,
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      rating: data['rating'] as String?,
      yearManufacture: data['yearManufacture'] as String?,
      dateHydrostatic: data['dateHydrostatic'] != null
          ? DateTime.parse(data['dateHydrostatic'] as String)
          : null,
      dateMaintenance: data['dateMaintenance'] != null
          ? DateTime.parse(data['dateMaintenance'] as String)
          : null,
      rechargeDate: data['rechargeDate'] != null
          ? DateTime.parse(data['rechargeDate'] as String)
          : null,
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Guardar extintor sincronizado desde el servidor
  /// Preserva photoPath local si ya existe en SQLite
  Future<void> saveExtinguisher(ExtinguisherModel extinguisher) async {
    final db = await AppDatabase.database;

    // Verificar si ya existe un registro con este ID para preservar photoPath
    final existing = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [extinguisher.id],
      limit: 1,
    );

    String? photoPathToUse = extinguisher.photoPath;
    if (existing.isNotEmpty) {
      // Si ya existe, preservar el photoPath local si existe
      final existingPhotoPath = existing.first['photoPath'] as String?;
      if (existingPhotoPath != null && existingPhotoPath.isNotEmpty) {
        photoPathToUse = existingPhotoPath;
      }
    }

    await db.insert('extintor', {
      'id': extinguisher.id,
      'codeExtintor': extinguisher.codeExtintor,
      'serialNumberNFC': extinguisher.serialNumberNFC,
      'type': extinguisher.type,
      'capacity': extinguisher.capacity,
      'agent': extinguisher.agent,
      'cylinderNumber': extinguisher.cylinderNumber,
      'location': extinguisher.location,
      'status': extinguisher.status,
      'photo': extinguisher.photo,
      'photoPath': photoPathToUse, // Usar el path preservado o el nuevo
      'pressure': extinguisher.pressure,
      'brand': extinguisher.brand,
      'model': extinguisher.model,
      'rating': extinguisher.rating,
      'yearManufacture': extinguisher.yearManufacture,
      'dateHydrostatic': extinguisher.dateHydrostatic?.toIso8601String(),
      'dateMaintenance': extinguisher.dateMaintenance?.toIso8601String(),
      'rechargeDate': extinguisher.rechargeDate?.toIso8601String(),
      'sedeId': extinguisher.sedeId,
      'usuarioCreadorId': extinguisher.usuarioCreadorId,
      'createdAt': extinguisher.createdAt?.toIso8601String(),
      'updatedAt': extinguisher.updatedAt?.toIso8601String(),
      'synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Actualizar extintor después de sincronización
  /// Busca el extintor temporal (con ID negativo) y lo actualiza con el ID real del servidor
  /// Puede buscar por serialNumberNFC o por tempId (ID negativo original)
  Future<void> updateExtinguisherAfterSync({
    String? serialNumberNFC,
    int? tempId, // ID negativo original del extintor temporal
    required ExtinguisherModel extinguisher,
  }) async {
    final db = await AppDatabase.database;

    // Buscar el extintor temporal
    List<Map<String, dynamic>> tempExtinguisher = [];

    if (tempId != null && tempId < 0) {
      // Buscar directamente por ID negativo
      tempExtinguisher = await db.query(
        'extintor',
        where: 'id = ?',
        whereArgs: [tempId],
        limit: 1,
      );
    } else if (serialNumberNFC != null && serialNumberNFC.isNotEmpty) {
      // Buscar por serialNumberNFC
      tempExtinguisher = await db.query(
        'extintor',
        where: 'serialNumberNFC = ? AND id < 0',
        whereArgs: [serialNumberNFC],
        limit: 1,
      );
    } else {
      // No hay forma de identificar el extintor temporal
      await saveExtinguisher(extinguisher);
      return;
    }

    if (tempExtinguisher.isEmpty) {
      // No se encontró el extintor temporal, insertar nuevo
      await saveExtinguisher(extinguisher);
      return;
    }

    final oldExtintorId = tempExtinguisher.first['id'] as int;
    final newExtintorId = extinguisher.id;

    // Preservar photoPath local si existe
    final existingPhotoPath = tempExtinguisher.first['photoPath'] as String?;
    final photoPathToUse =
        (existingPhotoPath != null && existingPhotoPath.isNotEmpty)
        ? existingPhotoPath
        : extinguisher.photoPath;

    // Actualizar en una transacción para mantener consistencia
    await db.transaction((txn) async {
      // Actualizar el registro del extintor con el ID real y synced = 1
      await txn.update(
        'extintor',
        {
          'id': newExtintorId,
          'codeExtintor': extinguisher.codeExtintor,
          'serialNumberNFC': extinguisher.serialNumberNFC,
          'type': extinguisher.type,
          'capacity': extinguisher.capacity,
          'agent': extinguisher.agent,
          'cylinderNumber': extinguisher.cylinderNumber,
          'location': extinguisher.location,
          'status': extinguisher.status,
          'photo': extinguisher.photo,
          'photoPath': photoPathToUse, // Preservar path local si existe
          'pressure': extinguisher.pressure,
          'brand': extinguisher.brand,
          'model': extinguisher.model,
          'rating': extinguisher.rating,
          'yearManufacture': extinguisher.yearManufacture,
          'dateHydrostatic': extinguisher.dateHydrostatic?.toIso8601String(),
          'dateMaintenance': extinguisher.dateMaintenance?.toIso8601String(),
          'rechargeDate': extinguisher.rechargeDate?.toIso8601String(),
          'sedeId': extinguisher.sedeId,
          'usuarioCreadorId': extinguisher.usuarioCreadorId,
          'createdAt': extinguisher.createdAt?.toIso8601String(),
          'updatedAt': extinguisher.updatedAt?.toIso8601String(),
          'synced': 1,
        },
        where: 'id = ?',
        whereArgs: [oldExtintorId],
      );

      // Actualizar referencias en servicio_extintor
      await txn.update(
        'servicio_extintor',
        {'extintorId': newExtintorId},
        where: 'extintorId = ?',
        whereArgs: [oldExtintorId],
      );

      // Actualizar referencias en sync_queue para CREATE_SERVICE_EXTINGUISHER
      // Necesitamos actualizar el payload JSON que contiene extintorId
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
            final payloadExtintorId = payload['extintorId'] as int?;

            // Si el extintorId en el payload coincide con el oldExtintorId, actualizarlo
            if (payloadExtintorId == oldExtintorId) {
              payload['extintorId'] = newExtintorId;
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
    });
  }

  /// Actualizar extintor después de sincronización cuando no tiene serialNumberNFC
  /// Busca el extintor temporal por otros campos o por relaciones en servicio_extintor
  Future<void> updateExtinguisherAfterSyncWithoutSerialNumber({
    required ExtinguisherModel extinguisher,
    required Map<String, dynamic> originalData,
  }) async {
    final db = await AppDatabase.database;

    // Estrategia 1: Buscar extintores temporales que coincidan con los datos del extintor sincronizado
    // Buscar por sedeId, usuarioCreadorId y campos que sean únicos
    final sedeId = extinguisher.sedeId;
    final usuarioCreadorId = extinguisher.usuarioCreadorId;

    // Buscar extintores temporales con la misma sede y usuario, sin serialNumberNFC
    final tempExtinguishers = await db.query(
      'extintor',
      where:
          'sedeId = ? AND usuarioCreadorId = ? AND id < 0 AND (serialNumberNFC IS NULL OR serialNumberNFC = ?)',
      whereArgs: [sedeId, usuarioCreadorId, ''],
      orderBy: 'createdAt DESC',
      limit: 10, // Limitar búsqueda
    );

    // Si encontramos candidatos, buscar el que mejor coincida
    Map<String, dynamic>? bestMatch;
    for (final temp in tempExtinguishers) {
      // Comparar campos clave para encontrar la mejor coincidencia
      final tempType = temp['type'] as String?;
      final tempLocation = temp['location'] as String?;
      final tempCapacity = temp['capacity'] as String?;

      final extType = extinguisher.type;
      final extLocation = extinguisher.location;
      final extCapacity = extinguisher.capacity;

      // Si coinciden varios campos, es probable que sea el mismo extintor
      int matches = 0;
      if (tempType != null && extType != null && tempType == extType) {
        matches++;
      }
      if (tempLocation != null &&
          extLocation != null &&
          tempLocation == extLocation) {
        matches++;
      }
      if (tempCapacity != null &&
          extCapacity != null &&
          tempCapacity == extCapacity) {
        matches++;
      }

      // Si hay al menos 2 coincidencias, considerarlo un buen match
      if (matches >= 2) {
        bestMatch = temp;
        break;
      }
    }

    // Si no encontramos por coincidencia, buscar por relaciones en servicio_extintor
    if (bestMatch == null) {
      // Buscar en servicio_extintor qué extintorId negativo se está usando
      // y que coincida con la sede del extintor sincronizado
      final serviceExtinguishers = await db.query(
        'servicio_extintor',
        where: 'extintorId < 0',
        orderBy: 'createdAt DESC',
        limit: 20,
      );

      // Para cada servicio_extintor con extintorId negativo, verificar si el extintor
      // tiene la misma sede y otros campos similares
      for (final se in serviceExtinguishers) {
        final tempExtintorId = se['extintorId'] as int;
        final tempExt = await db.query(
          'extintor',
          where: 'id = ? AND sedeId = ?',
          whereArgs: [tempExtintorId, sedeId],
          limit: 1,
        );

        if (tempExt.isNotEmpty) {
          final temp = tempExt.first;
          // Verificar si no tiene serialNumberNFC o tiene serialNumberNFC vacío
          final tempSerial = temp['serialNumberNFC'] as String?;
          if (tempSerial == null || tempSerial.isEmpty) {
            // Verificar coincidencias
            final tempType = temp['type'] as String?;
            final tempLocation = temp['location'] as String?;

            final extType = extinguisher.type;
            final extLocation = extinguisher.location;

            int matches = 0;
            if (tempType != null && extType != null && tempType == extType) {
              matches++;
            }
            if (tempLocation != null &&
                extLocation != null &&
                tempLocation == extLocation) {
              matches++;
            }

            if (matches >= 1) {
              bestMatch = temp;
              break;
            }
          }
        }
      }
    }

    if (bestMatch != null) {
      // Encontramos el extintor temporal, actualizarlo
      final oldExtintorId = bestMatch['id'] as int;
      final newExtintorId = extinguisher.id;

      // Preservar photoPath local si existe
      final existingPhotoPath = bestMatch['photoPath'] as String?;
      final photoPathToUse =
          (existingPhotoPath != null && existingPhotoPath.isNotEmpty)
          ? existingPhotoPath
          : extinguisher.photoPath;

      // Actualizar en una transacción para mantener consistencia
      await db.transaction((txn) async {
        // Actualizar el registro del extintor con el ID real y synced = 1
        await txn.update(
          'extintor',
          {
            'id': newExtintorId,
            'codeExtintor': extinguisher.codeExtintor,
            'serialNumberNFC': extinguisher.serialNumberNFC,
            'type': extinguisher.type,
            'capacity': extinguisher.capacity,
            'agent': extinguisher.agent,
            'cylinderNumber': extinguisher.cylinderNumber,
            'location': extinguisher.location,
            'status': extinguisher.status,
            'photo': extinguisher.photo,
            'photoPath': photoPathToUse,
            'pressure': extinguisher.pressure,
            'brand': extinguisher.brand,
            'model': extinguisher.model,
            'rating': extinguisher.rating,
            'yearManufacture': extinguisher.yearManufacture,
            'dateHydrostatic': extinguisher.dateHydrostatic?.toIso8601String(),
            'dateMaintenance': extinguisher.dateMaintenance?.toIso8601String(),
            'rechargeDate': extinguisher.rechargeDate?.toIso8601String(),
            'sedeId': extinguisher.sedeId,
            'usuarioCreadorId': extinguisher.usuarioCreadorId,
            'createdAt': extinguisher.createdAt?.toIso8601String(),
            'updatedAt': extinguisher.updatedAt?.toIso8601String(),
            'synced': 1,
          },
          where: 'id = ?',
          whereArgs: [oldExtintorId],
        );

        // Actualizar referencias en servicio_extintor
        await txn.update(
          'servicio_extintor',
          {'extintorId': newExtintorId},
          where: 'extintorId = ?',
          whereArgs: [oldExtintorId],
        );

        // Actualizar referencias en sync_queue para CREATE_SERVICE_EXTINGUISHER
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
              final payloadExtintorId = payload['extintorId'] as int?;

              if (payloadExtintorId == oldExtintorId) {
                payload['extintorId'] = newExtintorId;
                await txn.update(
                  'sync_queue',
                  {'payload': jsonEncode(payload)},
                  where: 'id = ?',
                  whereArgs: [item['id']],
                );
              }
            }
          } catch (e) {
            continue;
          }
        }

        // Actualizar referencias en sync_queue para UPDATE_EXTINGUISHER
        final updateExtinguisherItems = await txn.query(
          'sync_queue',
          where: 'type = ?',
          whereArgs: ['UPDATE_EXTINGUISHER'],
        );

        for (final item in updateExtinguisherItems) {
          try {
            final payloadStr = item['payload'] as String?;
            if (payloadStr != null) {
              final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
              final payloadExtintorId = payload['extintorId'] as int?;

              if (payloadExtintorId == oldExtintorId) {
                payload['extintorId'] = newExtintorId;
                await txn.update(
                  'sync_queue',
                  {'payload': jsonEncode(payload)},
                  where: 'id = ?',
                  whereArgs: [item['id']],
                );
              }
            }
          } catch (e) {
            continue;
          }
        }
      });
    } else {
      // No se encontró el extintor temporal, guardar como nuevo
      await saveExtinguisher(extinguisher);
    }
  }

  /// Actualizar relaciones cuando un extintor con ID negativo se sincroniza después de UPDATE
  /// Este método se usa cuando un extintor creado offline (ID negativo) se actualiza
  /// y luego se sincroniza, necesitando actualizar las referencias en servicio_extintor y sync_queue
  Future<void> updateExtinguisherRelationsAfterSync({
    required int oldExtintorId,
    required int newExtintorId,
  }) async {
    final db = await AppDatabase.database;

    // Actualizar en una transacción para mantener consistencia
    await db.transaction((txn) async {
      // Actualizar referencias en servicio_extintor
      await txn.update(
        'servicio_extintor',
        {'extintorId': newExtintorId},
        where: 'extintorId = ?',
        whereArgs: [oldExtintorId],
      );

      // Actualizar referencias en sync_queue para CREATE_SERVICE_EXTINGUISHER
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
            final payloadExtintorId = payload['extintorId'] as int?;

            // Si el extintorId en el payload coincide con el oldExtintorId, actualizarlo
            if (payloadExtintorId == oldExtintorId) {
              payload['extintorId'] = newExtintorId;
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

      // Actualizar referencias en sync_queue para UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS
      // si es que existe algún tipo de actualización de servicio_extintor
      final updateServiceExtinguisherItems = await txn.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['UPDATE_SERVICE_EXTINGUISHER_OBSERVATIONS'],
      );

      for (final item in updateServiceExtinguisherItems) {
        try {
          final payloadStr = item['payload'] as String?;
          if (payloadStr != null) {
            final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
            // Este tipo no tiene extintorId directamente, pero puede tenerlo en el payload
            // Solo actualizar si existe
            if (payload.containsKey('extintorId')) {
              final payloadExtintorId = payload['extintorId'] as int?;
              if (payloadExtintorId == oldExtintorId) {
                payload['extintorId'] = newExtintorId;
                await txn.update(
                  'sync_queue',
                  {'payload': jsonEncode(payload)},
                  where: 'id = ?',
                  whereArgs: [item['id']],
                );
              }
            }
          }
        } catch (e) {
          // Si hay error al parsear el JSON, continuar con el siguiente item
          continue;
        }
      }

      // Nota: Las referencias en mantenimiento_detalle e inspeccion_detalle
      // se actualizan automáticamente cuando se sincroniza servicio_extintor,
      // ya que estos detalles referencian servicio_extintor, no directamente al extintor.
      // Al actualizar el extintorId en servicio_extintor, las relaciones quedan correctas.
    });
  }

  /// Obtener extintores pendientes de sincronización (CREATE y UPDATE)
  Future<List<Map<String, dynamic>>> getPendingExtinguishers() async {
    final db = await AppDatabase.database;

    return await db.query(
      'sync_queue',
      where: 'type = ? OR type = ?',
      whereArgs: ['CREATE_EXTINGUISHER', 'UPDATE_EXTINGUISHER'],
      orderBy: 'createdAt ASC',
    );
  }

  /// Eliminar un elemento de la cola de sincronización
  Future<void> deleteQueueItem(int id) async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Verificar si existe un extintor con el mismo serialNumberNFC o codeExtintor
  Future<bool> existsExtinguisher({
    String? serialNumberNFC,
    String? codeExtintor,
  }) async {
    final db = await AppDatabase.database;
    if ((serialNumberNFC == null || serialNumberNFC.isEmpty) &&
        (codeExtintor == null || codeExtintor.isEmpty)) {
      return false;
    }
    if (serialNumberNFC != null && serialNumberNFC.isNotEmpty) {
      final r = await db.query(
        'extintor',
        where: 'serialNumberNFC = ?',
        whereArgs: [serialNumberNFC],
        limit: 1,
      );
      if (r.isNotEmpty) return true;
    }
    if (codeExtintor != null && codeExtintor.isNotEmpty) {
      final r = await db.query(
        'extintor',
        where: 'codeExtintor = ?',
        whereArgs: [codeExtintor],
        limit: 1,
      );
      if (r.isNotEmpty) return true;
    }
    final pendingItems = await db.query(
      'sync_queue',
      where: 'type = ?',
      whereArgs: ['CREATE_EXTINGUISHER'],
    );
    for (final item in pendingItems) {
      try {
        final payload =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final pSn = payload['serialNumberNFC'] as String?;
        final pCe = payload['codeExtintor'] as String?;
        if (serialNumberNFC != null && pSn == serialNumberNFC) return true;
        if (codeExtintor != null && pCe != null && pCe == codeExtintor) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  /// Obtener información sobre qué campo está duplicado
  Future<Map<String, bool>> checkDuplicates({
    String? codeExtintor,
    String? serialNumberNFC,
  }) async {
    final db = await AppDatabase.database;
    final result = <String, bool>{
      'codeExtintor': false,
      'serialNumberNFC': false,
    };

    Future<void> check(String column, String value, String key) async {
      if (value.isEmpty) return;
      final synced = await db.query(
        'extintor',
        where: '$column = ?',
        whereArgs: [value],
        limit: 1,
      );
      if (synced.isNotEmpty) {
        result[key] = true;
        return;
      }
      final pendingItems = await db.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['CREATE_EXTINGUISHER'],
      );
      for (final item in pendingItems) {
        try {
          final payload =
              jsonDecode(item['payload'] as String) as Map<String, dynamic>;
          final p =
              payload[column == 'codeExtintor'
                      ? 'codeExtintor'
                      : 'serialNumberNFC']
                  as String?;
          if (p != null && p == value) {
            result[key] = true;
            return;
          }
        } catch (e) {
          continue;
        }
      }
    }

    if (codeExtintor != null && codeExtintor.isNotEmpty) {
      await check('codeExtintor', codeExtintor, 'codeExtintor');
    }
    if (serialNumberNFC != null && serialNumberNFC.isNotEmpty) {
      await check('serialNumberNFC', serialNumberNFC, 'serialNumberNFC');
    }
    return result;
  }

  /// Actualizar error de sincronización
  Future<void> updateSyncError(int id, String error) async {
    final db = await AppDatabase.database;

    // Obtener intentos actuales
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

  /// Obtener extintores por sedeId
  @override
  Future<List<Extinguisher>> getExtinguishersBySedeId(int sedeId) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'extintor',
      where: 'sedeId = ?',
      whereArgs: [sedeId],
      orderBy: 'serialNumberNFC ASC',
    );

    return results.map((map) => ExtinguisherModel.fromMap(map)).toList();
  }

  @override
  Future<Extinguisher> updateExtinguisher(
    int extintorId,
    Map<String, dynamic> data,
  ) async {
    final db = await AppDatabase.database;
    final session = await AuthService.loadSession();
    final userIdStr = session['userId'] as String?;

    if (userIdStr == null || userIdStr.isEmpty) {
      throw Exception(
        'No se encontró el ID del usuario en la sesión. Por favor, inicia sesión nuevamente.',
      );
    }

    int usuarioActualizadorId;
    try {
      usuarioActualizadorId = int.parse(userIdStr);
      if (usuarioActualizadorId <= 0) {
        throw Exception('ID de usuario inválido');
      }
    } catch (e) {
      throw Exception(
        'El ID del usuario no es válido. Por favor, inicia sesión nuevamente.',
      );
    }

    // Obtener el extintor existente para preservar datos
    final existing = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [extintorId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw Exception('Extintor no encontrado');
    }

    final existingData = existing.first;
    final now = DateTime.now();

    // Preparar datos para actualizar, preservando valores existentes si no se proporcionan
    final updateData = {
      'codeExtintor': data['codeExtintor'] ?? existingData['codeExtintor'],
      'serialNumberNFC':
          data['serialNumberNFC'] ?? existingData['serialNumberNFC'],
      'type': data['type'] ?? existingData['type'],
      'capacity': data['capacity'] ?? existingData['capacity'],
      'agent': data['agent'] ?? existingData['agent'],
      'cylinderNumber':
          data['cylinderNumber'] ?? existingData['cylinderNumber'],
      'location': data['location'] ?? existingData['location'],
      'status': data['status'] ?? existingData['status'],
      'pressure': data['pressure'] ?? existingData['pressure'],
      'brand': data['brand'] ?? existingData['brand'],
      'model': data['model'] ?? existingData['model'],
      'rating': data['rating'] ?? existingData['rating'],
      'yearManufacture':
          data['yearManufacture'] ?? existingData['yearManufacture'],
      'dateHydrostatic': data['dateHydrostatic'] is DateTime
          ? (data['dateHydrostatic'] as DateTime).toIso8601String()
          : (data['dateHydrostatic'] ?? existingData['dateHydrostatic']),
      'dateMaintenance': data['dateMaintenance'] is DateTime
          ? (data['dateMaintenance'] as DateTime).toIso8601String()
          : (data['dateMaintenance'] ?? existingData['dateMaintenance']),
      'rechargeDate': data['rechargeDate'] is DateTime
          ? (data['rechargeDate'] as DateTime).toIso8601String()
          : (data['rechargeDate'] ?? existingData['rechargeDate']),
      'updatedAt': now.toIso8601String(),
      'synced': 0, // Marcar como no sincronizado
    };

    // Actualizar en la base de datos
    await db.update(
      'extintor',
      updateData,
      where: 'id = ?',
      whereArgs: [extintorId],
    );

    // Manejo de sincronización:
    // - Si el extintorId es NEGATIVO, significa que el extintor aún no se ha
    //   sincronizado nunca. En ese caso, en lugar de crear un UPDATE separado,
    //   fusionamos los cambios en el payload del CREATE_EXTINGUISHER existente
    //   (identificado por tempId) para que el servidor reciba un solo CREATE
    //   con el estado final del extintor.
    // - Si el extintorId es POSITIVO, encolamos un UPDATE_EXTINGUISHER normal.

    if (extintorId < 0) {
      bool mergedIntoCreate = false;

      // Buscar items CREATE_EXTINGUISHER en la cola
      final createItems = await db.query(
        'sync_queue',
        where: 'type = ?',
        whereArgs: ['CREATE_EXTINGUISHER'],
      );

      for (final item in createItems) {
        try {
          final payloadStr = item['payload'] as String?;
          if (payloadStr == null) continue;

          final payload = jsonDecode(payloadStr) as Map<String, dynamic>? ?? {};
          final payloadTempId = payload['tempId'];

          if (payloadTempId is int && payloadTempId == extintorId) {
            // Fusionar los nuevos datos en el payload original.
            // Los campos de "data" sobrescriben a los existentes.
            payload.addAll(data);

            await db.update(
              'sync_queue',
              {'payload': jsonEncode(payload)},
              where: 'id = ?',
              whereArgs: [item['id']],
            );

            mergedIntoCreate = true;
            break;
          }
        } catch (_) {
          // Si hay error al parsear este item, continuar con el siguiente.
          continue;
        }
      }

      if (!mergedIntoCreate) {
        // Caso de seguridad: si por alguna razón no encontramos el CREATE
        // correspondiente (por ejemplo, datos antiguos sin tempId),
        // encolamos un UPDATE_EXTINGUISHER como antes.
        await db.insert('sync_queue', {
          'type': 'UPDATE_EXTINGUISHER',
          'payload': jsonEncode({'extintorId': extintorId, ...data}),
          'createdAt': now.toIso8601String(),
          'lastSyncError': null,
          'syncAttempts': 0,
          'lastSyncAttempt': null,
        });
      }
    } else {
      // Extintor ya sincronizado al menos una vez (ID positivo):
      // encolar un UPDATE_EXTINGUISHER normal.
      await db.insert('sync_queue', {
        'type': 'UPDATE_EXTINGUISHER',
        'payload': jsonEncode({'extintorId': extintorId, ...data}),
        'createdAt': now.toIso8601String(),
        'lastSyncError': null,
        'syncAttempts': 0,
        'lastSyncAttempt': null,
      });
    }

    // Retornar el extintor actualizado
    final updated = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [extintorId],
      limit: 1,
    );

    return ExtinguisherModel.fromMap(updated.first);
  }

  @override
  Future<List<Extinguisher>> getExtinguishersWithoutSerialNumber({
    int? sedeId,
  }) async {
    final db = await AppDatabase.database;

    String whereClause = '(serialNumberNFC IS NULL OR serialNumberNFC = ?)';
    List<dynamic> whereArgs = [''];

    // Si se proporciona sedeId, filtrar también por sede
    if (sedeId != null) {
      whereClause += ' AND sedeId = ?';
      whereArgs.add(sedeId);
    }

    final results = await db.query(
      'extintor',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id ASC',
    );

    return results.map((map) => ExtinguisherModel.fromMap(map)).toList();
  }
}
