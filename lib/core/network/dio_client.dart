import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: "http://192.168.1.12:8000",
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {"Content-Type": "application/json"},
    ));

    dio.interceptors.add(AuthInterceptor());
  }
}