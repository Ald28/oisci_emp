/// Estado del mantenimiento
class MaintenanceState {
  final String? serviceId;
  final Map<String, bool> checklistItems; // itemId -> completed
  final String? observations;

  const MaintenanceState({
    this.serviceId,
    this.checklistItems = const {},
    this.observations,
  });

  MaintenanceState copyWith({
    String? serviceId,
    Map<String, bool>? checklistItems,
    String? observations,
  }) {
    return MaintenanceState(
      serviceId: serviceId ?? this.serviceId,
      checklistItems: checklistItems ?? this.checklistItems,
      observations: observations ?? this.observations,
    );
  }
}

