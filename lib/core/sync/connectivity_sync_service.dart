import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'sync_service.dart';
import 'service_sync_service.dart';
import 'sync_progress_controller.dart';
import '../notifications/notification_service.dart';

/// Servicio para monitorear conectividad y sincronizar automáticamente
class ConnectivitySyncService {
  final Connectivity _connectivity = Connectivity();
  final SyncService _syncService = SyncService();
  final ServiceSyncService _serviceSyncService = ServiceSyncService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isSyncingServices = false;
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
    if (_isSyncing || _isSyncingServices) {
      return;
    }

    // Verificar cooldown para evitar sincronizaciones muy frecuentes
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < _syncCooldown) {
        return;
      }
    }

    // Verificar si hay registros pendientes antes de sincronizar
    final hasPendingExtinguishers = await _syncService
        .hasPendingExtinguishers();
    final hasPendingServices = await _serviceSyncService.hasPendingServices();

    if (!hasPendingExtinguishers && !hasPendingServices) {
      return; // No hay nada que sincronizar
    }

    // Sincronizar extintores primero
    if (hasPendingExtinguishers) {
      await _syncExtinguishers();
    }

    // Sincronizar servicios después
    if (hasPendingServices) {
      await _syncServices();
    }
  }

  /// Sincronizar extintores pendientes
  Future<void> _syncExtinguishers() async {
    _isSyncing = true;
    _lastSyncTime = DateTime.now();

    // Obtener cantidad de pendientes para la notificación
    final pendingCount = await _syncService.getPendingCount();

    // ID único para la notificación de progreso
    const notificationId = 1001;

    // Mostrar notificación inicial (funciona aunque la app esté cerrada)
    await NotificationService.showProgress(
      id: notificationId,
      title: 'Sincronización en curso',
      body: 'Subiendo extintores pendientes...',
      progress: 0,
      maxProgress: pendingCount,
    );

    // Emitir progreso inicial
    SyncProgressController().emitProgress({
      'step': 'Sincronizando extintores...',
      'progress': 0.0,
      'total': pendingCount,
      'synced': 0,
    });

    try {
      // Sincronizar con progreso
      await for (final progress
          in _syncService.syncPendingExtinguishersWithProgress()) {
        // Emitir progreso para que HomePage pueda escucharlo
        SyncProgressController().emitProgress(progress);

        // Actualizar notificación con progreso
        final total = progress['total'] as int? ?? pendingCount;
        final synced = progress['synced'] as int? ?? 0;
        final progressValue = progress['progress'] as double? ?? 0.0;
        final step = progress['step'] as String? ?? 'Sincronizando...';

        if (progressValue < 1.0) {
          await NotificationService.showProgress(
            id: notificationId,
            title: 'Sincronizando extintores',
            body: step,
            progress: synced,
            maxProgress: total,
          );
        } else {
          // Si el progreso es 100%, cancelar la notificación de progreso
          await NotificationService.cancel(notificationId);
        }
      }

      // Cancelar la notificación de progreso antes de mostrar la de éxito
      await NotificationService.cancel(notificationId);

      // Notificación de éxito
      final finalProgress = await _syncService.getPendingCount();
      if (finalProgress == 0) {
        await NotificationService.show(
          'Sincronización completada',
          'Todos los extintores se han subido exitosamente',
        );
      } else {
        await NotificationService.show(
          'Sincronización parcial',
          'Se subieron algunos extintores. Revisa los errores en la pantalla de sincronización.',
        );
      }
    } catch (e) {
      // Cancelar la notificación de progreso antes de mostrar la de error
      await NotificationService.cancel(notificationId);

      // Notificación de error
      await NotificationService.show(
        'Error de sincronización',
        'No se pudieron subir todos los extintores',
      );

      // Emitir error
      SyncProgressController().emitProgress({
        'step': 'Error',
        'progress': 0.0,
        'error': 'Error durante la sincronización: ${e.toString()}',
      });
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincronizar servicios pendientes
  Future<void> _syncServices() async {
    _isSyncingServices = true;

    // Obtener cantidad de pendientes para la notificación
    final pendingCount = await _serviceSyncService.getPendingCount();

    // ID único para la notificación de progreso (diferente al de extintores)
    const notificationId = 1002;

    // Mostrar notificación inicial (funciona aunque la app esté cerrada)
    await NotificationService.showProgress(
      id: notificationId,
      title: 'Sincronización en curso',
      body: 'Subiendo servicios pendientes...',
      progress: 0,
      maxProgress: pendingCount,
    );

    // Emitir progreso inicial
    SyncProgressController().emitProgress({
      'step': 'Sincronizando servicios...',
      'progress': 0.0,
      'total': pendingCount,
      'synced': 0,
    });

    try {
      // Sincronizar con progreso
      await for (final progress
          in _serviceSyncService.syncPendingServicesWithProgress()) {
        // Emitir progreso para que HomePage pueda escucharlo
        SyncProgressController().emitProgress(progress);

        // Actualizar notificación con progreso
        final total = progress['total'] as int? ?? pendingCount;
        final synced = progress['synced'] as int? ?? 0;
        final progressValue = progress['progress'] as double? ?? 0.0;
        final step = progress['step'] as String? ?? 'Sincronizando...';

        if (progressValue < 1.0) {
          await NotificationService.showProgress(
            id: notificationId,
            title: 'Sincronizando servicios',
            body: step,
            progress: synced,
            maxProgress: total,
          );
        } else {
          // Si el progreso es 100%, cancelar la notificación de progreso
          await NotificationService.cancel(notificationId);
        }
      }

      // Cancelar la notificación de progreso antes de mostrar la de éxito
      await NotificationService.cancel(notificationId);

      // Notificación de éxito
      final finalProgress = await _serviceSyncService.getPendingCount();
      if (finalProgress == 0) {
        await NotificationService.show(
          'Sincronización completada',
          'Todos los servicios se han subido exitosamente',
        );
      } else {
        await NotificationService.show(
          'Sincronización parcial',
          'Se subieron algunos servicios. Revisa los errores en la pantalla de sincronización.',
        );
      }
    } catch (e) {
      // Cancelar la notificación de progreso antes de mostrar la de error
      await NotificationService.cancel(notificationId);

      // Notificación de error
      await NotificationService.show(
        'Error de sincronización',
        'No se pudieron subir todos los servicios',
      );

      // Emitir error
      SyncProgressController().emitProgress({
        'step': 'Error',
        'progress': 0.0,
        'error':
            'Error durante la sincronización de servicios: ${e.toString()}',
      });
    } finally {
      _isSyncingServices = false;
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
