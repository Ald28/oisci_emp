import 'dart:async';

/// Controlador global para el progreso de sincronización automática
/// Permite que cualquier parte de la app escuche el progreso
class SyncProgressController {
  static final SyncProgressController _instance =
      SyncProgressController._internal();
  factory SyncProgressController() => _instance;
  SyncProgressController._internal();

  final _progressController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream público para escuchar el progreso
  Stream<Map<String, dynamic>> get progressStream => _progressController.stream;

  /// Emitir progreso
  void emitProgress(Map<String, dynamic> progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  /// Cerrar el stream (solo para limpieza)
  void dispose() {
    _progressController.close();
  }
}
