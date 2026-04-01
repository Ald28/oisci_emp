import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../domain/repositories/extinguisher_repository.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../datasources/extinguisher_datasource.dart';
import '../datasources/http_extinguisher_datasource.dart';
import '../datasources/local_extinguisher_datasource.dart';
import '../models/extinguisher_model.dart';
import '../../../../core/database/app_database.dart';

class ExtinguisherRepositoryImpl implements ExtinguisherRepository {
  final ExtinguisherDataSource? remoteDataSource;
  final ExtinguisherDataSource? localDataSource;

  ExtinguisherRepositoryImpl({
    ExtinguisherDataSource? remoteDataSource,
    ExtinguisherDataSource? localDataSource,
  }) : remoteDataSource = remoteDataSource ?? HttpExtinguisherDataSource(),
       localDataSource = localDataSource ?? LocalExtinguisherDataSource();

  /// Obtener el datasource apropiado según la conectividad
  Future<ExtinguisherDataSource> _getDataSource({
    required bool preferLocal,
  }) async {
    if (preferLocal) {
      return localDataSource!;
    }

    final hasInternet = await InternetConnectionChecker().hasConnection;
    return hasInternet ? remoteDataSource! : localDataSource!;
  }

  @override
  Future<Extinguisher?> searchExtinguisher(
    String searchTerm, {
    int? sedeId,
  }) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    // Si hay internet, buscar primero en el servidor
    if (hasInternet) {
      final remoteDataSource = await _getDataSource(preferLocal: false);
      final extinguisher = await remoteDataSource.searchExtinguisher(
        searchTerm,
        sedeId: sedeId,
      );

      // Si se encontró en el servidor, guardarlo localmente para uso offline
      if (extinguisher != null &&
          localDataSource is LocalExtinguisherDataSource) {
        await (localDataSource as LocalExtinguisherDataSource).saveExtinguisher(
          extinguisher as ExtinguisherModel,
        );
      }

      // Si se encontró en el servidor, retornarlo
      if (extinguisher != null) {
        return extinguisher;
      }

      // Si no se encontró en el servidor, buscar también en local (puede estar pendiente de sincronización)
      if (localDataSource != null &&
          localDataSource is LocalExtinguisherDataSource) {
        final localExtinguisher =
            await (localDataSource as LocalExtinguisherDataSource)
                .searchExtinguisher(searchTerm, sedeId: sedeId);
        if (localExtinguisher != null) {
          return localExtinguisher;
        }
      }

      // No se encontró ni en servidor ni en local
      return null;
    }

    // Sin internet, buscar solo en SQLite (incluye sincronizados y pendientes)
    final dataSource = await _getDataSource(preferLocal: true);
    return await dataSource.searchExtinguisher(searchTerm, sedeId: sedeId);
  }

  @override
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data) async {
    // Determinar qué datasource usar según conectividad
    final hasInternet = await InternetConnectionChecker().hasConnection;
    final dataSource = await _getDataSource(preferLocal: !hasInternet);

    return await dataSource.createExtinguisher(data);
  }

  @override
  Future<Extinguisher?> getExtinguisherById(int extintorId) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    // Si hay internet, buscar primero en el servidor
    if (hasInternet) {
      try {
        final remoteDataSource = await _getDataSource(preferLocal: false);
        if (remoteDataSource is HttpExtinguisherDataSource) {
          final extinguisher = await remoteDataSource.getExtinguisherById(
            extintorId,
          );

          // Si se encontró en el servidor, guardarlo localmente para uso offline
          if (extinguisher != null &&
              localDataSource is LocalExtinguisherDataSource) {
            await (localDataSource as LocalExtinguisherDataSource)
                .saveExtinguisher(extinguisher);
            return extinguisher;
          }

          // Si no se encontró en el servidor (404), buscar en local
          // (puede ser un extintor creado offline que aún no se sincronizó)
        }
      } catch (e) {
        // Si falla HTTP (excepto 404), continuar con búsqueda local
        // El error se puede loggear pero no se lanza para permitir fallback
      }
    }

    // Si no hay internet o no se encontró en el servidor, buscar en local
    if (localDataSource is LocalExtinguisherDataSource) {
      // Primero intentar buscar directamente por ID
      var localExtinguisher =
          await (localDataSource as LocalExtinguisherDataSource)
              .getExtinguisherById(extintorId);

      // Si no se encuentra y el ID es negativo, buscar el extintor sincronizado
      // que corresponde a este ID negativo (el extintor puede haberse sincronizado)
      if (localExtinguisher == null && extintorId < 0) {
        // Buscar el extintor temporal para obtener serialNumberNFC o codeExtintor
        final db = await AppDatabase.database;
        final tempResult = await db.query(
          'extintor',
          where: 'id = ?',
          whereArgs: [extintorId],
          limit: 1,
        );

        if (tempResult.isNotEmpty) {
          final row = tempResult.first;
          final searchTerm =
              row['serialNumberNFC'] as String? ??
              row['codeExtintor'] as String?;
          if (searchTerm != null && searchTerm.isNotEmpty) {
            final syncedExtinguisher =
                await (localDataSource as LocalExtinguisherDataSource)
                    .searchExtinguisher(searchTerm);
            if (syncedExtinguisher != null && syncedExtinguisher.id > 0) {
              localExtinguisher = syncedExtinguisher;
            }
          }
        }
      }

      // Si se encuentra en local, retornarlo
      if (localExtinguisher != null) {
        return localExtinguisher;
      }
    }

    // No se encontró ni en servidor ni en local
    return null;
  }

  @override
  Future<List<Extinguisher>> getExtinguishersBySedeId(int sedeId) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    // Si hay internet, intentar obtener primero desde el backend
    if (hasInternet && remoteDataSource is HttpExtinguisherDataSource) {
      try {
        final remoteExtinguishers =
            await (remoteDataSource as HttpExtinguisherDataSource)
                .getExtinguishersBySedeId(sedeId);

        // Guardar/actualizar también localmente para uso offline
        if (localDataSource is LocalExtinguisherDataSource &&
            remoteExtinguishers.isNotEmpty) {
          for (final ext in remoteExtinguishers) {
            await (localDataSource as LocalExtinguisherDataSource)
                .saveExtinguisher(ext as ExtinguisherModel);
          }
        }

        return remoteExtinguishers;
      } catch (_) {
        // Si falla HTTP, continuamos con la lectura local como fallback
      }
    }

    // Sin internet o si falló el request, obtener desde la base de datos local
    if (localDataSource is LocalExtinguisherDataSource) {
      return await (localDataSource as LocalExtinguisherDataSource)
          .getExtinguishersBySedeId(sedeId);
    }

    return [];
  }

  @override
  Future<Extinguisher> updateExtinguisher(
    int extintorId,
    Map<String, dynamic> data,
  ) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    if (hasInternet) {
      try {
        // Intentar actualizar en el servidor
        final remoteDataSource = await _getDataSource(preferLocal: false);
        final updatedExtinguisher = await remoteDataSource.updateExtinguisher(
          extintorId,
          data,
        );

        // Guardar también localmente
        if (localDataSource is LocalExtinguisherDataSource) {
          await (localDataSource as LocalExtinguisherDataSource)
              .saveExtinguisher(updatedExtinguisher as ExtinguisherModel);
        }

        return updatedExtinguisher;
      } catch (e) {
        // Si falla HTTP, guardar solo localmente (con sync_queue)
        final dataSource = await _getDataSource(preferLocal: true);
        return await dataSource.updateExtinguisher(extintorId, data);
      }
    } else {
      // Sin internet, guardar solo localmente (con sync_queue)
      final dataSource = await _getDataSource(preferLocal: true);
      return await dataSource.updateExtinguisher(extintorId, data);
    }
  }

  @override
  Future<List<Extinguisher>> getExtinguishersWithoutSerialNumber({
    int? sedeId,
  }) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    if (hasInternet) {
      try {
        // Intentar obtener desde el backend
        final remoteDataSource = await _getDataSource(preferLocal: false);
        final extinguishers = await remoteDataSource
            .getExtinguishersWithoutSerialNumber(sedeId: sedeId);

        // Guardar también localmente para uso offline
        if (localDataSource is LocalExtinguisherDataSource &&
            extinguishers.isNotEmpty) {
          for (final ext in extinguishers) {
            await (localDataSource as LocalExtinguisherDataSource)
                .saveExtinguisher(ext as ExtinguisherModel);
          }
        }

        return extinguishers;
      } catch (_) {
        // Si falla HTTP, continuamos con la lectura local como fallback
      }
    }

    // Sin internet o si falló el request, obtener desde la base de datos local
    if (localDataSource is LocalExtinguisherDataSource) {
      return await (localDataSource as LocalExtinguisherDataSource)
          .getExtinguishersWithoutSerialNumber(sedeId: sedeId);
    }

    return [];
  }

  @override
  Future<List<Extinguisher>> getAllExtinguishers() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;

    if (hasInternet && remoteDataSource is HttpExtinguisherDataSource) {
      try {
        final remoteExtinguishers =
            await (remoteDataSource as HttpExtinguisherDataSource)
                .getAllExtinguishers();

        // Guardar/actualizar también localmente para uso offline
        if (localDataSource is LocalExtinguisherDataSource &&
            remoteExtinguishers.isNotEmpty) {
          for (final ext in remoteExtinguishers) {
            await (localDataSource as LocalExtinguisherDataSource)
                .saveExtinguisher(ext as ExtinguisherModel);
          }
        }

        return remoteExtinguishers;
      } catch (_) {
        // Si falla HTTP, continuamos con la lectura local como fallback
      }
    }

    // Sin internet o si falló el request, obtener desde la base de datos local
    if (localDataSource is LocalExtinguisherDataSource) {
      return await (localDataSource as LocalExtinguisherDataSource)
          .getAllExtinguishers();
    }

    return [];
  }
}
