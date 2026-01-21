import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/extinguisher_stats_model.dart';
import '../models/service_stats_model.dart';

/// DataSource HTTP para estadísticas
class HttpStatisticsDataSource {
  final Dio _dio = DioClient().dio;

  /// Obtener estadísticas de extintores por sede
  /// GET /extintores/sede/:sedeId
  Future<ExtinguisherStatsModel> getExtinguisherStatsBySedeId(int sedeId) async {
    try {
      final response = await _dio.get('/nfc/extintores/sede/$sedeId');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
        return ExtinguisherStatsModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al obtener estadísticas de extintores: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al obtener estadísticas de extintores',
        );
      }
      rethrow;
    }
  }

  /// Obtener estadísticas de servicios por sede y año
  /// GET /services/servicios/sede/:sedeId?year=2026
  Future<ServiceStatsModel> getServiceStatsBySedeIdAndYear(
    int sedeId,
    int year,
  ) async {
    try {
      final response = await _dio.get(
        '/services/servicios/sede/$sedeId',
        queryParameters: {'year': year},
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['ok'] == true && responseData['data'] != null) {
        return ServiceStatsModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al obtener estadísticas de servicios: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(
          errorData?['message'] ?? 'Error al obtener estadísticas de servicios',
        );
      }
      rethrow;
    }
  }
}
