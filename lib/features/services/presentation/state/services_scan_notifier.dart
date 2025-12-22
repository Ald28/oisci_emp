import 'package:flutter/material.dart';
import 'services_scan_state.dart';

/// Notifier: Lógica de búsqueda de extintor
class ServicesScanNotifier extends ChangeNotifier {
  ServicesScanState _state = const ServicesScanState();

  ServicesScanState get state => _state;

  Future<void> scanNfc() async {
    _state = _state.copyWith(isScanning: true);
    notifyListeners();
    // TODO: Implementar escaneo NFC
  }

  Future<void> searchByCode(String code) async {
    _state = _state.copyWith(isScanning: true);
    notifyListeners();
    // TODO: Implementar búsqueda por código
  }
}

