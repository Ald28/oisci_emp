import 'package:flutter/material.dart';
import 'home_state.dart';

/// Notifier para manejar el estado del Home
class HomeNotifier extends ChangeNotifier {
  HomeState _state = const HomeState();

  HomeState get state => _state;

  /// Cambiar el tab seleccionado
  void setSelectedTab(int index, String title) {
    _state = _state.copyWith(
      selectedTabIndex: index,
      currentTitle: title,
    );
    notifyListeners();
  }

  /// Cambiar el título actual
  void setTitle(String title) {
    _state = _state.copyWith(currentTitle: title);
    notifyListeners();
  }

  /// Toggle del drawer
  void toggleDrawer(bool isOpen) {
    _state = _state.copyWith(isDrawerOpen: isOpen);
    notifyListeners();
  }

  /// Resetear al estado inicial
  void reset() {
    _state = const HomeState();
    notifyListeners();
  }
}


