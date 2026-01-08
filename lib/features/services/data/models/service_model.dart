import '../../domain/entities/service_entity.dart';

/// Modelo: Servicio (Data Layer)
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.type,
    required super.dateStart,
    super.dateEnd,
    super.sincronizado,
    required super.status,
    super.statusValid,
    super.historic,
    required super.sedeId,
    required super.userId,
    required super.usuarioCreadorId,
    super.usuarioActualizadorId,
    super.createdAt,
    super.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      type: json['type'] as String,
      dateStart: DateTime.parse(json['dateStart'] as String),
      dateEnd: json['dateEnd'] != null
          ? DateTime.parse(json['dateEnd'] as String)
          : null,
      sincronizado: json['sincronizado'] as bool? ?? false,
      status: json['status'] as String,
      statusValid: json['statusValid'] as String? ?? 'APROBADO',
      historic: json['historic'] as String?,
      sedeId: json['sedeId'] as int,
      userId: json['userId'] as int,
      usuarioCreadorId: json['usuarioCreadorId'] as int,
      usuarioActualizadorId: json['usuarioActualizadorId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'dateStart': dateStart.toIso8601String(),
      'dateEnd': dateEnd?.toIso8601String(),
      'sincronizado': sincronizado,
      'status': status,
      'statusValid': statusValid,
      'historic': historic,
      'sedeId': sedeId,
      'userId': userId,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int,
      type: map['type'] as String,
      dateStart: DateTime.parse(map['dateStart'] as String),
      dateEnd: map['dateEnd'] != null
          ? DateTime.parse(map['dateEnd'] as String)
          : null,
      sincronizado: (map['sincronizado'] as int? ?? 0) == 1,
      status: map['status'] as String,
      statusValid: map['statusValid'] as String? ?? 'APROBADO',
      historic: map['historic'] as String?,
      sedeId: map['sedeId'] as int,
      userId: map['userId'] as int,
      usuarioCreadorId: map['usuarioCreadorId'] as int,
      usuarioActualizadorId: map['usuarioActualizadorId'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'dateStart': dateStart.toIso8601String(),
      'dateEnd': dateEnd?.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
      'status': status,
      'statusValid': statusValid,
      'historic': historic,
      'sedeId': sedeId,
      'userId': userId,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
