import 'dart:io';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../features/services/data/datasources/local_extinguisher_datasource.dart';
import '../../features/services/data/models/extinguisher_model.dart';
import '../network/dio_client.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        // Si el extintor tiene una foto URL, descargarla y guardar el path local
        if (extintor.photo != null && extintor.photo!.isNotEmpty) {
          try {
            final photoPath = await _downloadPhoto(
              extintor.id,
              extintor.photo!,
            );
            if (photoPath != null) {
              // Crear un nuevo modelo con el photoPath actualizado
              final extintorWithPath = ExtinguisherModel(
                id: extintor.id,
                serialNumber: extintor.serialNumber,
                type: extintor.type,
                capacity: extintor.capacity,
                agent: extintor.agent,
                cylinderNumber: extintor.cylinderNumber,
                location: extintor.location,
                status: extintor.status,
                photo: extintor.photo,
                photoPath: photoPath,
                pressure: extintor.pressure,
                brand: extintor.brand,
                model: extintor.model,
                rating: extintor.rating,
                yearManufacture: extintor.yearManufacture,
                dateHydrostatic: extintor.dateHydrostatic,
                dateMaintenance: extintor.dateMaintenance,
                createdAt: extintor.createdAt,
                updatedAt: extintor.updatedAt,
                sedeId: extintor.sedeId,
                usuarioCreadorId: extintor.usuarioCreadorId,
                sedeName: extintor.sedeName,
              );
              await _localDataSource.saveExtinguisher(extintorWithPath);
            } else {
              // Si falla la descarga, guardar sin photoPath
              await _localDataSource.saveExtinguisher(extintor);
            }
          } catch (e) {
            // Si hay error al descargar, guardar sin photoPath
            // No queremos que falle toda la sincronización por una imagen
            await _localDataSource.saveExtinguisher(extintor);
          }
        } else {
          // Si no hay foto, guardar normalmente
          await _localDataSource.saveExtinguisher(extintor);
        }
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
          var extintor = ExtinguisherModel.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );

          // Si el extintor tiene una foto URL, descargarla y guardar el path local
          if (extintor.photo != null && extintor.photo!.isNotEmpty) {
            try {
              final photoPath = await _downloadPhoto(
                extintor.id,
                extintor.photo!,
              );
              if (photoPath != null) {
                // Crear un nuevo modelo con el photoPath actualizado
                extintor = ExtinguisherModel(
                  id: extintor.id,
                  serialNumber: extintor.serialNumber,
                  type: extintor.type,
                  capacity: extintor.capacity,
                  agent: extintor.agent,
                  cylinderNumber: extintor.cylinderNumber,
                  location: extintor.location,
                  status: extintor.status,
                  photo: extintor.photo,
                  photoPath: photoPath,
                  pressure: extintor.pressure,
                  brand: extintor.brand,
                  model: extintor.model,
                  rating: extintor.rating,
                  yearManufacture: extintor.yearManufacture,
                  dateHydrostatic: extintor.dateHydrostatic,
                  dateMaintenance: extintor.dateMaintenance,
                  createdAt: extintor.createdAt,
                  updatedAt: extintor.updatedAt,
                  sedeId: extintor.sedeId,
                  usuarioCreadorId: extintor.usuarioCreadorId,
                  sedeName: extintor.sedeName,
                );
              }
            } catch (e) {
              // Si hay error al descargar, continuar sin photoPath
              // No queremos que falle toda la sincronización por una imagen
            }
          }

          // Buscar el extintor temporal en extintor por serialNumber o tempId
          // para actualizarlo con el ID real del servidor
          final serialNumber = data['serialNumber'] as String?;
          final tempId = data['tempId'] as int?;

          if (serialNumber != null || tempId != null) {
            // Actualizar el registro existente en extintor con el ID real y synced = 1
            await _localDataSource.updateExtinguisherAfterSync(
              serialNumber: serialNumber,
              tempId: tempId,
              extinguisher: extintor,
            );
          } else {
            // Si no hay forma directa de identificar el extintor temporal,
            // usar la búsqueda heurística basada en otros campos y relaciones.
            await _localDataSource
                .updateExtinguisherAfterSyncWithoutSerialNumber(
              extinguisher: extintor,
              originalData:
                  data, // Datos originales del payload para buscar el tempId
            );
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

  /// Descargar foto de un extintor desde la URL y guardarla localmente
  /// Retorna el path local de la imagen descargada, o null si falla
  /// Si ya existe un archivo para este extintor, lo reemplaza con la nueva versión
  Future<String?> _downloadPhoto(int extintorId, String photoUrl) async {
    try {
      // Construir URL completa si es relativa
      String fullUrl = photoUrl;
      if (!photoUrl.startsWith('http://') && !photoUrl.startsWith('https://')) {
        final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
        final cleanUrl = photoUrl.startsWith('/')
            ? photoUrl.substring(1)
            : photoUrl;
        fullUrl = '$baseUrl/$cleanUrl';
      }

      // Obtener directorio de documentos de la app
      final appDir = await getApplicationDocumentsDirectory();
      final extintoresDir = Directory(path.join(appDir.path, 'extintores'));
      if (!await extintoresDir.exists()) {
        await extintoresDir.create(recursive: true);
      }

      // Buscar si ya existe un archivo para este extintor
      // Usar un patrón de nombre consistente: extintor_{id}.jpg
      final fileName = 'extintor_$extintorId.jpg';
      final filePath = path.join(extintoresDir.path, fileName);

      // Si ya existe el archivo, eliminarlo para reemplazarlo con la nueva versión
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Descargar la imagen
      final response = await _dio.get(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Guardar el archivo
        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);
        return filePath;
      } else {
        // Si la descarga falla, retornar null
        return null;
      }
    } catch (e) {
      // Si hay cualquier error, retornar null
      // No queremos que falle toda la sincronización por una imagen
      return null;
    }
  }
}
