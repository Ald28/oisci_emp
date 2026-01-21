import '../../domain/entities/service_stats_entity.dart';

/// Modelo: Estadísticas de Servicios (Data Layer)
/// Solo se usa para parsear JSON del backend, no se guarda en SQLite
class ServiceStatsModel extends ServiceStatsEntity {
  const ServiceStatsModel({
    required super.sedeId,
    required super.year,
    required super.byType,
  });

  /// Parsear desde JSON del backend
  factory ServiceStatsModel.fromJson(Map<String, dynamic> json) {
    // Convertir el objeto byType a Map<String, int>
    final byTypeMap = <String, int>{};
    if (json['byType'] != null && json['byType'] is Map) {
      (json['byType'] as Map).forEach((key, value) {
        byTypeMap[key.toString()] = value is int
            ? value
            : (value as num).toInt();
      });
    }

    return ServiceStatsModel(
      sedeId: json['sedeId'] as int,
      year: json['year'] as int,
      byType: byTypeMap,
    );
  }
}
