import 'package:flutter/material.dart';
import 'package:oisci_emp/core/notifications/notification_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  runApp(const App());
}