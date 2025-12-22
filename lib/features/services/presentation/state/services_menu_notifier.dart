import 'package:flutter/material.dart';
import 'services_menu_state.dart';

/// Notifier: Estado/acciones del menú de servicios
class ServicesMenuNotifier extends ChangeNotifier {
  ServicesMenuState _state = const ServicesMenuState();

  ServicesMenuState get state => _state;

  void setLoading(bool isLoading) {
    _state = _state.copyWith(isLoading: isLoading);
    notifyListeners();
  }
}

