import 'package:hive/hive.dart';

part 'sede_hive_model.g.dart';

/// Modelo Hive: Sede (Data Layer)
/// Se guarda localmente para uso offline
/// Incluye el ID del servidor para mantener consistencia
@HiveType(typeId: 1)
class SedeHiveModel extends HiveObject {
  @HiveField(0)
  final int id; // ID del servidor (importante para mantener consistencia)

  @HiveField(1)
  final String nameSede;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String city;

  @HiveField(4)
  final bool active;

  SedeHiveModel({
    required this.id,
    required this.nameSede,
    required this.address,
    required this.city,
    required this.active,
  });

  /// Crear desde SedeModel (del servidor)
  factory SedeHiveModel.fromSedeModel(dynamic sedeModel) {
    return SedeHiveModel(
      id: sedeModel.id,
      nameSede: sedeModel.nameSede,
      address: sedeModel.address,
      city: sedeModel.city,
      active: sedeModel.active,
    );
  }

  /// Convertir a Sede (entidad del dominio)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_sede': nameSede,
      'address': address,
      'city': city,
      'active': active,
    };
  }
}
