import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/datasources/http_extinguisher_datasource.dart';
import '../../features/services/data/models/pending_extinguisher_model.dart';

/// Servicio de sincronización para enviar extintores pendientes al servidor
class SyncService {
  final LocalExtinguisherDataSource _localDataSource;
  final HttpExtinguisherDataSource _httpDataSource;

  SyncService({
    LocalExtinguisherDataSource? localDataSource,
    HttpExtinguisherDataSource? httpDataSource,
  }) : _localDataSource = localDataSource ?? LocalExtinguisherDataSource(),
       _httpDataSource = httpDataSource ?? HttpExtinguisherDataSource();

  /// Sincronizar todos los extintores pendientes
  /// Retorna el número de extintores sincronizados exitosamente
  Future<int> syncPendingExtinguishers() async {
    // Verificar conexión a internet
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return 0; // No hay internet, no se puede sincronizar
    }

    // Obtener todos los extintores pendientes
    final pendingExtinguishers = await _localDataSource
        .getPendingExtinguishers();

    if (pendingExtinguishers.isEmpty) {
      return 0; // No hay extintores pendientes
    }

    int syncedCount = 0;

    // Intentar sincronizar cada extintor pendiente
    for (final pendingExtinguisher in pendingExtinguishers) {
      try {
        // Convertir a Map para enviar al servidor
        final data = pendingExtinguisher.toMap();

        // Intentar crear en el servidor
        await _httpDataSource.createExtinguisher(data);

        // Si se creó exitosamente, eliminar de pendientes
        await _localDataSource.deletePendingExtinguisher(pendingExtinguisher);
        syncedCount++;
      } catch (e) {
        // Si falla, guardar el error en el modelo
        final errorMessage = e.toString();
        pendingExtinguisher.markSyncError(errorMessage);
        continue;
      }
    }

    return syncedCount;
  }

  /// Obtener la cantidad de extintores pendientes
  Future<int> getPendingCount() async {
    return await _localDataSource.getPendingCount();
  }

  /// Verificar si hay extintores pendientes
  Future<bool> hasPendingExtinguishers() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Sincronizar un extintor individual
  Future<bool> syncSingleExtinguisher(
    PendingExtinguisherModel extinguisher,
  ) async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      extinguisher.markSyncError('No hay conexión a internet');
      return false;
    }

    try {
      final data = extinguisher.toMap();
      await _httpDataSource.createExtinguisher(data);
      await _localDataSource.deletePendingExtinguisher(extinguisher);
      return true;
    } catch (e) {
      extinguisher.markSyncError(e.toString());
      return false;
    }
  }

  /// Obtener todos los extintores pendientes
  Future<List<PendingExtinguisherModel>> getPendingExtinguishers() async {
    try {
      final pending = await _localDataSource.getPendingExtinguishers();
      // Filtrar cualquier registro inválido que pueda tener campos null
      return pending.where((extinguisher) {
        try {
          // Validar que tenga los campos requeridos
          return extinguisher.sedeId > 0 && extinguisher.usuarioCreadorId > 0;
        } catch (e) {
          // Si hay error al validar, excluir este registro
          return false;
        }
      }).toList();
    } catch (e) {
      // Si hay error al cargar, retornar lista vacía en lugar de lanzar excepción
      return [];
    }
  }
}
