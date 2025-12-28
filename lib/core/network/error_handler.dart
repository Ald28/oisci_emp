import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../../features/users/presentation/login_page.dart';

/// Helper para manejar errores HTTP de forma reutilizable
class ErrorHandler {
  /// Maneja errores DioException y muestra mensajes apropiados
  /// Retorna true si el error fue manejado (401), false si necesita manejo adicional
  static bool handleDioError(
    BuildContext context,
    DioException error, {
    String? customMessage,
    VoidCallback? on401,
  }) {
    // Error 401: Token expirado o inválido
    if (error.response?.statusCode == 401) {
      // Cerrar sesión (mantiene credenciales para login offline)
      AuthService.logout();
      
      // Mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Callback personalizado o redirección por defecto
      if (on401 != null) {
        Future.delayed(const Duration(seconds: 1), on401);
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        });
      }
      
      return true; // Error manejado
    }
    
    // Otros errores
    final message = customMessage ?? 
        error.response?.data?['message'] ?? 
        error.message ?? 
        'Error desconocido';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    return false; // Error no manejado completamente
  }
  
  /// Obtiene un mensaje de error legible desde un DioException
  static String getErrorMessage(DioException error, {String? defaultMessage}) {
    if (error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      return data['message'] ?? defaultMessage ?? 'Error desconocido';
    }
    return defaultMessage ?? error.message ?? 'Error desconocido';
  }
}

