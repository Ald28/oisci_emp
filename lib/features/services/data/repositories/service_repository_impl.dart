import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_extinguisher_entity.dart';
import '../../domain/entities/maintenance_detail_entity.dart';
import '../datasources/local_service_datasource.dart';
import '../datasources/http_service_datasource.dart';
import '../models/service_extinguisher_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final LocalServiceDataSource _localDataSource;
  final HttpServiceDataSource _httpDataSource;

  ServiceRepositoryImpl({
    LocalServiceDataSource? localDataSource,
    HttpServiceDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalServiceDataSource(),
       _httpDataSource = httpDataSource ?? HttpServiceDataSource();

  /// Determinar si hay conexión a internet
  Future<bool> _hasInternet() async {
    return await InternetConnectionChecker().hasConnection;
  }

  @override
  Future<ServiceEntity> createService({
    required String type,
    required DateTime dateStart,
    required int sedeId,
    required int userId,
  }) async {
    final hasInternet = await _hasInternet();
    final data = {
      'type': type,
      'dateStart': dateStart.toIso8601String(),
      'sedeId': sedeId,
      'userId': userId,
    };

    if (hasInternet) {
      try {
        // Intentar crear en el servidor
        final service = await _httpDataSource.createService(data);
        // Guardar también localmente (sin agregar a sync_queue)
        await _localDataSource.saveService(service);
        return service;
      } catch (e) {
        // Si falla, guardar solo localmente (con sync_queue)
        return await _localDataSource.createService(
          type: type,
          dateStart: dateStart,
          sedeId: sedeId,
          userId: userId,
        );
      }
    } else {
      // Sin internet, guardar solo localmente (con sync_queue)
      return await _localDataSource.createService(
        type: type,
        dateStart: dateStart,
        sedeId: sedeId,
        userId: userId,
      );
    }
  }

  @override
  Future<ServiceEntity?> getServiceById(int id) async {
    return await _localDataSource.getServiceById(id);
  }

  @override
  Future<ServiceEntity?> getServiceInProgress(String type) async {
    return await _localDataSource.getServiceInProgress(type);
  }

  @override
  Future<ServiceEntity> finalizeService(int servicioId) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar finalizar en el servidor
        final service = await _httpDataSource.finalizeService(servicioId);
        // Actualizar también localmente (sin agregar a sync_queue)
        await _localDataSource.finalizeService(
          servicioId,
          addToSyncQueue: false,
        );
        // Retornar el servicio actualizado del servidor
        return service;
      } catch (e) {
        // Si falla, finalizar solo localmente (con sync_queue)
        await _localDataSource.finalizeService(
          servicioId,
          addToSyncQueue: true,
        );
        // Obtener el servicio actualizado de local
        final service = await _localDataSource.getServiceById(servicioId);
        if (service == null) {
          throw Exception('Servicio no encontrado');
        }
        return service;
      }
    } else {
      // Sin internet, finalizar solo localmente (con sync_queue)
      await _localDataSource.finalizeService(servicioId, addToSyncQueue: true);
      // Obtener el servicio actualizado de local
      final service = await _localDataSource.getServiceById(servicioId);
      if (service == null) {
        throw Exception('Servicio no encontrado');
      }
      return service;
    }
  }

  @override
  Future<List<ServiceEntity>> getServicesInProgress() async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar obtener del servidor
        final services = await _httpDataSource.getServicesInProgress();
        // ServiceModel extiende ServiceEntity, así que ya es una entidad
        return services;
      } catch (e) {
        // Si falla, obtener de local (offline)
        return await _localDataSource.getServicesInProgress();
      }
    } else {
      // Sin internet, obtener de local (offline)
      return await _localDataSource.getServicesInProgress();
    }
  }

  @override
  Future<ServiceExtinguisherEntity> addExtinguisherToService({
    required int servicioId,
    required int extintorId,
    String? estadoInicial,
    String? observaciones,
  }) async {
    final hasInternet = await _hasInternet();
    final data = {
      'extintorId': extintorId,
      'estadoInicial': estadoInicial,
      'observaciones': observaciones,
    };

    if (hasInternet) {
      try {
        // Intentar crear en el servidor
        final serviceExtinguisher = await _httpDataSource
            .addExtinguisherToService(servicioId: servicioId, data: data);
        // Guardar también localmente (sin agregar a sync_queue)
        await _localDataSource.saveServiceExtinguisher(serviceExtinguisher);
        return serviceExtinguisher;
      } catch (e) {
        // Si falla, guardar solo localmente (con sync_queue)
        return await _localDataSource.createServiceExtinguisher(
          servicioId: servicioId,
          extintorId: extintorId,
          estadoInicial: estadoInicial,
          observaciones: observaciones,
        );
      }
    } else {
      // Sin internet, guardar solo localmente (con sync_queue)
      return await _localDataSource.createServiceExtinguisher(
        servicioId: servicioId,
        extintorId: extintorId,
        estadoInicial: estadoInicial,
        observaciones: observaciones,
      );
    }
  }

  @override
  Future<ServiceExtinguisherEntity?>
  getServiceExtinguisherByServiceAndExtinguisher({
    required int servicioId,
    required int extintorId,
  }) async {
    return await _localDataSource
        .getServiceExtinguisherByServiceAndExtinguisher(
          servicioId: servicioId,
          extintorId: extintorId,
        );
  }

  @override
  Future<void> markServiceExtinguisherCompleted(int servicioExtintorId) async {
    await _localDataSource.markServiceExtinguisherCompleted(servicioExtintorId);
  }

  @override
  Future<void> updateServiceExtinguisherObservations({
    required int servicioExtintorId,
    required String? observaciones,
  }) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar actualizar en el servidor
        await _httpDataSource.updateServiceExtinguisherObservations(
          servicioExtintorId: servicioExtintorId,
          observaciones: observaciones,
        );
        // También actualizar localmente (sin agregar a sync_queue)
        await _localDataSource.updateServiceExtinguisherObservations(
          servicioExtintorId: servicioExtintorId,
          observaciones: observaciones,
          addToSyncQueue: false,
        );
      } catch (e) {
        // Si falla HTTP, actualizar solo localmente (con sync_queue)
        await _localDataSource.updateServiceExtinguisherObservations(
          servicioExtintorId: servicioExtintorId,
          observaciones: observaciones,
          addToSyncQueue: true,
        );
      }
    } else {
      // Sin conexión, actualizar solo localmente (con sync_queue)
      await _localDataSource.updateServiceExtinguisherObservations(
        servicioExtintorId: servicioExtintorId,
        observaciones: observaciones,
        addToSyncQueue: true,
      );
    }
  }

  @override
  Future<List<ServiceExtinguisherEntity>> getServiceExtinguishersByServiceId(
    int servicioId,
  ) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar obtener del servidor
        final serviceExtinguishers = await _httpDataSource
            .listServiceExtinguishers(servicioId);
        // ServiceExtinguisherModel extiende ServiceExtinguisherEntity, así que ya es una entidad
        return serviceExtinguishers;
      } catch (e) {
        // Si falla, obtener de local
        final results = await _localDataSource
            .getServiceExtinguishersByServiceId(servicioId);
        // Convertir los Maps a ServiceExtinguisherModel
        // El JOIN incluye campos del extintor (serialNumber, location, etc.)
        return results.map((map) {
          // El JOIN ya incluye serialNumber y otros campos del extintor
          return ServiceExtinguisherModel.fromMap(map);
        }).toList();
      }
    } else {
      // Sin internet, obtener solo de local
      final results = await _localDataSource.getServiceExtinguishersByServiceId(
        servicioId,
      );
      // Convertir los Maps a ServiceExtinguisherModel
      // El JOIN incluye campos del extintor (serialNumber, location, etc.)
      return results.map((map) {
        // El JOIN ya incluye serialNumber y otros campos del extintor
        return ServiceExtinguisherModel.fromMap(map);
      }).toList();
    }
  }

  @override
  Future<MaintenanceDetailEntity> createMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  }) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar crear en el servidor
        final maintenanceDetail = await _httpDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          data: checklistData,
        );
        // Guardar también localmente (sin agregar a sync_queue)
        await _localDataSource.saveMaintenanceDetail(maintenanceDetail);
        return maintenanceDetail;
      } catch (e) {
        // Si falla, guardar solo localmente (con sync_queue)
        return await _localDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
        );
      }
    } else {
      // Sin internet, guardar solo localmente (con sync_queue)
      return await _localDataSource.createMaintenanceDetail(
        servicioExtintorId: servicioExtintorId,
        checklistData: checklistData,
      );
    }
  }

  @override
  Future<MaintenanceDetailEntity?> getMaintenanceDetailByServiceExtinguisherId(
    int servicioExtintorId,
  ) async {
    return await _localDataSource.getMaintenanceDetailByServiceExtinguisherId(
      servicioExtintorId,
    );
  }

  @override
  Future<MaintenanceDetailEntity> updateMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> checklistData,
  }) async {
    final hasInternet = await _hasInternet();

    if (hasInternet) {
      try {
        // Intentar actualizar en el servidor
        final result = await _httpDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          data: checklistData,
        );
        // También actualizar localmente (sin agregar a sync_queue)
        await _localDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
          addToSyncQueue: false,
        );
        return result;
      } catch (e) {
        // Si falla HTTP, actualizar solo localmente (con sync_queue)
        return await _localDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
          addToSyncQueue: true,
        );
      }
    } else {
      // Sin conexión, actualizar solo localmente (con sync_queue)
      return await _localDataSource.updateMaintenanceDetail(
        servicioExtintorId: servicioExtintorId,
        checklistData: checklistData,
        addToSyncQueue: true,
      );
    }
  }
}
