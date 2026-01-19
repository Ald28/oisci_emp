import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../models/client_model.dart';
import '../../../services/data/models/sede_model.dart';
import 'client_datasource.dart';

/// DataSource local usando SQLite para almacenar clientes
class LocalClientDataSource implements ClientDataSource {
  @override
  Future<Map<String, dynamic>> searchClients({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final db = await AppDatabase.database;

    // Construir la consulta WHERE
    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.trim().isNotEmpty) {
      whereClause = 'active = ? AND (ruc LIKE ? OR razonSocial LIKE ?)';
      final searchPattern = '%${search.trim()}%';
      whereArgs = [1, searchPattern, searchPattern];
    } else {
      whereClause = 'active = ?';
      whereArgs = [1];
    }

    // Calcular offset para paginación
    final offset = (page - 1) * pageSize;

    // Obtener total de registros
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM client WHERE $whereClause',
      whereArgs,
    );
    final total = countResult.first['count'] as int;

    // Obtener clientes con paginación
    final result = await db.query(
      'client',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'razonSocial ASC',
      limit: pageSize,
      offset: offset,
    );

    // Obtener clientes y cargar sus sedes
    final clients = <ClientModel>[];
    for (final map in result) {
      final client = ClientModel.fromMap(map);

      // Obtener las sedes del cliente desde la tabla sede
      final sedesResult = await db.query(
        'sede',
        where: 'clientId = ? AND active = ?',
        whereArgs: [client.id, 1],
        orderBy: 'name_sede ASC',
      );

      final sedes = sedesResult
          .map((sedeMap) => SedeModel.fromMap(sedeMap))
          .toList();

      // Crear un nuevo ClientModel con las sedes
      final clientWithSedes = ClientModel(
        id: client.id,
        clientCode: client.clientCode,
        razonSocial: client.razonSocial,
        ruc: client.ruc,
        phone: client.phone,
        address: client.address,
        userId: client.userId,
        active: client.active,
        createdAt: client.createdAt,
        updatedAt: client.updatedAt,
        sedes: sedes.isNotEmpty ? sedes : null,
      );

      clients.add(clientWithSedes);
    }

    return {
      'data': clients,
      'pagination': {
        'page': page,
        'pageSize': pageSize,
        'total': total,
        'totalPages': (total / pageSize).ceil(),
      },
    };
  }

  /// Guardar clientes localmente (desde el servidor)
  /// Si replaceAll es true, borra todos los clientes antes de guardar (sincronización completa)
  /// Si replaceAll es false, solo actualiza/inserta los clientes proporcionados (merge)
  ///
  /// NOTA: Las sedes NO se guardan aquí porque ya están sincronizadas por separado
  /// en SedeSyncService y se guardan en la tabla 'sede' con su clientId.
  /// Las sedes se relacionan con los clientes al recuperarlos usando clientId.
  Future<void> saveClients(
    List<ClientModel> clients, {
    bool replaceAll = false,
  }) async {
    final db = await AppDatabase.database;

    // Iniciar transacción para mejor rendimiento
    await db.transaction((txn) async {
      // Si es sincronización completa, limpiar solo los clientes existentes
      // NO eliminamos las sedes porque se manejan por separado en SedeSyncService
      if (replaceAll) {
        await txn.delete('client');
      }

      // Guardar solo los clientes (sin sus sedes)
      // Las sedes ya están en la tabla 'sede' sincronizadas por SedeSyncService
      for (final client in clients) {
        await txn.insert(
          'client',
          client.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Obtener todos los clientes guardados localmente
  Future<List<ClientModel>> getAllClients() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'client',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'razonSocial ASC',
    );

    // Obtener clientes y cargar sus sedes
    final clients = <ClientModel>[];
    for (final map in result) {
      final client = ClientModel.fromMap(map);

      // Obtener las sedes del cliente desde la tabla sede
      final sedesResult = await db.query(
        'sede',
        where: 'clientId = ? AND active = ?',
        whereArgs: [client.id, 1],
        orderBy: 'name_sede ASC',
      );

      final sedes = sedesResult
          .map((sedeMap) => SedeModel.fromMap(sedeMap))
          .toList();

      // Crear un nuevo ClientModel con las sedes
      final clientWithSedes = ClientModel(
        id: client.id,
        clientCode: client.clientCode,
        razonSocial: client.razonSocial,
        ruc: client.ruc,
        phone: client.phone,
        address: client.address,
        userId: client.userId,
        active: client.active,
        createdAt: client.createdAt,
        updatedAt: client.updatedAt,
        sedes: sedes.isNotEmpty ? sedes : null,
      );

      clients.add(clientWithSedes);
    }

    return clients;
  }

  /// Verificar si hay clientes guardados localmente
  Future<bool> hasClients() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM client');
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Obtener cantidad de clientes guardados
  Future<int> getClientsCount() async {
    final db = await AppDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM client');
    return result.first['count'] as int;
  }
}
