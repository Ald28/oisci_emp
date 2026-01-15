import '../../domain/entities/maintenance_detail_entity.dart';

/// Modelo: MantenimientoDetalle (Data Layer)
class MaintenanceDetailModel extends MaintenanceDetailEntity {
  const MaintenanceDetailModel({
    required super.id,
    required super.servicioExtintorId,
    super.mantenimiento,
    super.recarga,
    super.agenteCarga,
    super.pruebaHidrostatica,
    super.bajaExtintor,
    super.motivoBaja,
    super.pintura,
    super.recargaCartucho,
    super.cambioPartes,
    super.detallesCambioPartes,
    required super.usuarioCreadorId,
    super.usuarioActualizadorId,
    super.createdAt,
    super.updatedAt,
  });

  factory MaintenanceDetailModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetailModel(
      id: json['id'] as int,
      servicioExtintorId: json['servicioExtintorId'] as int,
      mantenimiento: json['mantenimiento'] as bool? ?? false,
      recarga: json['recarga'] as bool? ?? false,
      agenteCarga: json['agenteCarga'] as String?,
      pruebaHidrostatica: json['pruebaHidrostatica'] as bool? ?? false,
      bajaExtintor: json['bajaExtintor'] as bool? ?? false,
      motivoBaja: json['motivoBaja'] as String?,
      pintura: json['pintura'] as bool? ?? false,
      recargaCartucho: json['recargaCartucho'] as bool? ?? false,
      cambioPartes: json['cambioPartes'] as bool? ?? false,
      detallesCambioPartes: json['detallesCambioPartes'] as String?,
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
      'mantenimiento': mantenimiento,
      'recarga': recarga,
      'agenteCarga': agenteCarga,
      'pruebaHidrostatica': pruebaHidrostatica,
      'bajaExtintor': bajaExtintor,
      'motivoBaja': motivoBaja,
      'pintura': pintura,
      'recargaCartucho': recargaCartucho,
      'cambioPartes': cambioPartes,
      'detallesCambioPartes': detallesCambioPartes,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory MaintenanceDetailModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceDetailModel(
      id: map['id'] as int,
      servicioExtintorId: map['servicioExtintorId'] as int,
      mantenimiento: (map['mantenimiento'] as int? ?? 0) == 1,
      recarga: (map['recarga'] as int? ?? 0) == 1,
      agenteCarga: map['agenteCarga'] as String?,
      pruebaHidrostatica: (map['pruebaHidrostatica'] as int? ?? 0) == 1,
      bajaExtintor: (map['bajaExtintor'] as int? ?? 0) == 1,
      motivoBaja: map['motivoBaja'] as String?,
      pintura: (map['pintura'] as int? ?? 0) == 1,
      recargaCartucho: (map['recargaCartucho'] as int? ?? 0) == 1,
      cambioPartes: (map['cambioPartes'] as int? ?? 0) == 1,
      detallesCambioPartes: map['detallesCambioPartes'] as String?,
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
      'mantenimiento': mantenimiento ? 1 : 0,
      'recarga': recarga ? 1 : 0,
      'agenteCarga': agenteCarga,
      'pruebaHidrostatica': pruebaHidrostatica ? 1 : 0,
      'bajaExtintor': bajaExtintor ? 1 : 0,
      'motivoBaja': motivoBaja,
      'pintura': pintura ? 1 : 0,
      'recargaCartucho': recargaCartucho ? 1 : 0,
      'cambioPartes': cambioPartes ? 1 : 0,
      'detallesCambioPartes': detallesCambioPartes,
      'usuarioCreadorId': usuarioCreadorId,
      'usuarioActualizadorId': usuarioActualizadorId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
