import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/service_model.dart';
import '../models/service_extinguisher_model.dart';
import '../models/maintenance_detail_model.dart';

/// DataSource HTTP para servicios
class HttpServiceDataSource {
  final Dio _dio = DioClient().dio;

  /// Crear servicio (Etapa 1) - POST /services/create
  Future<ServiceModel> createService(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/services/create', data: data);
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { message: 'Servicio iniciado', servicioId: ... }
      if (responseData['servicioId'] != null) {
        final servicioId = responseData['servicioId'] as int;
        // Construir ServiceModel con los datos enviados
        // El type viene como String (MANTENIMIENTO o INSPECCION)
        final typeStr = data['type'] as String;
        return ServiceModel(
          id: servicioId,
          type: typeStr, // String, no enum
          dateStart: DateTime.parse(data['dateStart'] as String),
          status: 'EN_PROCESO', // String
          statusValid: 'APROBADO',
          sedeId: data['sedeId'] as int,
          userId: data['userId'] as int,
          usuarioCreadorId: 0, // Se obtiene del token
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception(
        'Error al crear servicio: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al crear servicio');
      }
      rethrow;
    }
  }

  /// Agregar extintor a servicio (Etapa 2) - POST /services/create/:servicioId/extintores
  Future<ServiceExtinguisherModel> addExtinguisherToService({
    required int servicioId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(
        '/services/create/$servicioId/extintores',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { message: 'Extintor agregado al servicio', servicioExtintorId: ... }
      if (responseData['servicioExtintorId'] != null) {
        final servicioExtintorId = responseData['servicioExtintorId'] as int;
        // Construir ServiceExtinguisherModel con los datos enviados
        return ServiceExtinguisherModel(
          id: servicioExtintorId,
          servicioId: servicioId,
          extintorId: data['extintorId'] as int,
          estadoInicial: data['estadoInicial'] as String?, // String, no enum
          observaciones: data['observaciones'] as String?,
          usuarioCreadorId: 0, // Se obtiene del token
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception(
        'Error al agregar extintor: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al agregar extintor');
      }
      rethrow;
    }
  }

  /// Crear detalle de mantenimiento (Etapa 3) - POST /mantenimiento/services/extintores/:servicioExtintorId/mantenimiento
  Future<MaintenanceDetailModel> createMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(
        '/mantenimiento/services/extintores/$servicioExtintorId/mantenimiento',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { message: 'Mantenimiento registrado correctamente', data: ... }
      if (responseData['data'] != null) {
        return MaintenanceDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al crear detalle de mantenimiento: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al crear detalle de mantenimiento',
        );
      }
      rethrow;
    }
  }

  /// Actualizar detalle de mantenimiento - PUT /mantenimiento/services/extintores/:servicioExtintorId/mantenimiento
  Future<MaintenanceDetailModel> updateMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '/mantenimiento/services/extintores/$servicioExtintorId/mantenimiento',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { message: 'Mantenimiento actualizado correctamente', data: ... }
      if (responseData['data'] != null) {
        return MaintenanceDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al actualizar detalle de mantenimiento: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ??
              'Error al actualizar detalle de mantenimiento',
        );
      }
      rethrow;
    }
  }

  /// Finalizar servicio - PUT /services/:servicioId/finalizar
  Future<ServiceModel> finalizeService(int servicioId) async {
    try {
      final response = await _dio.put('/services/$servicioId/finalizar');
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { message: 'Servicio finalizado correctamente', data: {...} }
      if (responseData['data'] != null) {
        return ServiceModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al finalizar servicio: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al finalizar servicio');
      }
      rethrow;
    }
  }

  /// Listar ServicioExtintor por servicioId - GET /services/:servicioId/extintores
  Future<List<ServiceExtinguisherModel>> listServiceExtinguishers(
    int servicioId,
  ) async {
    try {
      final response = await _dio.get('/services/$servicioId/extintores');
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: [...] }
      // Cada item incluye ServicioExtintor con extintor y mantenimientoDetalle anidados
      if (responseData['data'] != null) {
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;
        return dataList.map((json) {
          final jsonMap = json as Map<String, dynamic>;
          // El backend retorna el ServicioExtintor con campos planos
          // El objeto extintor anidado no se usa en el modelo actual
          return ServiceExtinguisherModel.fromJson(jsonMap);
        }).toList();
      }

      throw Exception(
        'Error al listar extintores: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al listar extintores');
      }
      rethrow;
    }
  }

  /// Obtener servicios EN_PROCESO por usuarioCreadorId - GET /services/in-progress
  Future<List<ServiceModel>> getServicesInProgress() async {
    try {
      final response = await _dio.get('/services/in-progress');
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: [...] }
      if (responseData['data'] != null) {
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;
        return dataList
            .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Error al obtener servicios en proceso: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al obtener servicios en proceso',
        );
      }
      rethrow;
    }
  }
}
