import '../../domain/entities/sede.dart';

/// Modelo: Sede (Data Layer)
class SedeModel extends Sede {
  const SedeModel({
    required super.id,
    required super.nameSede,
    required super.address,
    required super.city,
    required super.active,
  });

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: json['id'] as int,
      nameSede: json['name_sede'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}

