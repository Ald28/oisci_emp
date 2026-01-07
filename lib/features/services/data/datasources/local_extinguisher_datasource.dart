import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/extinguisher.dart';
import '../models/extinguisher_model.dart';
import 'extinguisher_datasource.dart';

/// DataSource local usando SQLite para almacenar extintores
class LocalExtinguisherDataSource implements ExtinguisherDataSource {
  @override
  Future<Extinguisher?> searchExtinguisher(String searchTerm) async {
    final db = await AppDatabase.database;

    // Buscar en extintor (tanto sincronizados como pendientes)
    // Ahora todos los extintores están en la tabla extintor con synced = 0 o 1
    final result = await db.query(
      'extintor',
      where: 'codeNFC = ? OR serialNumber = ?',
      whereArgs: [searchTerm, searchTerm],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return ExtinguisherModel.fromMap(result.first);
    }

    // No se encontró
    return null;
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
      'codeNFC': data['codeNFC'] as String?,
      'serialNumber': data['serialNumber'] as String?,
      'type': data['type'] as String?,
      'capacity': data['capacity'] as String?,
      'agent': data['agent'] as String?,
      'cylinderNumber': data['cylinderNumber'] as String?,
      'location': data['location'] as String?,
      'status': data['status'] as String?,
      'photo': data['photo'] as String?,
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
      codeNFC: data['codeNFC'] as String?,
      serialNumber: data['serialNumber'] as String?,
      type: data['type'] as String?,
      capacity: data['capacity'] as String?,
      agent: data['agent'] as String?,
      cylinderNumber: data['cylinderNumber'] as String?,
      location: data['location'] as String?,
      status: data['status'] as String?,
      photo: data['photo'] as String?,
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Guardar extintor sincronizado desde el servidor
  Future<void> saveExtinguisher(ExtinguisherModel extinguisher) async {
    final db = await AppDatabase.database;

    await db.insert('extintor', {
      'id': extinguisher.id,
      'codeNFC': extinguisher.codeNFC,
      'serialNumber': extinguisher.serialNumber,
      'type': extinguisher.type,
      'capacity': extinguisher.capacity,
      'agent': extinguisher.agent,
      'cylinderNumber': extinguisher.cylinderNumber,
      'location': extinguisher.location,
      'status': extinguisher.status,
      'photo': extinguisher.photo,
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
    String? codeNFC,
    String? serialNumber,
    required ExtinguisherModel extinguisher,
  }) async {
    final db = await AppDatabase.database;

    // Construir la condición WHERE
    String whereClause;
    List<dynamic> whereArgs;

    if (codeNFC != null && serialNumber != null) {
      whereClause = '(codeNFC = ? OR serialNumber = ?) AND id < 0';
      whereArgs = [codeNFC, serialNumber];
    } else if (codeNFC != null) {
      whereClause = 'codeNFC = ? AND id < 0';
      whereArgs = [codeNFC];
    } else if (serialNumber != null) {
      whereClause = 'serialNumber = ? AND id < 0';
      whereArgs = [serialNumber];
    } else {
      // Si no hay codeNFC ni serialNumber, no se puede actualizar
      return;
    }

    // Actualizar el registro existente con el ID real y synced = 1
    await db.update(
      'extintor',
      {
        'id': extinguisher.id,
        'codeNFC': extinguisher.codeNFC,
        'serialNumber': extinguisher.serialNumber,
        'type': extinguisher.type,
        'capacity': extinguisher.capacity,
        'agent': extinguisher.agent,
        'cylinderNumber': extinguisher.cylinderNumber,
        'location': extinguisher.location,
        'status': extinguisher.status,
        'photo': extinguisher.photo,
        'sedeId': extinguisher.sedeId,
        'usuarioCreadorId': extinguisher.usuarioCreadorId,
        'createdAt': extinguisher.createdAt?.toIso8601String(),
        'updatedAt': extinguisher.updatedAt?.toIso8601String(),
        'synced': 1,
      },
      where: whereClause,
      whereArgs: whereArgs,
    );
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

  /// Verificar si existe un extintor con el mismo codeNFC o serialNumber
  /// Busca tanto en extintores sincronizados como en pendientes
  Future<bool> existsExtinguisher({
    String? codeNFC,
    String? serialNumber,
  }) async {
    final db = await AppDatabase.database;

    // Validar que al menos uno de los campos esté presente
    if (codeNFC == null && serialNumber == null) {
      return false;
    }

    // Buscar en extintores sincronizados
    if (codeNFC != null) {
      final result = await db.query(
        'extintor',
        where: 'codeNFC = ?',
        whereArgs: [codeNFC],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return true;
      }
    }

    if (serialNumber != null) {
      final result = await db.query(
        'extintor',
        where: 'serialNumber = ?',
        whereArgs: [serialNumber],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return true;
      }
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
        final pendingCodeNFC = payload['codeNFC'] as String?;
        final pendingSerialNumber = payload['serialNumber'] as String?;

        // Verificar codeNFC
        if (codeNFC != null &&
            pendingCodeNFC != null &&
            pendingCodeNFC == codeNFC) {
          return true;
        }

        // Verificar serialNumber
        if (serialNumber != null &&
            pendingSerialNumber != null &&
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
  Future<Map<String, bool>> checkDuplicates({
    String? codeNFC,
    String? serialNumber,
  }) async {
    final db = await AppDatabase.database;
    final result = <String, bool>{'codeNFC': false, 'serialNumber': false};

    // Verificar codeNFC en extintores sincronizados
    if (codeNFC != null && codeNFC.isNotEmpty) {
      final syncedResult = await db.query(
        'extintor',
        where: 'codeNFC = ?',
        whereArgs: [codeNFC],
        limit: 1,
      );
      if (syncedResult.isNotEmpty) {
        result['codeNFC'] = true;
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
            final pendingCodeNFC = payload['codeNFC'] as String?;
            if (pendingCodeNFC != null && pendingCodeNFC == codeNFC) {
              result['codeNFC'] = true;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

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
}
