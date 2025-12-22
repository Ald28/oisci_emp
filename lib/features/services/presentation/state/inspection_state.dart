/// Estado de la inspección
class InspectionState {
  final String? serviceId;
  final Map<String, bool> checklistItems; // itemId -> completed
  final List<String> photos; // URLs o paths
  final String? observations;

  const InspectionState({
    this.serviceId,
    this.checklistItems = const {},
    this.photos = const [],
    this.observations,
  });

  InspectionState copyWith({
    String? serviceId,
    Map<String, bool>? checklistItems,
    List<String>? photos,
    String? observations,
  }) {
    return InspectionState(
      serviceId: serviceId ?? this.serviceId,
      checklistItems: checklistItems ?? this.checklistItems,
      photos: photos ?? this.photos,
      observations: observations ?? this.observations,
    );
  }
}

