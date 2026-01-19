import '../../domain/entities/client_entity.dart';
import '../../../services/data/models/sede_model.dart';

/// Modelo: Cliente (Data Layer)
class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.clientCode,
    required super.razonSocial,
    required super.ruc,
    required super.phone,
    required super.address,
    required super.userId,
    required super.active,
    super.createdAt,
    super.updatedAt,
    super.sedes,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    // El backend puede retornar createdAt y updatedAt como strings ISO
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Parsear sedes si existen
    List<SedeModel>? sedes;
    if (json['sedes'] != null && json['sedes'] is List) {
      sedes = (json['sedes'] as List)
          .map(
            (sedeJson) => SedeModel.fromJson(sedeJson as Map<String, dynamic>),
          )
          .toList();
    }

    return ClientModel(
      id: json['id'] as int,
      clientCode: json['clientCode'] as String,
      razonSocial: json['razonSocial'] as String,
      ruc: json['ruc'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      userId: json['userId'] as int,
      active: json['active'] as bool? ?? true,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      sedes: sedes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientCode': clientCode,
      'razonSocial': razonSocial,
      'ruc': ruc,
      'phone': phone,
      'address': address,
      'userId': userId,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sedes': sedes?.map((sede) => (sede as SedeModel).toMap()).toList(),
    };
  }

  /// Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientCode': clientCode,
      'razonSocial': razonSocial,
      'ruc': ruc,
      'phone': phone,
      'address': address,
      'userId': userId,
      'active': active ? 1 : 0,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Crear desde Map de SQLite
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return ClientModel(
      id: map['id'] as int,
      clientCode: map['clientCode'] as String,
      razonSocial: map['razonSocial'] as String,
      ruc: map['ruc'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      userId: map['userId'] as int,
      active: (map['active'] as int) == 1,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }
}
