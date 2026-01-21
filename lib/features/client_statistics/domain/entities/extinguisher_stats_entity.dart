/// Entidad: Estadísticas de Extintores por Sede (Domain Layer)
class ExtinguisherStatsEntity {
  final int sedeId;
  final Map<String, int> byType; // Ej: {"Agua Agua": 5, "CO2 CO2": 3}
  final int total;
  final int operativos;
  final int inoperativos;

  const ExtinguisherStatsEntity({
    required this.sedeId,
    required this.byType,
    required this.total,
    required this.operativos,
    required this.inoperativos,
  });
}
