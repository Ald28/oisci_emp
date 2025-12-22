/// Estado del flujo de servicio
class ServiceFlowState {
  final bool isNewExtinguisher;
  final String? extinguisherId;

  const ServiceFlowState({
    this.isNewExtinguisher = false,
    this.extinguisherId,
  });

  ServiceFlowState copyWith({
    bool? isNewExtinguisher,
    String? extinguisherId,
  }) {
    return ServiceFlowState(
      isNewExtinguisher: isNewExtinguisher ?? this.isNewExtinguisher,
      extinguisherId: extinguisherId ?? this.extinguisherId,
    );
  }
}

