import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/datasources/http_extinguisher_datasource.dart';
import '../../features/services/domain/entities/extinguisher_entity.dart';
import '../../features/services/data/models/extinguisher_model.dart';
import '../database/app_database.dart';

/// Servicio de sincronización para enviar extintores pendientes al servidor
/// Usa SQLite para almacenar pendientes
class SyncService {
  final LocalExtinguisherDataSource _localDataSource;
  final HttpExtinguisherDataSource _httpDataSource;

  SyncService({
    LocalExtinguisherDataSource? localDataSource,
    HttpExtinguisherDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalExtinguisherDataSource(),
       _httpDataSource = httpDataSource ?? HttpExtinguisherDataSource();

  /// Sincronizar todos los extintores pendientes
  /// Retorna el número de extintores sincronizados exitosamente
  Future<int> syncPendingExtinguishers() async {
    // Verificar conexión a internet
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0; // No hay internet, no se puede sincronizar
    }

    // Obtener todos los extintores pendientes de la cola
    final pendingItems = await _localDataSource.getPendingExtinguishers();

    if (pendingItems.isEmpty) {
      return 0; // No hay extintores pendientes
    }

    int syncedCount = 0;

    // Intentar sincronizar cada extintor pendiente
    for (final item in pendingItems) {
      try {
        // Decodificar el payload JSON
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final type = item['type'] as String;

        Extinguisher extinguisher;

        if (type == 'UPDATE_EXTINGUISHER') {
          // Actualizar extintor existente
          var extintorId = data['extintorId'] as int;
          final originalExtintorId =
              extintorId; // Guardar el ID original para actualizar relaciones

          // Si el extintorId es negativo, necesitamos encontrar el ID real (positivo)
          // antes de llamar al servidor, porque el servidor no conoce IDs negativos
          if (extintorId < 0) {
            final realExtintorId = await _findRealExtinguisherId(extintorId);
            if (realExtintorId != null) {
              extintorId = realExtintorId;
            } else {
              // Si no se encuentra el ID real, el extintor aún no se ha sincronizado
              // No podemos actualizar en el servidor, marcar error y continuar con el siguiente
              await _localDataSource.updateSyncError(
                item['id'] as int,
                'El extintor aún no está sincronizado. Sincronice primero el extintor antes de actualizarlo.',
              );
              continue;
            }
          }

          // Construir payload limpio con solo los campos necesarios para el backend
          // (siguiendo el mismo patrón que UPDATE_MAINTENANCE_DETAIL y UPDATE_INSPECTION_DETAIL)
          final extinguisherData = <String, dynamic>{
            'codeExtintor': data['codeExtintor'],
            'serialNumberNFC': data['serialNumberNFC'],
            'type': data['type'],
            'capacity': data['capacity'],
            'agent': data['agent'],
            'cylinderNumber': data['cylinderNumber'],
            'location': data['location'],
            'status': data['status'],
            'photo': data['photo'],
            'pressure': data['pressure'],
            'brand': data['brand'],
            'model': data['model'],
            'rating': data['rating'],
            'yearManufacture': data['yearManufacture'],
            // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
            // No se envían desde el frontend (similar a como no se envía la foto)
            'sedeId': data['sedeId'],
            // No incluir: extintorId (está en la URL), tempId, updatedAt, createdAt,
            // synced, photoPath, usuarioCreadorId (campos internos o manejados por el backend)
          };

          extinguisher = await _httpDataSource.updateExtinguisher(
            extintorId,
            extinguisherData,
          );

          // Si el extintorId original era negativo, actualizar las relaciones
          // con el nuevo ID positivo devuelto por el servidor
          if (originalExtintorId < 0 && extinguisher.id != originalExtintorId) {
            await _localDataSource.updateExtinguisherRelationsAfterSync(
              oldExtintorId: originalExtintorId,
              newExtintorId: extinguisher.id,
            );
          }

          // Guardar el extintor actualizado localmente
          await _localDataSource.saveExtinguisher(
            extinguisher as ExtinguisherModel,
          );
        } else {
          // Crear nuevo extintor
          // Construir payload limpio con solo los campos necesarios para el backend
          // (excluyendo campos internos como tempId, photoPath, createdAt, updatedAt, synced)
          final extinguisherData = <String, dynamic>{
            'codeExtintor': data['codeExtintor'],
            'serialNumberNFC': data['serialNumberNFC'],
            'type': data['type'],
            'capacity': data['capacity'],
            'agent': data['agent'],
            'cylinderNumber': data['cylinderNumber'],
            'location': data['location'],
            'status': data['status'],
            'photo': data['photo'],
            'pressure': data['pressure'],
            'brand': data['brand'],
            'model': data['model'],
            'rating': data['rating'],
            'yearManufacture': data['yearManufacture'],
            // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
            // No se envían desde el frontend (similar a como no se envía la foto)
            'sedeId': data['sedeId'],
            // No incluir: tempId, photoPath, createdAt, updatedAt, synced,
            // usuarioCreadorId (campos internos o manejados por el backend)
          };

          extinguisher = await _httpDataSource.createExtinguisher(
            extinguisherData,
          );

          // Buscar el extintor temporal en extintor por serialNumberNFC o tempId
          final serialNumberNFC = data['serialNumberNFC'] as String?;
          final tempId = data['tempId'] as int?;

          if (serialNumberNFC != null || tempId != null) {
            await _localDataSource.updateExtinguisherAfterSync(
              serialNumberNFC: serialNumberNFC,
              tempId: tempId,
              extinguisher: extinguisher as ExtinguisherModel,
            );
          } else {
            // Si no hay forma directa de identificar el extintor temporal,
            // usar la búsqueda heurística basada en otros campos y relaciones.
            await _localDataSource
                .updateExtinguisherAfterSyncWithoutSerialNumber(
                  extinguisher: extinguisher as ExtinguisherModel,
                  originalData:
                      data, // Datos originales del payload para buscar el tempId
                );
          }
        }

        // Si se procesó exitosamente, eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        // Si falla, actualizar el error en la cola
        final errorMessage = e.toString();
        await _localDataSource.updateSyncError(item['id'] as int, errorMessage);
        continue;
      }
    }

    return syncedCount;
  }

  /// Sincronizar todos los extintores pendientes con progreso
  /// Retorna un Stream con el progreso de sincronización
  Stream<Map<String, dynamic>> syncPendingExtinguishersWithProgress() async* {
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

    // Obtener todos los extintores pendientes de la cola
    final pendingItems = await _localDataSource.getPendingExtinguishers();

    if (pendingItems.isEmpty) {
      yield {'step': 'No hay registros pendientes', 'progress': 1.0};
      return;
    }

    final totalItems = pendingItems.length;
    int syncedCount = 0;

    yield {
      'step': 'Sincronizando registros...',
      'progress': 0.0,
      'total': totalItems,
      'synced': 0,
    };

    // Intentar sincronizar cada extintor pendiente
    for (int i = 0; i < pendingItems.length; i++) {
      final item = pendingItems[i];
      try {
        // Decodificar el payload JSON
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final type = item['type'] as String;

        // Actualizar progreso
        yield {
          'step': 'Sincronizando registro ${i + 1} de $totalItems...',
          'progress': ((i + 1) / totalItems),
          'total': totalItems,
          'synced': syncedCount,
        };

        Extinguisher extinguisher;

        if (type == 'UPDATE_EXTINGUISHER') {
          // Actualizar extintor existente
          var extintorId = data['extintorId'] as int;
          final originalExtintorId =
              extintorId; // Guardar el ID original para actualizar relaciones

          // Si el extintorId es negativo, necesitamos encontrar el ID real (positivo)
          // antes de llamar al servidor, porque el servidor no conoce IDs negativos
          if (extintorId < 0) {
            final realExtintorId = await _findRealExtinguisherId(extintorId);
            if (realExtintorId != null) {
              extintorId = realExtintorId;
            } else {
              // Si no se encuentra el ID real, el extintor aún no se ha sincronizado
              // No podemos actualizar en el servidor, marcar error y continuar con el siguiente
              await _localDataSource.updateSyncError(
                item['id'] as int,
                'El extintor aún no está sincronizado. Sincronice primero el extintor antes de actualizarlo.',
              );
              // Reportar el error y continuar
              yield {
                'step': 'Error en registro ${i + 1} de $totalItems',
                'progress': ((i + 1) / totalItems),
                'total': totalItems,
                'synced': syncedCount,
                'error': 'El extintor aún no está sincronizado',
              };
              continue;
            }
          }

          // Construir payload limpio con solo los campos necesarios para el backend
          // (siguiendo el mismo patrón que UPDATE_MAINTENANCE_DETAIL y UPDATE_INSPECTION_DETAIL)
          final extinguisherData = <String, dynamic>{
            'codeExtintor': data['codeExtintor'],
            'serialNumberNFC': data['serialNumberNFC'],
            'type': data['type'],
            'capacity': data['capacity'],
            'agent': data['agent'],
            'cylinderNumber': data['cylinderNumber'],
            'location': data['location'],
            'status': data['status'],
            'photo': data['photo'],
            'pressure': data['pressure'],
            'brand': data['brand'],
            'model': data['model'],
            'rating': data['rating'],
            'yearManufacture': data['yearManufacture'],
            // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
            // No se envían desde el frontend (similar a como no se envía la foto)
            'sedeId': data['sedeId'],
            // No incluir: extintorId (está en la URL), tempId, updatedAt, createdAt,
            // synced, photoPath, usuarioCreadorId (campos internos o manejados por el backend)
          };

          extinguisher = await _httpDataSource.updateExtinguisher(
            extintorId,
            extinguisherData,
          );

          // Si el extintorId original era negativo, actualizar las relaciones
          // con el nuevo ID positivo devuelto por el servidor
          if (originalExtintorId < 0 && extinguisher.id != originalExtintorId) {
            await _localDataSource.updateExtinguisherRelationsAfterSync(
              oldExtintorId: originalExtintorId,
              newExtintorId: extinguisher.id,
            );
          }

          // Guardar el extintor actualizado localmente
          await _localDataSource.saveExtinguisher(
            extinguisher as ExtinguisherModel,
          );
        } else {
          // Crear nuevo extintor
          // Construir payload limpio con solo los campos necesarios para el backend
          // (excluyendo campos internos como tempId, photoPath, createdAt, updatedAt, synced)
          final extinguisherData = <String, dynamic>{
            'codeExtintor': data['codeExtintor'],
            'serialNumberNFC': data['serialNumberNFC'],
            'type': data['type'],
            'capacity': data['capacity'],
            'agent': data['agent'],
            'cylinderNumber': data['cylinderNumber'],
            'location': data['location'],
            'status': data['status'],
            'photo': data['photo'],
            'pressure': data['pressure'],
            'brand': data['brand'],
            'model': data['model'],
            'rating': data['rating'],
            'yearManufacture': data['yearManufacture'],
            // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
            // No se envían desde el frontend (similar a como no se envía la foto)
            'sedeId': data['sedeId'],
            // No incluir: tempId, photoPath, createdAt, updatedAt, synced,
            // usuarioCreadorId (campos internos o manejados por el backend)
          };

          extinguisher = await _httpDataSource.createExtinguisher(
            extinguisherData,
          );

          // Buscar el extintor temporal en extintor por serialNumberNFC o tempId
          final serialNumberNFC = data['serialNumberNFC'] as String?;
          final tempId = data['tempId'] as int?;

          if (serialNumberNFC != null || tempId != null) {
            await _localDataSource.updateExtinguisherAfterSync(
              serialNumberNFC: serialNumberNFC,
              tempId: tempId,
              extinguisher: extinguisher as ExtinguisherModel,
            );
          } else {
            // Si no hay forma directa de identificar el extintor temporal,
            // usar la búsqueda heurística basada en otros campos y relaciones.
            await _localDataSource
                .updateExtinguisherAfterSyncWithoutSerialNumber(
                  extinguisher: extinguisher as ExtinguisherModel,
                  originalData:
                      data, // Datos originales del payload para buscar el tempId
                );
          }
        }

        // Si se procesó exitosamente, eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        // Si falla, actualizar el error en la cola
        final errorMessage = e.toString();
        await _localDataSource.updateSyncError(item['id'] as int, errorMessage);
        // Continuar con el siguiente, pero reportar el error
        yield {
          'step': 'Error en registro ${i + 1} de $totalItems',
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

  /// Obtener la cantidad de extintores pendientes
  Future<int> getPendingCount() async {
    final pending = await _localDataSource.getPendingExtinguishers();
    return pending.length;
  }

  /// Verificar si hay extintores pendientes
  Future<bool> hasPendingExtinguishers() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Sincronizar un extintor individual por ID de la cola
  Future<bool> syncSingleExtinguisher(int queueId) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      await _localDataSource.updateSyncError(
        queueId,
        'No hay conexión a internet',
      );
      return false;
    }

    try {
      // Obtener el item de la cola
      final pending = await _localDataSource.getPendingExtinguishers();
      final item = pending.firstWhere((p) => p['id'] == queueId);

      // Decodificar el payload
      final data =
          jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final type = item['type'] as String;

      Extinguisher extinguisher;

      if (type == 'UPDATE_EXTINGUISHER') {
        // Actualizar extintor existente
        var extintorId = data['extintorId'] as int;
        final originalExtintorId =
            extintorId; // Guardar el ID original para actualizar relaciones

        // Si el extintorId es negativo, necesitamos encontrar el ID real (positivo)
        // antes de llamar al servidor, porque el servidor no conoce IDs negativos
        if (extintorId < 0) {
          final realExtintorId = await _findRealExtinguisherId(extintorId);
          if (realExtintorId != null) {
            extintorId = realExtintorId;
          } else {
            // Si no se encuentra el ID real, el extintor aún no se ha sincronizado
            // No podemos actualizar en el servidor, marcar error y retornar false
            await _localDataSource.updateSyncError(
              queueId,
              'El extintor aún no está sincronizado. Sincronice primero el extintor antes de actualizarlo.',
            );
            return false;
          }
        }

        // Construir payload limpio con solo los campos necesarios para el backend
        // (siguiendo el mismo patrón que UPDATE_MAINTENANCE_DETAIL y UPDATE_INSPECTION_DETAIL)
        final extinguisherData = <String, dynamic>{
          'codeExtintor': data['codeExtintor'],
          'serialNumberNFC': data['serialNumberNFC'],
          'type': data['type'],
          'capacity': data['capacity'],
          'agent': data['agent'],
          'cylinderNumber': data['cylinderNumber'],
          'location': data['location'],
          'status': data['status'],
          'photo': data['photo'],
          'pressure': data['pressure'],
          'brand': data['brand'],
          'model': data['model'],
          'rating': data['rating'],
          'yearManufacture': data['yearManufacture'],
          // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
          // No se envían desde el frontend (similar a como no se envía la foto)
          'sedeId': data['sedeId'],
          // No incluir: extintorId (está en la URL), tempId, updatedAt, createdAt,
          // synced, photoPath, usuarioCreadorId (campos internos o manejados por el backend)
        };

        extinguisher = await _httpDataSource.updateExtinguisher(
          extintorId,
          extinguisherData,
        );

        // Si el extintorId original era negativo, actualizar las relaciones
        // con el nuevo ID positivo devuelto por el servidor
        if (originalExtintorId < 0 && extinguisher.id != originalExtintorId) {
          await _localDataSource.updateExtinguisherRelationsAfterSync(
            oldExtintorId: originalExtintorId,
            newExtintorId: extinguisher.id,
          );
        }

        // Guardar el extintor actualizado localmente
        await _localDataSource.saveExtinguisher(
          extinguisher as ExtinguisherModel,
        );
      } else {
        // Crear nuevo extintor
        // Construir payload limpio con solo los campos necesarios para el backend
        // (excluyendo campos internos como tempId, photoPath, createdAt, updatedAt, synced)
        final extinguisherData = <String, dynamic>{
          'codeExtintor': data['codeExtintor'],
          'serialNumberNFC': data['serialNumberNFC'],
          'type': data['type'],
          'capacity': data['capacity'],
          'agent': data['agent'],
          'cylinderNumber': data['cylinderNumber'],
          'location': data['location'],
          'status': data['status'],
          'photo': data['photo'],
          'pressure': data['pressure'],
          'brand': data['brand'],
          'model': data['model'],
          'rating': data['rating'],
          'yearManufacture': data['yearManufacture'],
          // dateHydrostatic, dateMaintenance y rechargeDate son manejados automáticamente por el backend
          // No se envían desde el frontend (similar a como no se envía la foto)
          'sedeId': data['sedeId'],
          // No incluir: tempId, photoPath, createdAt, updatedAt, synced,
          // usuarioCreadorId (campos internos o manejados por el backend)
        };

        extinguisher = await _httpDataSource.createExtinguisher(
          extinguisherData,
        );

        final serialNumberNFC = data['serialNumberNFC'] as String?;
        final tempId = data['tempId'] as int?;

        if (serialNumberNFC != null || tempId != null) {
          await _localDataSource.updateExtinguisherAfterSync(
            serialNumberNFC: serialNumberNFC,
            tempId: tempId,
            extinguisher: extinguisher as ExtinguisherModel,
          );
        } else {
          await _localDataSource.updateExtinguisherAfterSyncWithoutSerialNumber(
            extinguisher: extinguisher as ExtinguisherModel,
            originalData: data,
          );
        }
      }

      // Si se procesó exitosamente, eliminar de la cola
      await _localDataSource.deleteQueueItem(queueId);
      return true;
    } catch (e) {
      await _localDataSource.updateSyncError(queueId, e.toString());
      return false;
    }
  }

  /// Encontrar el ID real (positivo) de un extintor a partir de su ID temporal (negativo)
  /// Similar a _findRealExtinguisherId en service_sync_service.dart
  Future<int?> _findRealExtinguisherId(int tempId) async {
    final db = await AppDatabase.database;

    // Buscar el extintor temporal
    final tempExtinguisher = await db.query(
      'extintor',
      where: 'id = ?',
      whereArgs: [tempId],
      limit: 1,
    );

    if (tempExtinguisher.isNotEmpty) {
      final temp = tempExtinguisher.first;
      final serialNumberNFC = temp['serialNumberNFC'] as String?;

      // Estrategia 1: Si tiene serialNumberNFC, buscar por serialNumberNFC
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

      // Estrategia 2: Si no tiene serialNumberNFC o no se encontró,
      // buscar en servicio_extintor qué extintorId positivo se está usando
      // que corresponda a este extintor temporal
      final sedeId = temp['sedeId'] as int?;
      final usuarioCreadorId = temp['usuarioCreadorId'] as int?;

      if (sedeId != null && usuarioCreadorId != null) {
        // Buscar extintores sincronizados con la misma sede y usuario
        final syncedExtinguishers = await db.query(
          'extintor',
          where: 'sedeId = ? AND usuarioCreadorId = ? AND id > 0',
          whereArgs: [sedeId, usuarioCreadorId],
          orderBy: 'createdAt DESC',
          limit: 10,
        );

        // Para cada extintor sincronizado, verificar si hay servicio_extintor
        // que tenga extintorId positivo pero que originalmente apuntaba al negativo
        for (final synced in syncedExtinguishers) {
          final syncedId = synced['id'] as int;
          // Buscar si hay servicio_extintor con este extintorId positivo
          // que fue creado alrededor del mismo tiempo que el extintor temporal
          final serviceExtinguishers = await db.query(
            'servicio_extintor',
            where: 'extintorId = ?',
            whereArgs: [syncedId],
            limit: 1,
          );

          if (serviceExtinguishers.isNotEmpty) {
            // Verificar si los campos coinciden
            final syncedType = synced['type'] as String?;
            final syncedLocation = synced['location'] as String?;
            final tempType = temp['type'] as String?;
            final tempLocation = temp['location'] as String?;

            int matches = 0;
            if (syncedType != null &&
                tempType != null &&
                syncedType == tempType) {
              matches++;
            }
            if (syncedLocation != null &&
                tempLocation != null &&
                syncedLocation == tempLocation) {
              matches++;
            }

            // Si hay coincidencias, probablemente es el mismo extintor
            if (matches >= 1) {
              return syncedId;
            }
          }
        }
      }
    }

    // Estrategia 3: Buscar directamente en servicio_extintor
    // Si hay servicio_extintor con extintorId positivo que fue actualizado recientemente
    // y que corresponde a este extintor temporal
    final serviceExtinguishers = await db.query(
      'servicio_extintor',
      where: 'extintorId > 0',
      orderBy: 'createdAt DESC',
      limit: 20,
    );

    for (final se in serviceExtinguishers) {
      final extintorId = se['extintorId'] as int;
      final extintor = await db.query(
        'extintor',
        where: 'id = ?',
        whereArgs: [extintorId],
        limit: 1,
      );

      if (extintor.isNotEmpty) {
        final ext = extintor.first;
        // Verificar si este extintor sincronizado corresponde al temporal
        // comparando campos clave
        if (tempExtinguisher.isNotEmpty) {
          final temp = tempExtinguisher.first;
          final tempSedeId = temp['sedeId'] as int?;
          final tempUsuarioId = temp['usuarioCreadorId'] as int?;
          final extSedeId = ext['sedeId'] as int?;
          final extUsuarioId = ext['usuarioCreadorId'] as int?;

          if (tempSedeId != null &&
              extSedeId != null &&
              tempSedeId == extSedeId &&
              tempUsuarioId != null &&
              extUsuarioId != null &&
              tempUsuarioId == extUsuarioId) {
            final extSerial = ext['serialNumberNFC'] as String?;
            if (extSerial == null || extSerial.isEmpty) {
              return extintorId;
            }
          }
        }
      }
    }

    return null;
  }

  /// Obtener todos los extintores pendientes
  /// Retorna una lista de Maps con los datos de la cola de sincronización
  Future<List<Map<String, dynamic>>> getPendingExtinguishers() async {
    try {
      final pending = await _localDataSource.getPendingExtinguishers();

      // Filtrar cualquier registro inválido
      return pending.where((item) {
        try {
          // Validar que tenga payload válido
          final payload = item['payload'] as String?;
          if (payload == null || payload.isEmpty) {
            return false;
          }

          // Intentar decodificar para validar
          final data = jsonDecode(payload) as Map<String, dynamic>;

          // Validar que tenga los campos requeridos
          // Nota: usuarioCreadorId NO está en el payload porque se obtiene de la sesión al crear
          final sedeId = data['sedeId'];

          if (sedeId == null) {
            return false;
          }

          // Validar que sea un número válido
          final sedeIdInt = sedeId is int
              ? sedeId
              : (sedeId is String ? int.tryParse(sedeId) : null);

          return sedeIdInt != null && sedeIdInt > 0;
        } catch (e) {
          // Si hay error al validar, excluir este registro
          return false;
        }
      }).toList();
    } catch (e) {
      // Si hay error al cargar, retornar lista vacía
      return [];
    }
  }
}
