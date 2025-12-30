import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/auth/auth_service.dart';
import '../../domain/entities/extinguisher.dart';
import '../models/extinguisher_model.dart';
import '../models/pending_extinguisher_model.dart';
import 'extinguisher_datasource.dart';

/// DataSource local usando Hive para almacenar extintores pendientes
class LocalExtinguisherDataSource implements ExtinguisherDataSource {
  static const String _boxName = 'pending_extinguishers';

  /// Obtener la caja de Hive
  Future<Box<PendingExtinguisherModel>> _getBox() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        return await Hive.openBox<PendingExtinguisherModel>(_boxName);
      }
      return Hive.box<PendingExtinguisherModel>(_boxName);
    } catch (e) {
      // Si hay error al abrir (datos corruptos), intentar eliminar y recrear
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {
        // Ignorar errores al eliminar
      }
      return await Hive.openBox<PendingExtinguisherModel>(_boxName);
    }
  }

  @override
  Future<Extinguisher?> searchExtinguisher(String searchTerm) async {
    // La búsqueda local no está implementada porque los extintores pendientes
    // aún no existen en el servidor, por lo que no se pueden buscar
    // Esta funcionalidad solo funciona con el servidor
    return null;
  }

  @override
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data) async {
    try {
      final box = await _getBox();

      // Validar que sedeId esté presente y sea válido
      final sedeIdValue = data['sedeId'];
      if (sedeIdValue == null) {
        throw Exception('sedeId es requerido para registrar un extintor');
      }

      int sedeId;
      if (sedeIdValue is int) {
        sedeId = sedeIdValue;
      } else if (sedeIdValue is String) {
        sedeId = int.tryParse(sedeIdValue) ?? 0;
        if (sedeId == 0) {
          throw Exception('sedeId debe ser un número válido');
        }
      } else {
        throw Exception('sedeId debe ser un número válido');
      }

      // Obtener usuarioCreadorId de la sesión guardada
      final session = await AuthService.loadSession();
      final userIdStr = session['userId'] as String?;

      if (userIdStr == null || userIdStr.isEmpty) {
        throw Exception(
          'No se encontró el ID del usuario en la sesión. Por favor, inicia sesión nuevamente.',
        );
      }

      int usuarioCreadorId;
      try {
        usuarioCreadorId = int.parse(userIdStr);
        if (usuarioCreadorId <= 0) {
          throw Exception('ID de usuario inválido');
        }
      } catch (e) {
        throw Exception(
          'El ID del usuario no es válido. Por favor, inicia sesión nuevamente.',
        );
      }

      // Crear modelo pendiente
      final pendingExtinguisher = PendingExtinguisherModel.fromMap(
        data,
        usuarioCreadorId,
      );

      // Guardar en Hive
      await box.add(pendingExtinguisher);

      // Retornar un Extinguisher temporal con ID 0 (indicando que es pendiente)
      // Esto permite que el flujo de la UI continúe normalmente
      return ExtinguisherModel(
        id: 0, // ID temporal, será reemplazado cuando se sincronice
        codeNFC: pendingExtinguisher.codeNFC,
        serialNumber: pendingExtinguisher.serialNumber,
        type: pendingExtinguisher.type,
        capacity: pendingExtinguisher.capacity,
        agent: pendingExtinguisher.agent,
        cylinderNumber: pendingExtinguisher.cylinderNumber,
        location: pendingExtinguisher.location,
        status: pendingExtinguisher.status,
        historic: pendingExtinguisher.historic,
        dateLow: pendingExtinguisher.dateLow,
        photo: pendingExtinguisher.photo,
        sedeId: pendingExtinguisher.sedeId,
        usuarioCreadorId: pendingExtinguisher.usuarioCreadorId,
        createdAt: pendingExtinguisher.createdAt,
      );
    } catch (e) {
      // Si el error es sobre datos corruptos, limpiar la caja
      if (e.toString().contains('corrupt') ||
          e.toString().contains('Null') ||
          e.toString().contains('type cast')) {
        try {
          await Hive.deleteBoxFromDisk(_boxName);
        } catch (_) {
          // Ignorar errores al limpiar
        }
        throw Exception(
          'Error al guardar: Los datos locales están corruptos y han sido limpiados. '
          'Por favor, intenta registrar nuevamente.',
        );
      }
      // Re-lanzar otros errores
      rethrow;
    }
  }

  /// Obtener todos los extintores pendientes
  Future<List<PendingExtinguisherModel>> getPendingExtinguishers() async {
    try {
      final box = await _getBox();
      final allValues = box.values.toList();

      // Filtrar registros inválidos que puedan tener campos null
      final validExtinguishers = <PendingExtinguisherModel>[];

      for (final extinguisher in allValues) {
        try {
          // Validar que tenga los campos requeridos
          if (extinguisher.sedeId > 0 && extinguisher.usuarioCreadorId > 0) {
            validExtinguishers.add(extinguisher);
          } else {
            // Eliminar registro inválido
            await extinguisher.delete();
          }
        } catch (e) {
          // Si hay error al validar, eliminar el registro corrupto
          try {
            await extinguisher.delete();
          } catch (_) {
            // Ignorar errores al eliminar
          }
        }
      }

      return validExtinguishers;
    } catch (e) {
      // Si hay error al abrir la caja o leer datos, puede ser por datos corruptos
      // Intentar limpiar la caja
      try {
        final box = await _getBox();
        await box.clear();
      } catch (_) {
        // Ignorar errores al limpiar
      }
      return [];
    }
  }

  /// Eliminar un extintor pendiente (después de sincronizarlo)
  Future<void> deletePendingExtinguisher(
    PendingExtinguisherModel extinguisher,
  ) async {
    await extinguisher.delete();
  }

  /// Obtener la cantidad de extintores pendientes
  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }
}
