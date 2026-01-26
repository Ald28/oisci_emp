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
  Future<Extinguisher?> searchExtinguisher(String searchTerm, {int? sedeId}) async {
    final db = await AppDatabase.database;

    // Buscar en extintor con JOIN a sede para obtener el nombre de la sede
    String whereClause = 'e.serialNumber = ?';
    List<dynamic> whereArgs = [searchTerm];
    
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
      'serialNumber': data['serialNumber'] as String?,
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
      'dateHydrostatic': data['dateHydrostatic'] as String?,
      'dateMaintenance': data['dateMaintenance'] as String?,
      'sedeId': sedeId,
      'usuarioCreadorId': usuarioCreadorId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'synced': 0, // Pendiente de sincronizar
    });

    // También guardar en sync_queue para rastreo de sincronización
    // Esto permite manejar errores y reintentos
    await db.insert('sync_queue', {
      'type': 'CREATE_EXTINGUISHER',
      'payload': jsonEncode(data),
      'createdAt': now.toIso8601String(),
      'lastSyncError': null,
      'syncAttempts': 0,
      'lastSyncAttempt': null,
    });

    // Retornar el Extinguisher con ID temporal
    return ExtinguisherModel(
      id: tempId,
      serialNumber: data['serialNumber'] as String?,
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
      dateHydrostatic: data['dateHydrostatic'] as String?,
      dateMaintenance: data['dateMaintenance'] as String?,
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
      'serialNumber': extinguisher.serialNumber,
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
      'dateHydrostatic': extinguisher.dateHydrostatic,
      'dateMaintenance': extinguisher.dateMaintenance,
      'sedeId': extinguisher.sedeId,
      'usuarioCreadorId': extinguisher.usuarioCreadorId,
      'createdAt': extinguisher.createdAt?.toIso8601String(),
      'updatedAt': extinguisher.updatedAt?.toIso8601String(),
      'synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Actualizar extintor después de sincronización
  /// Busca el extintor temporal (con ID negativo) y lo actualiza con el ID real del servidor
  Future<void> updateExtinguisherAfterSync({
    String? serialNumber,
    required ExtinguisherModel extinguisher,
  }) async {
    final db = await AppDatabase.database;

    // Construir la condición WHERE
    if (serialNumber == null) {
      // Si no hay serialNumber, no se puede actualizar
      return;
    }

    // Buscar el extintor temporal con ID negativo
    final tempExtinguisher = await db.query(
      'extintor',
      where: 'serialNumber = ? AND id < 0',
      whereArgs: [serialNumber],
      limit: 1,
    );

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
          'serialNumber': extinguisher.serialNumber,
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
          'dateHydrostatic': extinguisher.dateHydrostatic,
          'dateMaintenance': extinguisher.dateMaintenance,
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

  /// Obtener extintores pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingExtinguishers() async {
    final db = await AppDatabase.database;

    return await db.query(
      'sync_queue',
      where: 'type = ?',
      whereArgs: ['CREATE_EXTINGUISHER'],
      orderBy: 'createdAt ASC',
    );
  }

  /// Eliminar un elemento de la cola de sincronización
  Future<void> deleteQueueItem(int id) async {
    final db = await AppDatabase.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Verificar si existe un extintor con el mismo serialNumber
  /// Busca tanto en extintores sincronizados como en pendientes
  Future<bool> existsExtinguisher({String? serialNumber}) async {
    final db = await AppDatabase.database;

    // Validar que el campo esté presente
    if (serialNumber == null) {
      return false;
    }

    // Buscar en extintores sincronizados
    final result = await db.query(
      'extintor',
      where: 'serialNumber = ?',
      whereArgs: [serialNumber],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return true;
    }

    // Buscar en extintores pendientes (sync_queue)
    final pendingItems = await db.query(
      'sync_queue',
      where: 'type = ?',
      whereArgs: ['CREATE_EXTINGUISHER'],
    );

    for (final item in pendingItems) {
      try {
        final payload =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final pendingSerialNumber = payload['serialNumber'] as String?;

        // Verificar serialNumber
        if (pendingSerialNumber != null &&
            pendingSerialNumber == serialNumber) {
          return true;
        }
      } catch (e) {
        // Si hay error al parsear, continuar con el siguiente
        continue;
      }
    }

    return false;
  }

  /// Obtener información sobre qué campo está duplicado
  Future<Map<String, bool>> checkDuplicates({String? serialNumber}) async {
    final db = await AppDatabase.database;
    final result = <String, bool>{'serialNumber': false};

    // Verificar serialNumber en extintores sincronizados
    if (serialNumber != null && serialNumber.isNotEmpty) {
      final syncedResult = await db.query(
        'extintor',
        where: 'serialNumber = ?',
        whereArgs: [serialNumber],
        limit: 1,
      );
      if (syncedResult.isNotEmpty) {
        result['serialNumber'] = true;
      } else {
        // Verificar en pendientes
        final pendingItems = await db.query(
          'sync_queue',
          where: 'type = ?',
          whereArgs: ['CREATE_EXTINGUISHER'],
        );
        for (final item in pendingItems) {
          try {
            final payload =
                jsonDecode(item['payload'] as String) as Map<String, dynamic>;
            final pendingSerialNumber = payload['serialNumber'] as String?;
            if (pendingSerialNumber != null &&
                pendingSerialNumber == serialNumber) {
              result['serialNumber'] = true;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }
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
      orderBy: 'serialNumber ASC',
    );

    return results.map((map) => ExtinguisherModel.fromMap(map)).toList();
  }
}
