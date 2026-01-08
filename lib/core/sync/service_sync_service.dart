import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/services/data/datasources/local_service_datasource.dart';
import '../../features/services/data/datasources/http_service_datasource.dart';
import '../../features/services/data/models/service_model.dart';
import '../../features/services/data/models/service_extinguisher_model.dart';

/// Servicio de sincronización para servicios pendientes
class ServiceSyncService {
  final LocalServiceDataSource _localDataSource;
  final HttpServiceDataSource _httpDataSource;

  ServiceSyncService({
    LocalServiceDataSource? localDataSource,
    HttpServiceDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalServiceDataSource(),
       _httpDataSource = httpDataSource ?? HttpServiceDataSource();

  /// Sincronizar servicios pendientes
  Future<int> syncPendingServices() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0;
    }

    final pendingItems = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE',
    );
    if (pendingItems.isEmpty) {
      return 0;
    }

    int syncedCount = 0;

    for (final item in pendingItems) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final service = await _httpDataSource.createService(data);

        // Buscar el servicio temporal por type, dateStart y sedeId (únicos según constraint)
        final tempService = await _localDataSource.getServiceInProgress(
          data['type'] as String,
        );
        if (tempService != null && tempService.id < 0) {
          // Actualizar en la base de datos local con el ID real
          await _localDataSource.updateServiceAfterSync(
            tempId: tempService.id,
            service: service,
          );
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
        continue;
      }
    }

    return syncedCount;
  }

  /// Sincronizar ServicioExtintor pendientes
  Future<int> syncPendingServiceExtinguishers() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0;
    }

    final pendingItems = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE_EXTINGUISHER',
    );
    if (pendingItems.isEmpty) {
      return 0;
    }

    int syncedCount = 0;

    for (final item in pendingItems) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final servicioId = data['servicioId'] as int;

        // Obtener el servicioId real (puede ser temporal, puede haber sido sincronizado)
        ServiceModel? service = await _localDataSource.getServiceById(
          servicioId,
        );
        if (service == null || service.id < 0) {
          // Si es temporal o no existe, intentar sincronizar el servicio primero
          await syncPendingServices();
          service = await _localDataSource.getServiceById(servicioId);
          if (service == null || service.id < 0) {
            await _localDataSource.updateSyncError(
              item['id'] as int,
              'Servicio no encontrado o pendiente de sincronización',
            );
            continue;
          }
        }

        final serviceExtinguisher = await _httpDataSource
            .addExtinguisherToService(
              servicioId: service.id,
              data: {
                'extintorId': data['extintorId'],
                'estadoInicial': data['estadoInicial'],
                'observaciones': data['observaciones'],
              },
            );

        // Buscar el servicioExtintor temporal por servicioId y extintorId
        final tempServiceExtinguisher = await _localDataSource
            .getServiceExtinguisherByServiceAndExtinguisher(
              servicioId: servicioId,
              extintorId: data['extintorId'] as int,
            );

        if (tempServiceExtinguisher != null && tempServiceExtinguisher.id < 0) {
          // Actualizar en la base de datos local
          await _localDataSource.updateServiceExtinguisherAfterSync(
            tempId: tempServiceExtinguisher.id,
            serviceExtinguisher: serviceExtinguisher,
          );
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
        continue;
      }
    }

    return syncedCount;
  }

  /// Sincronizar MantenimientoDetalle pendientes
  Future<int> syncPendingMaintenanceDetails() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0;
    }

    final pendingItems = await _localDataSource.getPendingSyncItems(
      'CREATE_MAINTENANCE_DETAIL',
    );
    if (pendingItems.isEmpty) {
      return 0;
    }

    int syncedCount = 0;

    for (final item in pendingItems) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final servicioExtintorId = data['servicioExtintorId'] as int;

        // Obtener el servicioExtintorId real (puede ser temporal, puede haber sido sincronizado)
        ServiceExtinguisherModel? serviceExtinguisher = await _localDataSource
            .getServiceExtinguisherById(servicioExtintorId);
        if (serviceExtinguisher == null || serviceExtinguisher.id < 0) {
          // Si es temporal o no existe, intentar sincronizar primero
          await syncPendingServiceExtinguishers();
          serviceExtinguisher = await _localDataSource
              .getServiceExtinguisherById(servicioExtintorId);
          if (serviceExtinguisher == null || serviceExtinguisher.id < 0) {
            await _localDataSource.updateSyncError(
              item['id'] as int,
              'ServicioExtintor no encontrado o pendiente de sincronización',
            );
            continue;
          }
        }

        final maintenanceDetail = await _httpDataSource.createMaintenanceDetail(
          servicioExtintorId: serviceExtinguisher.id,
          data: {
            'mantenimiento': data['mantenimiento'],
            'recarga': data['recarga'],
            'agenteCarga': data['agenteCarga'],
            'pruebaHidrostatica': data['pruebaHidrostatica'],
            'bajaExtintor': data['bajaExtintor'],
            'motivoBaja': data['motivoBaja'],
            'pintura': data['pintura'],
            'recargaCartucho': data['recargaCartucho'],
            'cambioPartes': data['cambioPartes'],
          },
        );

        // Buscar el mantenimientoDetalle temporal por servicioExtintorId
        final tempMaintenanceDetail = await _localDataSource
            .getMaintenanceDetailByServiceExtinguisherId(servicioExtintorId);

        if (tempMaintenanceDetail != null && tempMaintenanceDetail.id < 0) {
          // Actualizar en la base de datos local
          await _localDataSource.updateMaintenanceDetailAfterSync(
            tempId: tempMaintenanceDetail.id,
            maintenanceDetail: maintenanceDetail,
          );
        }

        // Eliminar de la cola
        await _localDataSource.deleteQueueItem(item['id'] as int);
        syncedCount++;
      } catch (e) {
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
        continue;
      }
    }

    return syncedCount;
  }

  /// Sincronizar todos los servicios pendientes
  Future<int> syncAllPendingServices() async {
    int totalSynced = 0;

    // Sincronizar en orden: Servicio -> ServicioExtintor -> MantenimientoDetalle
    totalSynced += await syncPendingServices();
    totalSynced += await syncPendingServiceExtinguishers();
    totalSynced += await syncPendingMaintenanceDetails();

    return totalSynced;
  }

  /// Obtener cantidad de servicios pendientes
  Future<int> getPendingCount() async {
    final services = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE',
    );
    final serviceExtinguishers = await _localDataSource.getPendingSyncItems(
      'CREATE_SERVICE_EXTINGUISHER',
    );
    final maintenanceDetails = await _localDataSource.getPendingSyncItems(
      'CREATE_MAINTENANCE_DETAIL',
    );

    return services.length +
        serviceExtinguishers.length +
        maintenanceDetails.length;
  }
}
