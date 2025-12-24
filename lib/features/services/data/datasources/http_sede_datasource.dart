import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'sede_datasource.dart';
import '../models/sede_model.dart';

class HttpSedeDataSource implements SedeDataSource {
  final Dio _dio = DioClient().dio;

  @override
  Future<List<SedeModel>> getSedes() async {
    try {
      final response = await _dio.get('/sede/list-sedes');
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['ok'] == true && responseData['data'] != null) {
        final sedesList = responseData['data'] as List;
        return sedesList
            .map((json) => SedeModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Error al obtener sedes: ${responseData['message'] ?? 'Error desconocido'}');
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        throw Exception(errorData?['message'] ?? 'Error al obtener sedes');
      }
      rethrow;
    }
  }
}

