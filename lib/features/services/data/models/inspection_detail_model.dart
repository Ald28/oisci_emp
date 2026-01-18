import '../../domain/entities/inspection_detail_entity.dart';

/// Modelo: InspeccionDetalle (Data Layer)
class InspectionDetailModel extends InspectionDetailEntity {
  const InspectionDetailModel({
    required super.id,
    required super.servicioExtintorId,
    super.foto1Url,
    super.foto2Url,
    super.foto3Url,
    super.visibilidad,
    super.visualizacion,
    super.accesibilidad,
    super.altura,
    super.situacion,
    super.conservacion,
    super.inscripciones,
    super.recorrido,
    super.peso,
    super.observaciones,
    required super.usuarioCreadorId,
    super.usuarioActualizadorId,
    super.createdAt,
    super.updatedAt,
  });

  factory InspectionDetailModel.fromJson(Map<String, dynamic> json) {
    return InspectionDetailModel(
      id: json['id'] as int,
      servicioExtintorId: json['servicioExtintorId'] as int,
      foto1Url: json['foto1Url'] as String?,
      foto2Url: json['foto2Url'] as String?,
      foto3Url: json['foto3Url'] as String?,
      visibilidad: json['visibilidad'] as String?,
      visualizacion: json['visualizacion'] as String?,
      accesibilidad: json['accesibilidad'] as String?,
      altura: json['altura'] as String?,
      situacion: json['situacion'] as String?,
      conservacion: json['conservacion'] as String?,
      inscripciones: json['inscripciones'] as String?,
      recorrido: json['recorrido'] as String?,
      peso: json['peso'] as String?,
      observaciones: json['observaciones'] as String?,
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
      'servicioExtintorId': servicioExtintorId,
      'foto1Url': foto1Url,
      'foto2Url': foto2Url,
      'foto3Url': foto3Url,
      'visibilidad': visibilidad,
      'visualizacion': visualizacion,
      'accesibilidad': accesibilidad,
      'altura': altura,
      'situacion': situacion,
      'conservacion': conservacion,
      'inscripciones': inscripciones,
      'recorrido': recorrido,
      'peso': peso,
      'observaciones': observaciones,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InspectionDetailModel.fromMap(Map<String, dynamic> map) {
    return InspectionDetailModel(
      id: map['id'] as int,
      servicioExtintorId: map['servicioExtintorId'] as int,
      foto1Url: map['foto1Url'] as String?,
      foto2Url: map['foto2Url'] as String?,
      foto3Url: map['foto3Url'] as String?,
      visibilidad: map['visibilidad'] as String?,
      visualizacion: map['visualizacion'] as String?,
      accesibilidad: map['accesibilidad'] as String?,
      altura: map['altura'] as String?,
      situacion: map['situacion'] as String?,
      conservacion: map['conservacion'] as String?,
      inscripciones: map['inscripciones'] as String?,
      recorrido: map['recorrido'] as String?,
      peso: map['peso'] as String?,
      observaciones: map['observaciones'] as String?,
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
      'servicioExtintorId': servicioExtintorId,
      'foto1Url': foto1Url,
      'foto2Url': foto2Url,
      'foto3Url': foto3Url,
      'visibilidad': visibilidad,
      'visualizacion': visualizacion,
      'accesibilidad': accesibilidad,
      'altura': altura,
      'situacion': situacion,
      'conservacion': conservacion,
      'inscripciones': inscripciones,
      'recorrido': recorrido,
      'peso': peso,
      'observaciones': observaciones,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
