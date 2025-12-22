/// Estado del menú de servicios
class ServicesMenuState {
  final bool isLoading;

  const ServicesMenuState({
    this.isLoading = false,
  });

  ServicesMenuState copyWith({
    bool? isLoading,
  }) {
    return ServicesMenuState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

