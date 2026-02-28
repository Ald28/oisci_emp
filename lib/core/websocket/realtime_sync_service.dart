import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/auth/auth_service.dart';
import '../sync/incremental_sync_service.dart';

/// Servicio WebSocket para sincronización en tiempo real
/// Similar a WhatsApp: cuando un dispositivo crea/edita algo,
/// todos los demás dispositivos conectados reciben la notificación inmediatamente
class RealtimeSyncService {
  io.Socket? _socket;
  final IncrementalSyncService _incrementalSyncService;
  final VoidCallback? onConnected;
  bool _isConnected = false;
  bool _isConnecting = false;

  RealtimeSyncService({
    IncrementalSyncService? incrementalSyncService,
    this.onConnected,
  }) : _incrementalSyncService = incrementalSyncService ?? IncrementalSyncService();

  /// Conectar al servidor WebSocket
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      // Obtener token de autenticación
      final session = await AuthService.loadSession();
      final accessToken = session['accessToken'] as String?;
      
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ No hay sesión activa, no se puede conectar WebSocket');
        _isConnecting = false;
        return;
      }

      // Obtener URL base del servidor
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

      // Crear conexión Socket.io
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
            .setAuth({'token': accessToken})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .build(),
      );

      // Eventos de conexión
      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        debugPrint('🔌 WebSocket conectado');
        onConnected?.call();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _isConnecting = false;
        debugPrint('🔌 WebSocket desconectado');
      });

      _socket!.onConnectError((error) {
        _isConnecting = false;
        debugPrint('❌ Error de conexión WebSocket: $error');
      });

      // Eventos de sincronización
      _socket!.on('extinguisher_changed', (data) {
        debugPrint('📡 WebSocket: Extintor cambiado: $data');
        _handleExtinguisherChange(data);
      });

      _socket!.on('service_changed', (data) {
        debugPrint('📡 WebSocket: Servicio cambiado: $data');
        _handleServiceChange(data);
      });

      _socket!.on('service_extinguisher_changed', (data) {
        debugPrint('📡 WebSocket: ServicioExtintor cambiado: $data');
        _handleServiceExtinguisherChange(data);
      });

      _socket!.on('maintenance_detail_changed', (data) {
        debugPrint('📡 WebSocket: MantenimientoDetalle cambiado: $data');
        _handleMaintenanceDetailChange(data);
      });

      _socket!.on('inspection_detail_changed', (data) {
        debugPrint('📡 WebSocket: InspeccionDetalle cambiado: $data');
        _handleInspectionDetailChange(data);
      });

      // Conectar
      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      debugPrint('❌ Error al conectar WebSocket: $e');
    }
  }

  /// Desconectar del servidor WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    debugPrint('🔌 WebSocket desconectado manualmente');
  }

  /// Manejar cambio de extintor
  Future<void> _handleExtinguisherChange(Map<String, dynamic> data) async {
    // Cuando se detecta un cambio, ejecutar sincronización incremental
    // Esto descargará solo los cambios desde la última sincronización
    await _incrementalSyncService.syncIncremental();
  }

  /// Manejar cambio de servicio
  Future<void> _handleServiceChange(Map<String, dynamic> data) async {
    await _incrementalSyncService.syncIncremental();
  }

  /// Manejar cambio de servicio_extintor
  Future<void> _handleServiceExtinguisherChange(Map<String, dynamic> data) async {
    await _incrementalSyncService.syncIncremental();
  }

  /// Manejar cambio de mantenimiento_detalle
  Future<void> _handleMaintenanceDetailChange(Map<String, dynamic> data) async {
    await _incrementalSyncService.syncIncremental();
  }

  /// Manejar cambio de inspeccion_detalle
  Future<void> _handleInspectionDetailChange(Map<String, dynamic> data) async {
    await _incrementalSyncService.syncIncremental();
  }

  /// Verificar si está conectado
  bool get isConnected => _isConnected;
}
