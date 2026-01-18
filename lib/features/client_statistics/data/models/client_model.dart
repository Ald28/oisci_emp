import '../../domain/entities/client_entity.dart';

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
    };
  }
}
