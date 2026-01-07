import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oisci_emp/core/notifications/notification_service.dart';
import 'package:oisci_emp/core/database/app_database.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar base de datos SQLite
  await AppDatabase.database;

  // Inicializar servicio de notificaciones
  await NotificationService.init();

  // Solicitar permisos de notificaciones (requerido para Android 13+)
  await NotificationService.requestPermissions();

  runApp(const App());
}
