import 'service_type.dart';
import 'service_status.dart';

/// Entidad: Orden de servicio
class ServiceOrder {
  final String id;
  final ServiceType type;
  final ServiceStatus status;
  final String extinguisherId;
  final String? extinguisherCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? observations;

  const ServiceOrder({
    required this.id,
    required this.type,
    required this.status,
    required this.extinguisherId,
    this.extinguisherCode,
    this.startDate,
    this.endDate,
    this.observations,
  });
}

