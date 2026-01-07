import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dio/dio.dart';
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/models/extinguisher_model.dart';
import '../network/dio_client.dart';
import 'dart:convert';

/// Servicio para sincronizar extintores: descargar del servidor y guardar localmente
class ExtinguisherSyncService {
  final LocalExtinguisherDataSource _localDataSource;
  final Dio _dio = DioClient().dio;

  ExtinguisherSyncService({LocalExtinguisherDataSource? localDataSource})
    : _localDataSource = localDataSource ?? LocalExtinguisherDataSource();

  /// Sincronizar extintores: descargar del servidor y guardar localmente
  /// Retorna true si se sincronizaron exitosamente, false si no hay internet
  Future<bool> syncExtinguishers() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return false;
    }

    try {
      // Obtener todos los extintores del servidor
      // El endpoint /nfc/list-nfc retorna directamente un array o un objeto con { ok: true, data: [...] }
      final response = await _dio.get('/nfc/list-nfc');
      final responseData = response.data;

      List extintoresList;

      // Manejar diferentes formatos de respuesta
      if (responseData is List) {
        // Si la respuesta es directamente un array
        extintoresList = responseData;
      } else if (responseData is Map<String, dynamic>) {
        // Si la respuesta es un objeto con formato { ok: true, data: [...] }
        if (responseData['ok'] == true && responseData['data'] != null) {
          extintoresList = responseData['data'] as List;
        } else {
          throw Exception(
            'Respuesta inválida del servidor: ${responseData['message'] ?? 'Formato de respuesta inesperado'}',
          );
        }
      } else {
        throw Exception('Formato de respuesta inesperado del servidor');
      }

      // Convertir y guardar cada extintor localmente
      final extintores = extintoresList
          .map(
            (json) => ExtinguisherModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      for (final extintor in extintores) {
        await _localDataSource.saveExtinguisher(extintor);
      }

      return true;
    } on DioException catch (e) {
      // Capturar errores de Dio y lanzar con mensaje más claro
      String errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        errorMessage =
            errorData['message'] as String? ??
            errorData['error'] as String? ??
            'Error al descargar extintores';
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data as String;
      } else {
        errorMessage =
            'Error al descargar extintores: ${e.message ?? 'Error desconocido'}';
      }

      // Si es un error 404, el endpoint no existe
      if (e.response?.statusCode == 404) {
        errorMessage =
            'Endpoint no encontrado. Verifique que el backend tenga el endpoint /nfc/list-nfc';
      }

      throw Exception(errorMessage);
    } catch (e) {
      // Relanzar otros errores con el mensaje original
      rethrow;
    }
  }

  /// Sincronizar extintores pendientes (de la cola de sincronización)
  Future<void> syncPendingExtinguishers() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) {
      return;
    }

    final pending = await _localDataSource.getPendingExtinguishers();

    for (final item in pending) {
      try {
        final data =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        // Intentar crear el extintor en el servidor
        final response = await _dio.post('/nfc/create-extintor', data: data);
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['ok'] == true && responseData['data'] != null) {
          // Guardar el extintor sincronizado localmente
          final extintor = ExtinguisherModel.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );

          // Buscar el extintor temporal en extintor por codeNFC o serialNumber
          // para actualizarlo con el ID real del servidor
          final codeNFC = data['codeNFC'] as String?;
          final serialNumber = data['serialNumber'] as String?;

          if (codeNFC != null || serialNumber != null) {
            // Actualizar el registro existente en extintor con el ID real y synced = 1
            await _localDataSource.updateExtinguisherAfterSync(
              codeNFC: codeNFC,
              serialNumber: serialNumber,
              extinguisher: extintor,
            );
          } else {
            // Si no hay codeNFC ni serialNumber, insertar nuevo (caso raro)
            await _localDataSource.saveExtinguisher(extintor);
          }

          // Eliminar de la cola
          await _localDataSource.deleteQueueItem(item['id'] as int);
        } else {
          // Error al sincronizar
          await _localDataSource.updateSyncError(
            item['id'] as int,
            responseData['message'] as String? ?? 'Error desconocido',
          );
        }
      } catch (e) {
        // Error al sincronizar
        await _localDataSource.updateSyncError(item['id'] as int, e.toString());
      }
    }
  }
}
