import 'package:flutter/material.dart';
import 'inspection_state.dart';

/// Notifier: Estado checklist/fotos/obs/resumen inspección
class InspectionNotifier extends ChangeNotifier {
  InspectionState _state = const InspectionState();

  InspectionState get state => _state;

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

  void addPhoto(String photoPath) {
    final updated = List<String>.from(_state.photos)..add(photoPath);
    _state = _state.copyWith(photos: updated);
    notifyListeners();
  }

  void setObservations(String observations) {
    _state = _state.copyWith(observations: observations);
    notifyListeners();
  }
}

