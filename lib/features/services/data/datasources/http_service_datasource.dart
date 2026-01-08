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

  /// Finalizar servicio - PUT /services/:servicioId/finalize
  Future<ServiceModel> finalizeService(int servicioId) async {
    try {
      final response = await _dio.put('/services/$servicioId/finalize');
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
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
}
