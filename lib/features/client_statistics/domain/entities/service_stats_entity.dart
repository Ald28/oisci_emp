/// Entidad: Estadísticas de Servicios por Sede y Año (Domain Layer)
class ServiceStatsEntity {
  final int sedeId;
  final int year;
  final Map<String, int> byType; // Ej: {"MANTENIMIENTO": 5, "RECARGA": 3}

  const ServiceStatsEntity({
    required this.sedeId,
    required this.year,
    required this.byType,
  });
}
