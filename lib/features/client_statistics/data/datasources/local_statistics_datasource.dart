import '../../../../core/database/app_database.dart';
import '../models/extinguisher_stats_model.dart';
import '../models/service_stats_model.dart';

/// DataSource local: Calcula estadísticas desde las tablas existentes en SQLite
/// Usa la misma lógica que el backend para mantener consistencia
class LocalStatisticsDataSource {
  LocalStatisticsDataSource();

  /// Calcular estadísticas de extintores desde SQLite
  /// Usa la misma lógica que el backend
  Future<ExtinguisherStatsModel> calculateExtinguisherStatsBySedeId(
    int sedeId,
  ) async {
    final db = await AppDatabase.database;

    // Obtener todos los extintores de la sede
    final results = await db.query(
      'extintor',
      where: 'sedeId = ?',
      whereArgs: [sedeId],
      columns: ['type', 'agent', 'status'],
    );

    final byType = <String, int>{};
    int total = 0;
    int operativos = 0;
    int inoperativos = 0;

    for (final row in results) {
      total++;

      final status = row['status'] as String?;
      if (status == 'OPERATIVO') {
        operativos++;
      } else if (status == 'INOPERATIVO') {
        inoperativos++;
      }

      // Construir la clave igual que el backend: "type agent" o solo "type"
      final type = row['type'] as String?;
      final agent = row['agent'] as String?;
      final key = agent != null && agent.isNotEmpty
          ? '$type $agent'
          : (type ?? 'SIN_TIPO');

      byType[key] = (byType[key] ?? 0) + 1;
    }

    return ExtinguisherStatsModel(
      sedeId: sedeId,
      byType: byType,
      total: total,
      operativos: operativos,
      inoperativos: inoperativos,
    );
  }

  /// Calcular estadísticas de servicios desde SQLite
  /// Usa la misma lógica que el backend
  Future<ServiceStatsModel> calculateServiceStatsBySedeIdAndYear(
    int sedeId,
    int year,
  ) async {
    final db = await AppDatabase.database;

    // Calcular rango de fechas para el año
    final startDate = DateTime(year, 1, 1).toIso8601String();
    final endDate = DateTime(year, 12, 31, 23, 59, 59).toIso8601String();

    // Obtener servicios del año
    final servicios = await db.query(
      'servicio',
      where: 'sedeId = ? AND dateStart >= ? AND dateStart <= ?',
      whereArgs: [sedeId, startDate, endDate],
    );

    int mantenimiento = 0;
    int recarga = 0;
    int pruebaHidrostatica = 0;
    int baja = 0;

    for (final servicio in servicios) {
      final serviceType = servicio['type'] as String?;

      if (serviceType == 'MANTENIMIENTO') {
        mantenimiento++;
      }

      // Obtener servicioExtintores de este servicio
      final servicioId = servicio['id'] as int;
      final servicioExtintores = await db.query(
        'servicio_extintor',
        where: 'servicioId = ?',
        whereArgs: [servicioId],
      );

      for (final se in servicioExtintores) {
        final seId = se['id'] as int;

        // Obtener mantenimiento_detalle si existe
        final mdResults = await db.query(
          'mantenimiento_detalle',
          where: 'servicioExtintorId = ?',
          whereArgs: [seId],
          limit: 1,
        );

        if (mdResults.isNotEmpty) {
          final md = mdResults.first;

          // Verificar recarga
          if ((md['recarga'] as int? ?? 0) == 1) {
            recarga++;
          }

          // Verificar prueba hidrostática
          if ((md['pruebaHidrostatica'] as int? ?? 0) == 1) {
            pruebaHidrostatica++;
          }

          // Verificar baja (desde mantenimiento_detalle o estadoFinal)
          // El backend usa OR, así que solo contamos una vez
          final estadoFinal = se['estadoFinal'] as String?;
          if ((md['bajaExtintor'] as int? ?? 0) == 1 ||
              estadoFinal == 'INOPERATIVO') {
            baja++;
          }
        } else {
          // Si no hay mantenimiento_detalle, verificar solo estadoFinal
          final estadoFinal = se['estadoFinal'] as String?;
          if (estadoFinal == 'INOPERATIVO') {
            baja++;
          }
        }
      }
    }

    return ServiceStatsModel(
      sedeId: sedeId,
      year: year,
      byType: {
        'MANTENIMIENTO': mantenimiento,
        'RECARGA': recarga,
        'PRUEBA HIDROSTÁTICA': pruebaHidrostatica,
        'BAJA': baja,
      },
    );
  }
}
