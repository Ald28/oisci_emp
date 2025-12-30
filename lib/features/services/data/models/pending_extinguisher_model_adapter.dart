part of 'pending_extinguisher_model.dart';

/// Adapter personalizado que maneja valores null y migración de datos antiguos
class PendingExtinguisherModelAdapter
    extends TypeAdapter<PendingExtinguisherModel> {
  @override
  final int typeId = 0;

  @override
  PendingExtinguisherModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{
        for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
      };

      // Manejar campos requeridos de forma segura
      final sedeIdValue = fields[11];
      final usuarioCreadorIdValue = fields[12];
      final createdAtValue = fields[13];
      final syncAttemptsValue = fields[15];

      // Validar sedeId
      int sedeId;
      if (sedeIdValue == null) {
        throw Exception('sedeId es null en datos almacenados');
      } else if (sedeIdValue is int) {
        sedeId = sedeIdValue;
      } else if (sedeIdValue is String) {
        sedeId = int.tryParse(sedeIdValue) ?? 0;
      } else {
        throw Exception(
          'sedeId tiene un tipo inválido: ${sedeIdValue.runtimeType}',
        );
      }

      // Validar usuarioCreadorId
      int usuarioCreadorId;
      if (usuarioCreadorIdValue == null) {
        throw Exception('usuarioCreadorId es null en datos almacenados');
      } else if (usuarioCreadorIdValue is int) {
        usuarioCreadorId = usuarioCreadorIdValue;
      } else if (usuarioCreadorIdValue is String) {
        usuarioCreadorId = int.tryParse(usuarioCreadorIdValue) ?? 0;
      } else {
        throw Exception(
          'usuarioCreadorId tiene un tipo inválido: ${usuarioCreadorIdValue.runtimeType}',
        );
      }

      // Validar createdAt
      DateTime createdAt;
      if (createdAtValue == null) {
        createdAt = DateTime.now();
      } else if (createdAtValue is DateTime) {
        createdAt = createdAtValue;
      } else {
        createdAt = DateTime.now();
      }

      // Validar syncAttempts (puede ser null en datos antiguos)
      int syncAttempts = 0;
      if (syncAttemptsValue != null) {
        if (syncAttemptsValue is int) {
          syncAttempts = syncAttemptsValue;
        } else if (syncAttemptsValue is String) {
          syncAttempts = int.tryParse(syncAttemptsValue) ?? 0;
        }
      }

      return PendingExtinguisherModel(
        codeNFC: fields[0] as String?,
        serialNumber: fields[1] as String?,
        type: fields[2] as String?,
        capacity: fields[3] as String?,
        agent: fields[4] as String?,
        cylinderNumber: fields[5] as String?,
        location: fields[6] as String?,
        status: fields[7] as String?,
        historic: fields[8] as String?,
        dateLow: fields[9] as String?,
        photo: fields[10] as String?,
        sedeId: sedeId,
        usuarioCreadorId: usuarioCreadorId,
        createdAt: createdAt,
        lastSyncError: fields[14] as String?,
        syncAttempts: syncAttempts,
        lastSyncAttempt: fields[16] as DateTime?,
      );
    } catch (e) {
      // Si hay error al leer, lanzar excepción descriptiva
      throw Exception(
        'Error al leer extintor pendiente de Hive: $e. '
        'Los datos pueden estar corruptos. Intenta limpiar los datos pendientes.',
      );
    }
  }

  @override
  void write(BinaryWriter writer, PendingExtinguisherModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.codeNFC)
      ..writeByte(1)
      ..write(obj.serialNumber)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.capacity)
      ..writeByte(4)
      ..write(obj.agent)
      ..writeByte(5)
      ..write(obj.cylinderNumber)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.historic)
      ..writeByte(9)
      ..write(obj.dateLow)
      ..writeByte(10)
      ..write(obj.photo)
      ..writeByte(11)
      ..write(obj.sedeId)
      ..writeByte(12)
      ..write(obj.usuarioCreadorId)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.lastSyncError)
      ..writeByte(15)
      ..write(obj.syncAttempts)
      ..writeByte(16)
      ..write(obj.lastSyncAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingExtinguisherModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
