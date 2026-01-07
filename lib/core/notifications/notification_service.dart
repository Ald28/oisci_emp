import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Crear canal de notificaciones (requerido para Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'sync_channel',
      'Sincronización',
      description: 'Notificaciones de sincronización de registros',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Inicializar el plugin
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    final initialized = await _notif.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar cuando el usuario toca la notificación
      },
    );

    if (initialized != null && initialized) {
      // Crear el canal en Android (requerido para Android 8.0+)
      await _notif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }

    _initialized = true;
  }

  /// Solicitar permisos de notificaciones (requerido para Android 13+)
  static Future<bool> requestPermissions() async {
    // Para Android 13+ (API 33+), necesitamos solicitar el permiso POST_NOTIFICATIONS
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Verificar si se tienen permisos de notificaciones
  static Future<bool> hasPermissions() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<void> show(String title, String body) async {
    await _showInternal(title: title, body: body);
  }

  static Future<void> showNamed({
    required String title,
    required String body,
  }) async {
    await _showInternal(title: title, body: body);
  }

  static Future<void> _showInternal({
    required String title,
    required String body,
  }) async {
    // Verificar y solicitar permisos si es necesario
    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) {
        // Si no se otorgaron permisos, no podemos mostrar la notificación
        return;
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Sincronización',
      channelDescription: 'Notificaciones de sincronización de registros',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    // Usar un ID único basado en timestamp para evitar reemplazar notificaciones
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    await _notif.show(notificationId, title, body, details);
  }

  /// Mostrar notificación de progreso (actualizable)
  static Future<void> showProgress({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    // Verificar y solicitar permisos si es necesario
    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) {
        // Si no se otorgaron permisos, no podemos mostrar la notificación
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Sincronización',
      channelDescription: 'Notificaciones de sincronización de registros',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      playSound: false, // No reproducir sonido en cada actualización
      enableVibration: false, // No vibrar en cada actualización
    );

    final details = NotificationDetails(android: androidDetails);
    await _notif.show(id, title, body, details);
  }

  /// Cancelar una notificación por su ID
  static Future<void> cancel(int id) async {
    await _notif.cancel(id);
  }

  /// Cancelar todas las notificaciones
  static Future<void> cancelAll() async {
    await _notif.cancelAll();
  }
}
