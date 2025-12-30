// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sede_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SedeHiveModelAdapter extends TypeAdapter<SedeHiveModel> {
  @override
  final int typeId = 1;

  @override
  SedeHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SedeHiveModel(
      id: fields[0] as int,
      nameSede: fields[1] as String,
      address: fields[2] as String,
      city: fields[3] as String,
      active: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SedeHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameSede)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.active);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SedeHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
