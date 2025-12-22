/// DTO: Request para finalizar servicio (JSON)
class ServiceCloseRequestDto {
  final String serviceId;
  final List<String> completedItems; // CH1, CH2, etc.
  final String? observations;

  const ServiceCloseRequestDto({
    required this.serviceId,
    required this.completedItems,
    this.observations,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'completedItems': completedItems,
      'observations': observations,
    };
  }
}

