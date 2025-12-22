import 'package:flutter/material.dart';
import 'service_flow_state.dart';

/// Notifier: Orquesta el flujo según pantallas
class ServiceFlowNotifier extends ChangeNotifier {
  ServiceFlowState _state = const ServiceFlowState();

  ServiceFlowState get state => _state;

  void setExtinguisherNew(bool isNew) {
    _state = _state.copyWith(isNewExtinguisher: isNew);
    notifyListeners();
  }

  void setExtinguisherId(String id) {
    _state = _state.copyWith(extinguisherId: id);
    notifyListeners();
  }
}

