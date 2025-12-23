import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'extinguisher_datasource.dart';
import '../models/extinguisher_model.dart';

/// Implementación HTTP: DataSource de Extintores (Backend Real)
/// Endpoint: GET /nfc/search/:codigoNFC
class HttpExtinguisherDataSource implements ExtinguisherDataSource {
  final Dio _dio = DioClient().dio;

  @override
  Future<ExtinguisherModel?> searchExtinguisher(String query) async {
    try {
      // Endpoint: GET /nfc/search/:codigoNFC
      // Busca por código NFC, número de serie o cualquier identificador
      final response = await _dio.get(
        '/nfc/search/$query',
      );

      // El backend retorna: { ok: true, data: {...} } o { ok: false, message: "..." }
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['ok'] == true && responseData['data'] != null) {
        return ExtinguisherModel.fromJson(responseData['data'] as Map<String, dynamic>);
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
}

