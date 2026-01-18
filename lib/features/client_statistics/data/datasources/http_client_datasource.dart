import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/client_model.dart';
import 'client_datasource.dart';

/// DataSource HTTP para clientes
class HttpClientDataSource implements ClientDataSource {
  final Dio _dio = DioClient().dio;

  @override
  Future<Map<String, dynamic>> searchClients({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/users/clients',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;

      // El backend retorna: { data: [...], pagination: {...} }
      if (responseData['data'] != null) {
        final clientsList = responseData['data'] as List;
        final clients = clientsList
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'data': clients,
          'pagination': responseData['pagination'] as Map<String, dynamic>? ?? {},
        };
      }

      throw Exception(
        'Error al obtener clientes: ${responseData['message'] ?? 'Error desconocido'}',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al obtener clientes');
      }
      rethrow;
    }
  }
}
