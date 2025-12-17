import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notif.initialize(settings);
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
    const androidDetails = AndroidNotificationDetails(
      'sync_channel',
      'Sincronización',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notif.show(DateTime.now().millisecond, title, body, details);
  }
}