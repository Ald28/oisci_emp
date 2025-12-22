/// DTO: Orden de servicio (JSON)
class ServiceOrderDto {
  final String id;
  final String type; // 'maintenance' | 'inspection'
  final String status; // 'draft' | 'inProgress' | 'finished'
  final String extinguisherId;
  final String? extinguisherCode;
  final String? startDate;
  final String? endDate;
  final String? observations;

  const ServiceOrderDto({
    required this.id,
    required this.type,
    required this.status,
    required this.extinguisherId,
    this.extinguisherCode,
    this.startDate,
    this.endDate,
    this.observations,
  });

  factory ServiceOrderDto.fromJson(Map<String, dynamic> json) {
    return ServiceOrderDto(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      extinguisherId: json['extinguisherId'] as String,
      extinguisherCode: json['extinguisherCode'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      observations: json['observations'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'extinguisherId': extinguisherId,
      'extinguisherCode': extinguisherCode,
      'startDate': startDate,
      'endDate': endDate,
      'observations': observations,
    };
  }
}

