import '../../domain/entities/extinguisher_stats_entity.dart';

/// Modelo: Estadísticas de Extintores (Data Layer)
/// Solo se usa para parsear JSON del backend, no se guarda en SQLite
class ExtinguisherStatsModel extends ExtinguisherStatsEntity {
  const ExtinguisherStatsModel({
    required super.sedeId,
    required super.byType,
    required super.total,
    required super.operativos,
    required super.inoperativos,
  });

  /// Parsear desde JSON del backend
  factory ExtinguisherStatsModel.fromJson(Map<String, dynamic> json) {
    // Convertir el objeto byType a Map<String, int>
    final byTypeMap = <String, int>{};
    if (json['byType'] != null && json['byType'] is Map) {
      (json['byType'] as Map).forEach((key, value) {
        byTypeMap[key.toString()] = value is int
            ? value
            : (value as num).toInt();
      });
    }

    return ExtinguisherStatsModel(
      sedeId: json['sedeId'] as int,
      byType: byTypeMap,
      total: json['total'] as int? ?? 0,
      operativos: json['operativos'] as int? ?? 0,
      inoperativos: json['inoperativos'] as int? ?? 0,
    );
  }
}
