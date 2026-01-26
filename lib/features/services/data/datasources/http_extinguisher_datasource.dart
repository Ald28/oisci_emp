import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/extinguisher_entity.dart';
import 'extinguisher_datasource.dart';
import '../models/extinguisher_model.dart';

class HttpExtinguisherDataSource implements ExtinguisherDataSource {
  final Dio _dio = DioClient().dio;

  @override
  Future<ExtinguisherModel?> searchExtinguisher(String searchTerm, {int? sedeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sedeId != null) {
        queryParams['sedeId'] = sedeId;
      }
      
      final response = await _dio.get(
        '/nfc/search/$searchTerm',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // El backend retorna: { ok: true, data: {...} } o { ok: false, message: "..." }
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
        return ExtinguisherModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      // No encontrado
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Extintor no encontrado
        return null;
      }
      // Otro error, relanzar
      rethrow;
    }
  }

  @override
  Future<ExtinguisherModel?> getExtinguisherById(int extintorId) async {
    try {
      final response = await _dio.get('/nfc/$extintorId');

      // El backend retorna: { ok: true, data: {...} } o { ok: false, message: "..." }
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
        return ExtinguisherModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      // No encontrado
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Extintor no encontrado
        return null;
      }
      // Otro error, relanzar
      rethrow;
    }
  }

  @override
  Future<ExtinguisherModel> createExtinguisher(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/nfc/create-extintor', data: data);

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
        return ExtinguisherModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al crear extintor: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al crear extintor');
      }
      rethrow;
    }
  }

  @override
  Future<List<Extinguisher>> getExtinguishersBySedeId(int sedeId) async {
    try {
      final response = await _dio.get('/nfc/ext-sede/$sedeId');

      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { ok: true, data: [...] }
      if (responseData['ok'] == true && responseData['data'] != null) {
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;

        return dataList
            .map(
              (json) =>
                  ExtinguisherModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      // Si no hay datos, retornar lista vacía
      return [];
    } on DioException catch (e) {
      // Si el backend retorna 404 u otro error controlado, devolvemos lista vacía
      if (e.response?.statusCode == 404) {
        return [];
      }
      // Para otros errores, relanzar para que el repositorio pueda manejar fallback
      rethrow;
    }
  }

  /// Obtener extintores modificados después de un timestamp (sincronización incremental)
  /// GET /nfc/sync/incremental?since=2026-01-22T10:00:00Z
  /// Retorna solo extintores modificados desde el timestamp proporcionado
  Future<List<ExtinguisherModel>> getExtinguishersUpdatedSince(String since) async {
    try {
      final response = await _dio.get(
        '/nfc/sync/incremental',
        queryParameters: {'since': since},
      );

      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { ok: true, data: [...] }
      if (responseData['ok'] == true && responseData['data'] != null) {
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;

        return dataList
            .map(
              (json) =>
                  ExtinguisherModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }
}
