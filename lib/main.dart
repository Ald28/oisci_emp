import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oisci_emp/core/notifications/notification_service.dart';
import 'package:oisci_emp/features/services/data/models/pending_extinguisher_model.dart';
import 'package:oisci_emp/features/services/data/models/sede_hive_model.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Hive
  await Hive.initFlutter();

  // Registrar adaptadores de Hive
  Hive.registerAdapter(PendingExtinguisherModelAdapter());
  Hive.registerAdapter(SedeHiveModelAdapter());

  await NotificationService.init();

  runApp(const App());
}
