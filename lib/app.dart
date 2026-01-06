import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/auth/auth_service.dart';
import 'core/sync/extinguisher_sync_service.dart';
import 'core/sync/sede_sync_service.dart';
import 'core/sync/connectivity_sync_service.dart';
import 'features/users/presentation/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

/// GlobalKey para el Navigator, usado por el interceptor para redirecciones globales
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ConnectivitySyncService _connectivitySyncService =
      ConnectivitySyncService();

  Future<Map<String, dynamic>> _loadSession() async {
    return await AuthService.loadSession();
  }

  /// Sincronizar extintores pendientes en background
  Future<void> _syncPendingExtinguishers() async {
    try {
      final syncService = ExtinguisherSyncService();
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

  /// Descargar extintores del servidor y guardar localmente
  Future<void> _syncExtinguishers() async {
    try {
      final extinguisherSyncService = ExtinguisherSyncService();
      await extinguisherSyncService.syncExtinguishers();
    } catch (e) {
      // Silenciar errores de sincronización en background
    }
  }

  @override
  void initState() {
    super.initState();
    // Iniciar monitoreo de conectividad para sincronización automática
    _connectivitySyncService.startMonitoring();
  }

  @override
  void dispose() {
    // Detener monitoreo cuando se destruye el widget
    _connectivitySyncService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
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
            // Sincronizar datos en background cuando hay sesión activa
            _syncPendingExtinguishers(); // Sincronizar extintores pendientes
            _syncSedes(); // Sincronizar sedes
            _syncExtinguishers(); // Descargar extintores del servidor
            return HomePage(userId: userId, name: name);
          }

          return LoginPage();
        },
      ),
    );
  }
}
