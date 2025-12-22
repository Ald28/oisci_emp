import 'package:flutter/material.dart';
import 'maintenance_state.dart';

/// Notifier: Estado checklist/inputs/obs/resumen mantenimiento
class MaintenanceNotifier extends ChangeNotifier {
  MaintenanceState _state = const MaintenanceState();

  MaintenanceState get state => _state;

  void setServiceId(String serviceId) {
    _state = _state.copyWith(serviceId: serviceId);
    notifyListeners();
  }

  void toggleChecklistItem(String itemId) {
    final current = _state.checklistItems[itemId] ?? false;
    final updated = Map<String, bool>.from(_state.checklistItems);
    updated[itemId] = !current;
    _state = _state.copyWith(checklistItems: updated);
    notifyListeners();
  }

  void setObservations(String observations) {
    _state = _state.copyWith(observations: observations);
    notifyListeners();
  }
}

