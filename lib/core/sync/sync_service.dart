import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/datasources/http_extinguisher_datasource.dart';

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

        // Intentar crear en el servidor y obtener el extintor creado
        final extinguisher = await _httpDataSource.createExtinguisher(data);

        // Buscar el extintor temporal en extintor por codeNFC o serialNumber
        // para actualizarlo con el ID real del servidor
        final codeNFC = data['codeNFC'] as String?;
        final serialNumber = data['serialNumber'] as String?;

        if (codeNFC != null || serialNumber != null) {
          // Actualizar el registro existente en extintor con el ID real y synced = 1
          await _localDataSource.updateExtinguisherAfterSync(
            codeNFC: codeNFC,
            serialNumber: serialNumber,
            extinguisher: extinguisher,
          );
        } else {
          // Si no hay codeNFC ni serialNumber, insertar nuevo (caso raro)
          await _localDataSource.saveExtinguisher(extinguisher);
        }

        // Si se creó exitosamente, eliminar de la cola
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

      // Intentar crear en el servidor y obtener el extintor creado
      final extinguisher = await _httpDataSource.createExtinguisher(data);

      // Buscar el extintor temporal en extintor por codeNFC o serialNumber
      // para actualizarlo con el ID real del servidor
      final codeNFC = data['codeNFC'] as String?;
      final serialNumber = data['serialNumber'] as String?;

      if (codeNFC != null || serialNumber != null) {
        // Actualizar el registro existente en extintor con el ID real y synced = 1
        await _localDataSource.updateExtinguisherAfterSync(
          codeNFC: codeNFC,
          serialNumber: serialNumber,
          extinguisher: extinguisher,
        );
      } else {
        // Si no hay codeNFC ni serialNumber, insertar nuevo (caso raro)
        await _localDataSource.saveExtinguisher(extinguisher);
      }

      // Si se creó exitosamente, eliminar de la cola
      await _localDataSource.deleteQueueItem(queueId);
      return true;
    } catch (e) {
      await _localDataSource.updateSyncError(queueId, e.toString());
      return false;
    }
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
