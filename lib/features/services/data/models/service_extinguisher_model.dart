import '../../domain/entities/service_extinguisher_entity.dart';

/// Modelo: ServicioExtintor (Data Layer)
class ServiceExtinguisherModel extends ServiceExtinguisherEntity {
  const ServiceExtinguisherModel({
    required super.id,
    required super.servicioId,
    required super.extintorId,
    super.estadoInicial,
    super.estadoFinal,
    super.completado,
    super.observaciones,
    required super.usuarioCreadorId,
    super.usuarioActualizadorId,
    super.createdAt,
    super.updatedAt,
    super.codeExtintor,
    super.serialNumberNFC,
  });

  factory ServiceExtinguisherModel.fromJson(Map<String, dynamic> json) {
    // El backend retorna el objeto extintor anidado con include: { extintor: true }
    final extintor = json['extintor'] as Map<String, dynamic>?;
    final codeExtintor = extintor?['codeExtintor'] as String?;
    final serialNumberNFC = extintor?['serialNumberNFC'] as String?;

    return ServiceExtinguisherModel(
      id: json['id'] as int,
      servicioId: json['servicioId'] as int,
      extintorId: json['extintorId'] as int,
      estadoInicial: json['estadoInicial'] as String?,
      estadoFinal: json['estadoFinal'] as String?,
      completado: json['completado'] as bool? ?? false,
      observaciones: json['observaciones'] as String?,
      usuarioCreadorId: json['usuarioCreadorId'] as int,
      usuarioActualizadorId: json['usuarioActualizadorId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      codeExtintor: codeExtintor,
      serialNumberNFC: serialNumberNFC,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servicioId': servicioId,
      'extintorId': extintorId,
      'estadoInicial': estadoInicial,
      'estadoFinal': estadoFinal,
      'completado': completado,
      'observaciones': observaciones,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ServiceExtinguisherModel.fromMap(Map<String, dynamic> map) {
    // El JOIN en local_service_datasource incluye codeExtintor y serialNumberNFC
    return ServiceExtinguisherModel(
      id: map['id'] as int,
      servicioId: map['servicioId'] as int,
      extintorId: map['extintorId'] as int,
      estadoInicial: map['estadoInicial'] as String?,
      estadoFinal: map['estadoFinal'] as String?,
      completado: (map['completado'] as int? ?? 0) == 1,
      observaciones: map['observaciones'] as String?,
      usuarioCreadorId: map['usuarioCreadorId'] as int,
      usuarioActualizadorId: map['usuarioActualizadorId'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      codeExtintor: map['codeExtintor'] as String?,
      serialNumberNFC: map['serialNumberNFC'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'servicioId': servicioId,
      'extintorId': extintorId,
      'estadoInicial': estadoInicial,
      'estadoFinal': estadoFinal,
      'completado': completado ? 1 : 0,
      'observaciones': observaciones,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
