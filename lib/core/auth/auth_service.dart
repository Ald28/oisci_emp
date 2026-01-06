import '../database/app_database.dart';

class AuthService {
  /// Guardar sesión del usuario en SQLite
  /// Se guarda después de un login exitoso con la base de datos central
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String name,
    required String role,
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toIso8601String();

    // Verificar si ya existe un usuario con este userId
    final existing = await db.query(
      'user',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Actualizar usuario existente
      await db.update(
        'user',
        {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'updatedAt': now,
        },
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } else {
      // Insertar nuevo usuario
      await db.insert('user', {
        'userId': userId,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  /// Cargar sesión del usuario desde SQLite
  /// Retorna un mapa con todos los datos del usuario guardados
  static Future<Map<String, dynamic>> loadSession() async {
    final db = await AppDatabase.database;

    final result = await db.query('user', limit: 1, orderBy: 'updatedAt DESC');

    if (result.isEmpty) {
      // Si no hay usuario guardado, retornar mapa con valores null
      return {
        "accessToken": null,
        "refreshToken": null,
        "userId": null,
        "name": null,
        "role": null,
        "email": null,
        "password": null,
      };
    }

    final user = result.first;
    return {
      "accessToken": user['accessToken'] as String?,
      "refreshToken": user['refreshToken'] as String?,
      "userId": user['userId'] as String?,
      "name": user['name'] as String?,
      "role": user['role'] as String?,
      "email": user['email'] as String?,
      "password": user['password'] as String?,
    };
  }

  /// Obtener el userId del usuario guardado
  static Future<String?> getUserId() async {
    final session = await loadSession();
    return session["userId"] as String?;
  }

  /// Cerrar sesión: Borra solo los tokens de sesión activa
  /// Mantiene email, password, userId, name y role para permitir login offline futuro
  static Future<void> logout() async {
    final db = await AppDatabase.database;

    // Solo actualizar los tokens a null, manteniendo los demás datos
    await db.update('user', {
      'accessToken': null,
      'refreshToken': null,
      'updatedAt': DateTime.now().toIso8601String(),
    }, where: 'userId IS NOT NULL');
  }

  /// Limpiar sesión completamente: Borra TODO incluyendo credenciales
  /// Usar solo cuando se quiera eliminar completamente los datos del usuario.
  /// Esto elimina todos los datos guardados: tokens, credenciales y datos del usuario.
  static Future<void> clearSession() async {
    final db = await AppDatabase.database;

    // Eliminar todos los registros de usuario
    await db.delete('user');
  }
}
