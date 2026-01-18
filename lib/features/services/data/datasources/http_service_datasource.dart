import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/service_model.dart';
import '../models/service_extinguisher_model.dart';
import '../models/maintenance_detail_model.dart';
import '../models/inspection_detail_model.dart';

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

  /// Obtener detalle de mantenimiento - GET /mantenimiento/services/extintores/:servicioExtintorId/mantenimiento
  Future<MaintenanceDetailModel?> getMaintenanceDetailByServiceExtinguisherId(
    int servicioExtintorId,
  ) async {
    try {
      final response = await _dio.get(
        '/mantenimiento/services/extintores/$servicioExtintorId/mantenimiento',
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: ... }
      if (responseData['data'] != null) {
        return MaintenanceDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No encontrado, retornar null
        return null;
      }
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al obtener detalle de mantenimiento',
        );
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

  /// Actualizar detalle de mantenimiento - PUT /mantenimiento/extintores/:servicioExtintorId/mantenimiento
  Future<MaintenanceDetailModel> updateMaintenanceDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.put(
        '/mantenimiento/extintores/$servicioExtintorId/mantenimiento',
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

  /// Actualizar observaciones de ServicioExtintor - PATCH /services/servicio-extintor/:servicioExtintorId/observacion
  Future<ServiceExtinguisherModel> updateServiceExtinguisherObservations({
    required int servicioExtintorId,
    required String? observaciones,
  }) async {
    try {
      final response = await _dio.patch(
        '/services/servicio-extintor/$servicioExtintorId/observacion',
        data: {'observaciones': observaciones},
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna el ServicioExtintor actualizado
      return ServiceExtinguisherModel.fromJson(responseData);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al actualizar observaciones',
        );
      }
      rethrow;
    }
  }

  /// Obtener servicio por ID - GET /services/:servicioId
  Future<ServiceModel?> getServiceById(int servicioId) async {
    try {
      final response = await _dio.get('/services/$servicioId');
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: ... }
      if (responseData['data'] != null) {
        return ServiceModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No encontrado, retornar null
        return null;
      }
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al obtener servicio');
      }
      rethrow;
    }
  }

  /// Obtener servicios EN_PROCESO por usuarioCreadorId - GET /services/en-proceso
  Future<List<ServiceModel>> getServicesInProgress() async {
    try {
      final response = await _dio.get('/services/en-proceso');
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

  /// Crear detalle de inspección - POST /inspeccion/services/extintores/:servicioExtintorId/inspeccion
  Future<InspectionDetailModel> createInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Separar fotos (File) del resto de datos
      final File? foto1 = data.remove('foto1') as File?;
      final File? foto2 = data.remove('foto2') as File?;
      final File? foto3 = data.remove('foto3') as File?;

      // Crear FormData para multipart
      final formData = FormData();

      // Agregar servicioExtintorId
      formData.fields.add(
        MapEntry('servicioExtintorId', servicioExtintorId.toString()),
      );

      // Agregar fotos si existen
      if (foto1 != null) {
        formData.files.add(
          MapEntry(
            'foto1',
            await MultipartFile.fromFile(foto1.path, filename: 'foto1.jpg'),
          ),
        );
      }
      if (foto2 != null) {
        formData.files.add(
          MapEntry(
            'foto2',
            await MultipartFile.fromFile(foto2.path, filename: 'foto2.jpg'),
          ),
        );
      }
      if (foto3 != null) {
        formData.files.add(
          MapEntry(
            'foto3',
            await MultipartFile.fromFile(foto3.path, filename: 'foto3.jpg'),
          ),
        );
      }

      // Agregar datos del checklist como JSON stringificado
      formData.fields.add(MapEntry('data', jsonEncode(data)));

      // Usar timeout extendido para peticiones con imágenes
      final response = await _dio.post(
        '/inspeccion/services/extintores/$servicioExtintorId/inspeccion',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(
            seconds: 120,
          ), // 2 minutos para subir imágenes
          sendTimeout: const Duration(
            seconds: 120,
          ), // 2 minutos para enviar imágenes
        ),
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: ... }
      if (responseData['data'] != null) {
        return InspectionDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al crear detalle de inspección: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al crear detalle de inspección',
        );
      }
      rethrow;
    }
  }

  /// Obtener detalle de inspección - GET /inspeccion/services/extintores/:servicioExtintorId/inspeccion
  Future<InspectionDetailModel?> getInspectionDetailByServiceExtinguisherId(
    int servicioExtintorId,
  ) async {
    try {
      final response = await _dio.get(
        '/inspeccion/services/extintores/$servicioExtintorId/inspeccion',
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: ... }
      if (responseData['data'] != null) {
        return InspectionDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No encontrado, retornar null
        return null;
      }
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al obtener detalle de inspección',
        );
      }
      rethrow;
    }
  }

  /// Actualizar detalle de inspección - PUT /inspeccion/extintores/:servicioExtintorId/inspeccion
  Future<InspectionDetailModel> updateInspectionDetail({
    required int servicioExtintorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Separar fotos (File) del resto de datos
      final File? foto1 = data.remove('foto1') as File?;
      final File? foto2 = data.remove('foto2') as File?;
      final File? foto3 = data.remove('foto3') as File?;

      // Crear FormData para multipart
      final formData = FormData();

      // Agregar fotos si existen
      if (foto1 != null) {
        formData.files.add(
          MapEntry(
            'foto1',
            await MultipartFile.fromFile(foto1.path, filename: 'foto1.jpg'),
          ),
        );
      }
      if (foto2 != null) {
        formData.files.add(
          MapEntry(
            'foto2',
            await MultipartFile.fromFile(foto2.path, filename: 'foto2.jpg'),
          ),
        );
      }
      if (foto3 != null) {
        formData.files.add(
          MapEntry(
            'foto3',
            await MultipartFile.fromFile(foto3.path, filename: 'foto3.jpg'),
          ),
        );
      }

      // Agregar datos del checklist como JSON stringificado
      formData.fields.add(MapEntry('data', jsonEncode(data)));

      // Usar timeout extendido para peticiones con imágenes
      final response = await _dio.put(
        '/inspeccion/extintores/$servicioExtintorId/inspeccion',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(
            seconds: 120,
          ), // 2 minutos para subir imágenes
          sendTimeout: const Duration(
            seconds: 120,
          ), // 2 minutos para enviar imágenes
        ),
      );
      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: ... }
      if (responseData['data'] != null) {
        return InspectionDetailModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al actualizar detalle de inspección: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al actualizar detalle de inspección',
        );
      }
      rethrow;
    }
  }
}
