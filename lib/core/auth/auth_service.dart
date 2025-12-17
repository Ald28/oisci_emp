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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
