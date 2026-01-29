import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/services/data/datasources/http_service_datasource.dart';
import '../../features/services/data/models/inspection_detail_model.dart';
import '../../features/services/data/models/service_model.dart';
import '../../features/services/data/models/service_extinguisher_model.dart';
import '../../features/services/data/models/maintenance_detail_model.dart';
import '../../core/database/app_database.dart';

/// Servicio para descargar (bootstrap) servicios y sus detalles desde el servidor
/// para permitir continuar el trabajo en modo offline.
///
/// Nota: Esto NO envía pendientes (eso lo hace `ServiceSyncService`).
class ServiceDownloadSyncService {
  final HttpServiceDataSource _http;

  ServiceDownloadSyncService({HttpServiceDataSource? httpDataSource})
    : _http = httpDataSource ?? HttpServiceDataSource();

  /// Descarga TODOS los servicios con TODOS sus detalles en una sola llamada,
  /// usando transacciones SQLite para asegurar consistencia.
  ///
  /// Incluye:
  /// - servicio
  /// - servicio_extintor de cada servicio
  /// - mantenimiento_detalle / inspeccion_detalle (si existen)
  /// - descarga de fotos de inspección (foto1/2/3) a paths locales
  ///
  /// Retorna `true` si el proceso se ejecutó (con internet),
  /// `false` si no hay conexión.
  Future<bool> syncServicesForOffline() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) return false;

    try {
      // 1) Obtener TODOS los servicios con detalles anidados en una sola llamada
      final servicesWithDetails = await _http.getAllServicesWithDetails();

      // 2) Pre-descargar todas las fotos ANTES de la transacción (para no bloquear)
      final Map<int, InspectionDetailModel> inspectionsWithPaths = {};
      for (final serviceData in servicesWithDetails) {
        for (final seData in serviceData.servicioExtintores) {
          if (seData.inspeccionDetalle != null) {
            final inspectionWithPaths = await _downloadInspectionPhotos(
              serviceExtinguisherId: seData.id,
              inspection: seData.inspeccionDetalle!,
            );
            inspectionsWithPaths[seData.id] = inspectionWithPaths;
          }
        }
      }

      // 3) Usar transacción SQLite para asegurar consistencia al guardar
      final db = await AppDatabase.database;
      await db.transaction((txn) async {
        // Procesar cada servicio con sus detalles
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

            // Guardar inspeccion_detalle si existe (usar versión con paths ya descargados)
            final inspectionWithPaths = inspectionsWithPaths[seData.id];
            if (inspectionWithPaths != null) {
              await _saveInspectionDetailInTransaction(
                txn,
                inspectionWithPaths,
              );
            }
          }
        }
      });

      return true;
    } catch (e) {
      // Si falla, la transacción se revierte automáticamente
      // Loggear el error pero no lanzar excepción para no interrumpir la sincronización
      debugPrint('Error al sincronizar servicios: $e');
      return false;
    }
  }

  /// Guardar servicio dentro de una transacción
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

  /// Guardar servicio_extintor dentro de una transacción
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

  /// Guardar mantenimiento_detalle dentro de una transacción
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

  /// Guardar inspeccion_detalle dentro de una transacción
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

    // Si hay foto1Url o foto1Path, actualizar también Extintor.photo y photoPath
    final foto1Path = map['foto1Path'] as String?;
    if ((inspection.foto1Url != null && inspection.foto1Url!.isNotEmpty) ||
        (foto1Path != null && foto1Path.isNotEmpty)) {
      // Obtener extintorId desde servicio_extintor
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

  Future<InspectionDetailModel> _downloadInspectionPhotos({
    required int serviceExtinguisherId,
    required InspectionDetailModel inspection,
  }) async {
    final foto1Path = await _downloadPhotoIfNeeded(
      serviceExtinguisherId: serviceExtinguisherId,
      index: 1,
      url: inspection.foto1Url,
    );
    final foto2Path = await _downloadPhotoIfNeeded(
      serviceExtinguisherId: serviceExtinguisherId,
      index: 2,
      url: inspection.foto2Url,
    );
    final foto3Path = await _downloadPhotoIfNeeded(
      serviceExtinguisherId: serviceExtinguisherId,
      index: 3,
      url: inspection.foto3Url,
    );

    // Importante: conservamos también las URLs originales, pero agregamos paths locales
    // para modo offline.
    return InspectionDetailModel(
      id: inspection.id,
      servicioExtintorId: inspection.servicioExtintorId,
      foto1Url: inspection.foto1Url,
      foto2Url: inspection.foto2Url,
      foto3Url: inspection.foto3Url,
      foto1Path: foto1Path ?? inspection.foto1Path,
      foto2Path: foto2Path ?? inspection.foto2Path,
      foto3Path: foto3Path ?? inspection.foto3Path,
      accesibilidad: inspection.accesibilidad,
      observaciones: inspection.observaciones,
      ubicacion: inspection.ubicacion,
      instalacion: inspection.instalacion,
      instrucciones: inspection.instrucciones,
      clasificacion: inspection.clasificacion,
      recarga: inspection.recarga,
      certificacion: inspection.certificacion,
      presion: inspection.presion,
      seguridad: inspection.seguridad,
      estado: inspection.estado,
      carga: inspection.carga,
      soporte: inspection.soporte,
      activacion: inspection.activacion,
      manguera: inspection.manguera,
      boquilla: inspection.boquilla,
      abrazadera: inspection.abrazadera,
      usuarioCreadorId: inspection.usuarioCreadorId,
      usuarioActualizadorId: inspection.usuarioActualizadorId,
      createdAt: inspection.createdAt,
      updatedAt: inspection.updatedAt,
    );
  }

  Future<String?> _downloadPhotoIfNeeded({
    required int serviceExtinguisherId,
    required int index,
    required String? url,
  }) async {
    if (url == null || url.isEmpty) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final inspectionDir = Directory(path.join(appDir.path, 'inspecciones'));
      if (!await inspectionDir.exists()) {
        await inspectionDir.create(recursive: true);
      }

      final fileName =
          'servicioExtintor_${serviceExtinguisherId}_foto$index.jpg';
      final filePath = path.join(inspectionDir.path, fileName);

      // Re-descargar siempre (si cambió en servidor)
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Usamos un Dio "simple" porque las URLs de fotos suelen ser Cloudinary (sin auth).
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
