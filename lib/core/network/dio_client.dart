import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000',
        connectTimeout: const Duration(
          seconds: 30,
        ), // Aumentado para conexiones lentas
        receiveTimeout: const Duration(
          seconds: 60,
        ), // Aumentado para subida de imágenes
        sendTimeout: const Duration(
          seconds: 60,
        ), // Aumentado para subida de imágenes
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.add(AuthInterceptor());
  }
}
