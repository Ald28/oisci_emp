import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'extinguisher_datasource.dart';
import '../models/extinguisher_model.dart';

class HttpExtinguisherDataSource implements ExtinguisherDataSource {
  final Dio _dio = DioClient().dio;

  @override
  Future<ExtinguisherModel?> searchExtinguisher(String searchTerm) async {
    try {
      final response = await _dio.get('/nfc/search/$searchTerm');

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
}
