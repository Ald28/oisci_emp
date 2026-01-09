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
        // Guardar también localmente
        await _localDataSource.createService(
          type: type,
          dateStart: dateStart,
          sedeId: sedeId,
          userId: userId,
        );
        return service;
      } catch (e) {
        // Si falla, guardar solo localmente
        return await _localDataSource.createService(
          type: type,
          dateStart: dateStart,
          sedeId: sedeId,
          userId: userId,
        );
      }
    } else {
      // Sin internet, guardar solo localmente
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
        // Actualizar también localmente
        await _localDataSource.finalizeService(servicioId);
        // Retornar el servicio actualizado del servidor
        return service;
      } catch (e) {
        // Si falla, finalizar solo localmente
        await _localDataSource.finalizeService(servicioId);
        // Obtener el servicio actualizado de local
        final service = await _localDataSource.getServiceById(servicioId);
        if (service == null) {
          throw Exception('Servicio no encontrado');
        }
        return service;
      }
    } else {
      // Sin internet, finalizar solo localmente
      await _localDataSource.finalizeService(servicioId);
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
        // Si falla, retornar lista vacía (no hay datos locales para esto)
        return [];
      }
    } else {
      // Sin internet, retornar lista vacía (no hay datos locales para esto)
      return [];
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
        // Guardar también localmente
        await _localDataSource.createServiceExtinguisher(
          servicioId: servicioId,
          extintorId: extintorId,
          estadoInicial: estadoInicial,
          observaciones: observaciones,
        );
        return serviceExtinguisher;
      } catch (e) {
        // Si falla, guardar solo localmente
        return await _localDataSource.createServiceExtinguisher(
          servicioId: servicioId,
          extintorId: extintorId,
          estadoInicial: estadoInicial,
          observaciones: observaciones,
        );
      }
    } else {
      // Sin internet, guardar solo localmente
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
    await _localDataSource.updateServiceExtinguisherObservations(
      servicioExtintorId: servicioExtintorId,
      observaciones: observaciones,
    );
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
        // El JOIN puede traer campos adicionales del extintor, pero fromMap solo necesita los campos de servicio_extintor
        return results.map((map) {
          // Crear un mapa solo con los campos de servicio_extintor
          final serviceExtinguisherMap = <String, dynamic>{
            'id': map['id'] as int,
            'servicioId': map['servicioId'] as int,
            'extintorId': map['extintorId'] as int,
            'estadoInicial': map['estadoInicial'] as String?,
            'estadoFinal': map['estadoFinal'] as String?,
            'completado': map['completado'] as int? ?? 0,
            'observaciones': map['observaciones'] as String?,
            'usuarioCreadorId': map['usuarioCreadorId'] as int,
            'usuarioActualizadorId': map['usuarioActualizadorId'] as int?,
            'createdAt': map['createdAt'] as String?,
            'updatedAt': map['updatedAt'] as String?,
          };
          // ServiceExtinguisherModel extiende ServiceExtinguisherEntity, así que ya es una entidad
          return ServiceExtinguisherModel.fromMap(serviceExtinguisherMap);
        }).toList();
      }
    } else {
      // Sin internet, obtener solo de local
      final results = await _localDataSource.getServiceExtinguishersByServiceId(
        servicioId,
      );
      // Convertir los Maps a ServiceExtinguisherModel
      return results.map((map) {
        // Crear un mapa solo con los campos de servicio_extintor
        final serviceExtinguisherMap = <String, dynamic>{
          'id': map['id'] as int,
          'servicioId': map['servicioId'] as int,
          'extintorId': map['extintorId'] as int,
          'estadoInicial': map['estadoInicial'] as String?,
          'estadoFinal': map['estadoFinal'] as String?,
          'completado': map['completado'] as int? ?? 0,
          'observaciones': map['observaciones'] as String?,
          'usuarioCreadorId': map['usuarioCreadorId'] as int,
          'usuarioActualizadorId': map['usuarioActualizadorId'] as int?,
          'createdAt': map['createdAt'] as String?,
          'updatedAt': map['updatedAt'] as String?,
        };
        // ServiceExtinguisherModel extiende ServiceExtinguisherEntity, así que ya es una entidad
        return ServiceExtinguisherModel.fromMap(serviceExtinguisherMap);
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
        // Guardar también localmente
        await _localDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
        );
        return maintenanceDetail;
      } catch (e) {
        // Si falla, guardar solo localmente
        return await _localDataSource.createMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
        );
      }
    } else {
      // Sin internet, guardar solo localmente
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
        // También actualizar localmente
        await _localDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
        );
        return result;
      } catch (e) {
        // Si falla HTTP, actualizar solo localmente
        return await _localDataSource.updateMaintenanceDetail(
          servicioExtintorId: servicioExtintorId,
          checklistData: checklistData,
        );
      }
    } else {
      // Sin conexión, actualizar solo localmente
      return await _localDataSource.updateMaintenanceDetail(
        servicioExtintorId: servicioExtintorId,
        checklistData: checklistData,
      );
    }
  }
}
