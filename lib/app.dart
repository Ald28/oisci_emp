import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';
import 'core/sync/sync_service.dart';
import 'core/sync/sede_sync_service.dart';
import 'features/users/presentation/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

/// GlobalKey para el Navigator, usado por el interceptor para redirecciones globales
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  Future<Map<String, dynamic>> _loadSession() async {
    return await AuthService.loadSession();
  }

  /// Sincronizar extintores pendientes en background
  Future<void> _syncPendingExtinguishers() async {
    try {
      final syncService = SyncService();
      await syncService.syncPendingExtinguishers();
    } catch (e) {
      // Silenciar errores de sincronización en background
      // No queremos interrumpir el inicio de la app
    }
  }

  /// Sincronizar sedes en background
  Future<void> _syncSedes() async {
    try {
      final sedeSyncService = SedeSyncService();
      await sedeSyncService.syncSedes();
    } catch (e) {
      // Silenciar errores de sincronización en background
      // Las sedes se pueden cargar desde local si falla
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: FutureBuilder(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data!;
          final token = session["accessToken"];
          final userId = session["userId"];
          final name = session["name"];

          if (token != null && userId != null && name != null) {
            // Sincronizar pendientes y sedes en background cuando hay sesión activa
            _syncPendingExtinguishers();
            _syncSedes();
            return HomePage(userId: userId, name: name);
          }

          return LoginPage();
        },
      ),
    );
  }
}
