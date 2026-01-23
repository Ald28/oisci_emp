import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../features/services/data/datasources/http_service_datasource.dart';
import '../../features/services/data/datasources/http_extinguisher_datasource.dart';
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/models/service_model.dart';
import '../../features/services/data/models/service_extinguisher_model.dart';
import '../../features/services/data/models/maintenance_detail_model.dart';
import '../../features/services/data/models/inspection_detail_model.dart';
import 'service_download_sync_service.dart';

/// Servicio para sincronización incremental bidireccional
/// Descarga cambios del servidor después de la última sincronización
class IncrementalSyncService {
  final ServiceDownloadSyncService _serviceDownloadSyncService;
  final HttpServiceDataSource _httpServiceDataSource;
  final HttpExtinguisherDataSource _httpExtinguisherDataSource;
  final LocalExtinguisherDataSource _localExtinguisherDataSource;

  IncrementalSyncService({
    ServiceDownloadSyncService? serviceDownloadSyncService,
    HttpServiceDataSource? httpServiceDataSource,
    HttpExtinguisherDataSource? httpExtinguisherDataSource,
    LocalExtinguisherDataSource? localExtinguisherDataSource,
  })  : _serviceDownloadSyncService = serviceDownloadSyncService ?? ServiceDownloadSyncService(),
        _httpServiceDataSource = httpServiceDataSource ?? HttpServiceDataSource(),
        _httpExtinguisherDataSource = httpExtinguisherDataSource ?? HttpExtinguisherDataSource(),
        _localExtinguisherDataSource = localExtinguisherDataSource ?? LocalExtinguisherDataSource();

  /// Obtener el último timestamp de sincronización
  Future<DateTime?> _getLastSyncTimestamp() async {
    final db = await AppDatabase.database;
    final result = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_timestamp'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final timestampStr = result.first['value'] as String?;
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
    }
    return null;
  }

  /// Guardar el último timestamp de sincronización
  Future<void> _setLastSyncTimestamp(DateTime timestamp) async {
    final db = await AppDatabase.database;
    await db.insert(
      'sync_metadata',
      {
        'key': 'last_sync_timestamp',
        'value': timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Sincronización incremental completa:
  /// 1. Sube pendientes (ya lo hace ConnectivitySyncService)
  /// 2. Descarga cambios del servidor desde la última sincronización
  Future<bool> syncIncremental() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return false;

    try {
      // 1. Obtener último timestamp de sincronización
      final lastSync = await _getLastSyncTimestamp();
      
      // 2. Descargar servicios modificados desde la última sincronización
      await _syncServicesIncremental(lastSync);
      
      // 3. Descargar extintores modificados desde la última sincronización
      await _syncExtinguishersIncremental(lastSync);
      
      // 4. Actualizar timestamp de sincronización
      await _setLastSyncTimestamp(DateTime.now());
      
      return true;
    } catch (e) {
      // Loggear error pero no fallar completamente
      debugPrint('Error en sincronización incremental: $e');
      return false;
    }
  }

  /// Sincronizar servicios incrementales
  /// Descarga solo servicios modificados después de lastSync
  Future<void> _syncServicesIncremental(DateTime? lastSync) async {
    if (lastSync == null) {
      // Si no hay timestamp previo, descargar todo (primera sincronización)
      await _serviceDownloadSyncService.syncServicesForOffline();
      return;
    }

    try {
      // Usar endpoint incremental que filtra por updatedAt
      final since = lastSync.toIso8601String();
      final servicesWithDetails = await _httpServiceDataSource.getServicesUpdatedSince(since);

      if (servicesWithDetails.isEmpty) {
        // No hay cambios, no hacer nada
        return;
      }

      // Guardar solo los servicios modificados usando transacción
      final db = await AppDatabase.database;
      await db.transaction((txn) async {
        for (final serviceData in servicesWithDetails) {
          // Guardar servicio
          await _saveServiceInTransaction(txn, serviceData);

          // Procesar cada servicio_extintor con sus detalles
          for (final seData in serviceData.servicioExtintores) {
            // Guardar servicio_extintor
            await _saveServiceExtinguisherInTransaction(
              txn,
              serviceData.id,
              seData,
            );

            // Guardar mantenimiento_detalle si existe
            if (seData.mantenimientoDetalle != null) {
              await _saveMaintenanceDetailInTransaction(
                txn,
                seData.mantenimientoDetalle!,
              );
            }

            // Guardar inspeccion_detalle si existe
            if (seData.inspeccionDetalle != null) {
              await _saveInspectionDetailInTransaction(
                txn,
                seData.inspeccionDetalle!,
              );
            }
          }
        }
      });
    } catch (e) {
      // Si falla el endpoint incremental, fallback a descargar todo
      debugPrint('Error en sincronización incremental de servicios, usando fallback: $e');
      await _serviceDownloadSyncService.syncServicesForOffline();
    }
  }

  /// Sincronizar extintores incrementales
  /// Descarga solo extintores modificados después de lastSync
  Future<void> _syncExtinguishersIncremental(DateTime? lastSync) async {
    if (lastSync == null) {
      // Si no hay timestamp previo, usar el método completo
      // (necesitamos ExtinguisherSyncService para descargar fotos)
      return;
    }

    try {
      // Usar endpoint incremental que filtra por updatedAt
      final since = lastSync.toIso8601String();
      final extintores = await _httpExtinguisherDataSource.getExtinguishersUpdatedSince(since);

      if (extintores.isEmpty) {
        // No hay cambios, no hacer nada
        return;
      }

      // Guardar solo los extintores modificados
      for (final extintor in extintores) {
        await _localExtinguisherDataSource.saveExtinguisher(extintor);
      }
    } catch (e) {
      // Si falla el endpoint incremental, no hacer nada (no queremos descargar todo)
      debugPrint('Error en sincronización incremental de extintores: $e');
    }
  }

  // Métodos auxiliares para guardar en transacción (copiados de ServiceDownloadSyncService)
  Future<void> _saveServiceInTransaction(
    Transaction txn,
    ServiceWithDetailsModel serviceData,
  ) async {
    final service = ServiceModel(
      id: serviceData.id,
      type: serviceData.type,
      dateStart: serviceData.dateStart,
      dateEnd: serviceData.dateEnd,
      status: serviceData.status,
      statusValid: serviceData.statusValid,
      historic: serviceData.historic,
      sedeId: serviceData.sedeId,
      userId: serviceData.userId,
      usuarioCreadorId: serviceData.usuarioCreadorId,
      usuarioActualizadorId: serviceData.usuarioActualizadorId,
      createdAt: serviceData.createdAt,
      updatedAt: serviceData.updatedAt,
      sincronizado: true,
    );

    await txn.insert(
      'servicio',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveServiceExtinguisherInTransaction(
    Transaction txn,
    int servicioId,
    ServiceExtinguisherWithDetailsModel seData,
  ) async {
    final se = ServiceExtinguisherModel(
      id: seData.id,
      servicioId: servicioId,
      extintorId: seData.extintorId,
      estadoInicial: seData.estadoInicial,
      estadoFinal: seData.estadoFinal,
      completado: seData.completado,
      observaciones: seData.observaciones,
      usuarioCreadorId: seData.usuarioCreadorId,
      usuarioActualizadorId: seData.usuarioActualizadorId,
      createdAt: seData.createdAt,
      updatedAt: seData.updatedAt,
    );

    await txn.insert(
      'servicio_extintor',
      se.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveMaintenanceDetailInTransaction(
    Transaction txn,
    MaintenanceDetailModel maintenance,
  ) async {
    await txn.insert(
      'mantenimiento_detalle',
      maintenance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveInspectionDetailInTransaction(
    Transaction txn,
    InspectionDetailModel inspection,
  ) async {
    final map = inspection.toMap();
    await txn.insert(
      'inspeccion_detalle',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Si hay foto1Url, actualizar también Extintor.photo y photoPath
    final foto1Path = map['foto1Path'] as String?;
    if ((inspection.foto1Url != null && inspection.foto1Url!.isNotEmpty) ||
        (foto1Path != null && foto1Path.isNotEmpty)) {
      final servicioExtintor = await txn.query(
        'servicio_extintor',
        where: 'id = ?',
        whereArgs: [inspection.servicioExtintorId],
        limit: 1,
      );

      if (servicioExtintor.isNotEmpty) {
        final extintorId = servicioExtintor.first['extintorId'] as int?;
        if (extintorId != null) {
          final updateData = <String, dynamic>{
            'updatedAt': DateTime.now().toIso8601String(),
          };

          if (inspection.foto1Url != null && inspection.foto1Url!.isNotEmpty) {
            updateData['photo'] = inspection.foto1Url;
          }
          if (foto1Path != null && foto1Path.isNotEmpty) {
            updateData['photoPath'] = foto1Path;
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
  }
}
