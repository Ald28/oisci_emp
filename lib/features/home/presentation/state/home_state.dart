/// Estado del módulo Home
class HomeState {
  final int selectedTabIndex;
  final String currentTitle;
  final bool isDrawerOpen;

  const HomeState({
    this.selectedTabIndex = 0,
    this.currentTitle = 'Inicio',
    this.isDrawerOpen = false,
  });

  HomeState copyWith({
    int? selectedTabIndex,
    String? currentTitle,
    bool? isDrawerOpen,
  }) {
    return HomeState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      currentTitle: currentTitle ?? this.currentTitle,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
    );
  }
}


