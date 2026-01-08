import '../../domain/entities/sede_entity.dart';

/// Modelo: Sede (Data Layer)
/// Incluye todos los campos según schema de Prisma
class SedeModel extends Sede {
  final String? managerName;
  final String? managerPhone;
  final String? managerEmail;
  final int? clientId;

  const SedeModel({
    required super.id,
    required super.nameSede,
    required super.address,
    required super.city,
    required super.active,
    this.managerName,
    this.managerPhone,
    this.managerEmail,
    this.clientId,
  });

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: json['id'] as int,
      nameSede: json['name_sede'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      active: json['active'] as bool? ?? true,
      managerName: json['manager_name'] as String?,
      managerPhone: json['manager_phone'] as String?,
      managerEmail: json['manager_email'] as String?,
      clientId: json['clientId'] as int?,
    );
  }

  /// Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_sede': nameSede,
      'address': address,
      'manager_name': managerName ?? '',
      'manager_phone': managerPhone ?? '',
      'manager_email': managerEmail ?? '',
      'city': city,
      'active': active ? 1 : 0,
      'clientId': clientId ?? 0,
      'createdAt': null,
      'updatedAt': null,
    };
  }

  /// Crear desde Map de SQLite
  factory SedeModel.fromMap(Map<String, dynamic> map) {
    return SedeModel(
      id: map['id'] as int,
      nameSede: map['name_sede'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      active: (map['active'] as int) == 1,
      managerName: map['manager_name'] as String?,
      managerPhone: map['manager_phone'] as String?,
      managerEmail: map['manager_email'] as String?,
      clientId: map['clientId'] as int?,
    );
  }
}
