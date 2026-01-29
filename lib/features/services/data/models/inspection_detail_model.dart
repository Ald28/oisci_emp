import '../../domain/entities/inspection_detail_entity.dart';

/// Modelo: InspeccionDetalle (Data Layer)
class InspectionDetailModel extends InspectionDetailEntity {
  const InspectionDetailModel({
    required super.id,
    required super.servicioExtintorId,
    super.foto1Url,
    super.foto2Url,
    super.foto3Url,
    super.foto1Path,
    super.foto2Path,
    super.foto3Path,
    super.accesibilidad,
    super.observaciones,
    super.ubicacion,
    super.instalacion,
    super.instrucciones,
    super.clasificacion,
    super.recarga,
    super.certificacion,
    super.presion,
    super.seguridad,
    super.estado,
    super.carga,
    super.soporte,
    super.activacion,
    super.manguera,
    super.boquilla,
    super.abrazadera,
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
      // El backend no envía paths locales
      foto1Path: null,
      foto2Path: null,
      foto3Path: null,
      accesibilidad: json['accesibilidad'] as String?,
      observaciones: json['observaciones'] as String?,
      ubicacion: json['ubicacion'] as String?,
      instalacion: json['instalacion'] as String?,
      instrucciones: json['instrucciones'] as String?,
      clasificacion: json['clasificacion'] as String?,
      recarga: json['recarga'] as String?,
      certificacion: json['certificacion'] as String?,
      presion: json['presion'] as String?,
      seguridad: json['seguridad'] as String?,
      estado: json['estado'] as String?,
      carga: json['carga'] as String?,
      soporte: json['soporte'] as String?,
      activacion: json['activacion'] as String?,
      manguera: json['manguera'] as String?,
      boquilla: json['boquilla'] as String?,
      abrazadera: json['abrazadera'] as String?,
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
      'foto1Path': foto1Path,
      'foto2Path': foto2Path,
      'foto3Path': foto3Path,
      'accesibilidad': accesibilidad,
      'observaciones': observaciones,
      'ubicacion': ubicacion,
      'instalacion': instalacion,
      'instrucciones': instrucciones,
      'clasificacion': clasificacion,
      'recarga': recarga,
      'certificacion': certificacion,
      'presion': presion,
      'seguridad': seguridad,
      'estado': estado,
      'carga': carga,
      'soporte': soporte,
      'activacion': activacion,
      'manguera': manguera,
      'boquilla': boquilla,
      'abrazadera': abrazadera,
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
      foto1Path: map['foto1Path'] as String?,
      foto2Path: map['foto2Path'] as String?,
      foto3Path: map['foto3Path'] as String?,
      accesibilidad: map['accesibilidad'] as String?,
      observaciones: map['observaciones'] as String?,
      ubicacion: map['ubicacion'] as String?,
      instalacion: map['instalacion'] as String?,
      instrucciones: map['instrucciones'] as String?,
      clasificacion: map['clasificacion'] as String?,
      recarga: map['recarga'] as String?,
      certificacion: map['certificacion'] as String?,
      presion: map['presion'] as String?,
      seguridad: map['seguridad'] as String?,
      estado: map['estado'] as String?,
      carga: map['carga'] as String?,
      soporte: map['soporte'] as String?,
      activacion: map['activacion'] as String?,
      manguera: map['manguera'] as String?,
      boquilla: map['boquilla'] as String?,
      abrazadera: map['abrazadera'] as String?,
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
      'foto1Path': foto1Path,
      'foto2Path': foto2Path,
      'foto3Path': foto3Path,
      'accesibilidad': accesibilidad,
      'observaciones': observaciones,
      'ubicacion': ubicacion,
      'instalacion': instalacion,
      'instrucciones': instrucciones,
      'clasificacion': clasificacion,
      'recarga': recarga,
      'certificacion': certificacion,
      'presion': presion,
      'seguridad': seguridad,
      'estado': estado,
      'carga': carga,
      'soporte': soporte,
      'activacion': activacion,
      'manguera': manguera,
      'boquilla': boquilla,
      'abrazadera': abrazadera,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
