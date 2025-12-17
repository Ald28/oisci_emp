import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class UserRemoteDataSource {
  final dio = DioClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        "/users/login",
        data: {"email": email, "password": password},
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception("Error de conexión: ${e.message}");
    } catch (e) {
      throw Exception("Error inesperado al iniciar sesión");
    }
  }
}