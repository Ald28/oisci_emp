import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../../app.dart';
import '../../../features/users/presentation/login_page.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final session = await AuthService.loadSession();
      final token = session["accessToken"];

      if (token != null && token.isNotEmpty) {
        options.headers["Authorization"] = "Bearer $token";
      }
    } catch (e) {
      // Si hay error al cargar la sesión, continuar sin token
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Si es un error 401, el token podría haber expirado
    if (err.response?.statusCode == 401) {
      // Cerrar sesión (mantiene credenciales para login offline)
      AuthService.logout();
      
      // Redirigir al login usando el navigatorKey global
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Redirigir después de un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          final currentContext = navigatorKey.currentContext;
          if (currentContext != null) {
            Navigator.of(currentContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        });
      }
    }
    handler.next(err);
  }
}