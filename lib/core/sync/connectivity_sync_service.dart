import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'sync_service.dart';

/// Servicio para monitorear conectividad y sincronizar automáticamente
class ConnectivitySyncService {
  final Connectivity _connectivity = Connectivity();
  final SyncService _syncService = SyncService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  static const Duration _syncCooldown = Duration(
    seconds: 5,
  ); // Evitar sincronizaciones muy frecuentes

  /// Iniciar monitoreo de conectividad
  void startMonitoring() {
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Verificar si hay conexión real a internet (no solo WiFi/Data)
        final hasInternet = await InternetConnectionChecker().hasConnection;

        if (hasInternet) {
          // Hay conexión a internet, sincronizar automáticamente
          await _syncWhenConnected();
        }
      },
      onError: (error) {
        // Silenciar errores de conectividad
      },
    );

    // Verificar conectividad inicial
    _checkInitialConnectivity();
  }

  /// Verificar conectividad inicial
  Future<void> _checkInitialConnectivity() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (hasInternet) {
      await _syncWhenConnected();
    }
  }

  /// Sincronizar cuando hay conexión
  Future<void> _syncWhenConnected() async {
    // Evitar múltiples sincronizaciones simultáneas
    if (_isSyncing) {
      return;
    }

    // Verificar cooldown para evitar sincronizaciones muy frecuentes
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < _syncCooldown) {
        return;
      }
    }

    _isSyncing = true;
    _lastSyncTime = DateTime.now();

    try {
      // Sincronizar extintores pendientes
      await _syncService.syncPendingExtinguishers();
    } catch (e) {
      // Silenciar errores de sincronización automática
    } finally {
      _isSyncing = false;
    }
  }

  /// Detener monitoreo de conectividad
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Sincronizar manualmente (forzar sincronización)
  Future<int> syncNow() async {
    if (_isSyncing) {
      return 0;
    }

    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0;
    }

    _isSyncing = true;
    try {
      final syncedCount = await _syncService.syncPendingExtinguishers();
      _lastSyncTime = DateTime.now();
      return syncedCount;
    } catch (e) {
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}
