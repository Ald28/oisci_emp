import 'package:hive/hive.dart';

part 'pending_extinguisher_model_adapter.dart';

/// Modelo: Extintor pendiente de sincronización (Data Layer)
/// Se guarda localmente cuando no hay internet
/// NO tiene ID porque el servidor lo generará al sincronizar
@HiveType(typeId: 0)
class PendingExtinguisherModel extends HiveObject {
  @HiveField(0)
  final String? codeNFC;

  @HiveField(1)
  final String? serialNumber;

  @HiveField(2)
  final String? type;

  @HiveField(3)
  final String? capacity;

  @HiveField(4)
  final String? agent;

  @HiveField(5)
  final String? cylinderNumber;

  @HiveField(6)
  final String? location;

  @HiveField(7)
  final String? status;

  @HiveField(8)
  final String? historic;

  @HiveField(9)
  final String? dateLow;

  @HiveField(10)
  final String? photo;

  @HiveField(11)
  final int sedeId;

  @HiveField(12)
  final int usuarioCreadorId;

  @HiveField(13)
  final DateTime createdAt; // Fecha de creación local

  @HiveField(14)
  String? lastSyncError; // Último error de sincronización

  @HiveField(15)
  int syncAttempts; // Número de intentos de sincronización

  @HiveField(16)
  DateTime? lastSyncAttempt; // Último intento de sincronización

  PendingExtinguisherModel({
    this.codeNFC,
    this.serialNumber,
    this.type,
    this.capacity,
    this.agent,
    this.cylinderNumber,
    this.location,
    this.status,
    this.historic,
    this.dateLow,
    this.photo,
    required this.sedeId,
    required this.usuarioCreadorId,
    required this.createdAt,
    this.lastSyncError,
    this.syncAttempts = 0,
    this.lastSyncAttempt,
  });

  /// Crear desde un Map (datos del formulario)
  factory PendingExtinguisherModel.fromMap(
    Map<String, dynamic> data,
    int usuarioCreadorId,
  ) {
    // Validar y obtener sedeId de forma segura
    final sedeIdValue = data['sedeId'];
    if (sedeIdValue == null) {
      throw Exception('sedeId es requerido para crear un extintor');
    }

    final sedeId = sedeIdValue is int
        ? sedeIdValue
        : (sedeIdValue is String ? int.tryParse(sedeIdValue) : null);

    if (sedeId == null) {
      throw Exception('sedeId debe ser un número válido');
    }

    return PendingExtinguisherModel(
      codeNFC: data['codeNFC'] as String?,
      serialNumber: data['serialNumber'] as String?,
      type: data['type'] as String?,
      capacity: data['capacity'] as String?,
      agent: data['agent'] as String?,
      cylinderNumber: data['cylinderNumber'] as String?,
      location: data['location'] as String?,
      status: data['status'] as String?,
      historic: data['historic'] as String?,
      dateLow: data['dateLow'] as String?,
      photo: data['photo'] as String?,
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
      createdAt: DateTime.now(),
      lastSyncError: null,
      syncAttempts: 0,
      lastSyncAttempt: null,
    );
  }

  /// Marcar error de sincronización
  void markSyncError(String error) {
    lastSyncError = error;
    syncAttempts++;
    lastSyncAttempt = DateTime.now();
    save(); // Guardar cambios en Hive
  }

  /// Limpiar error de sincronización
  void clearSyncError() {
    lastSyncError = null;
    save();
  }

  /// Verificar si tiene error
  bool get hasError => lastSyncError != null && lastSyncError!.isNotEmpty;

  /// Convertir a Map para enviar al servidor
  Map<String, dynamic> toMap() {
    return {
      'codeNFC': codeNFC,
      'serialNumber': serialNumber,
      'type': type,
      'capacity': capacity,
      'agent': agent,
      'cylinderNumber': cylinderNumber,
      'location': location,
      'status': status,
      'historic': historic,
      'dateLow': dateLow,
      'photo': photo,
      'sedeId': sedeId,
    };
  }
}
