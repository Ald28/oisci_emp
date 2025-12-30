import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String name,
    required String role,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("accessToken", accessToken);
    await prefs.setString("refreshToken", refreshToken);
    await prefs.setString("userId", userId);
    await prefs.setString("name", name);
    await prefs.setString("role", role);
    await prefs.setString("email", email);
    await prefs.setString("password", password);
  }

  static Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "accessToken": prefs.getString("accessToken"),
      "refreshToken": prefs.getString("refreshToken"),
      "userId": prefs.getString("userId"),
      "name": prefs.getString("name"),
      "role": prefs.getString("role"),
      "email": prefs.getString("email"),
      "password": prefs.getString("password"),
    };
  }

  /// Cerrar sesión: Borra solo los tokens de sesión activa
  /// Mantiene email, password, userId, name y role para permitir login offline futuro
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Solo borrar tokens de sesión activa
    // Mantener credenciales y datos del usuario para login offline
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    // NO borrar userId, name, role, email y password para permitir login offline
  }

  /// Limpiar sesión completamente: Borra TODO incluyendo credenciales
  /// Usar solo cuando se quiera eliminar completamente los datos del usuario.
  /// Esto elimina todos los datos guardados: tokens, credenciales y datos del usuario.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpiar todo, incluyendo credenciales
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    await prefs.remove("userId");
    await prefs.remove("name");
    await prefs.remove("role");
    await prefs.remove("email");
    await prefs.remove("password");
  }
}
