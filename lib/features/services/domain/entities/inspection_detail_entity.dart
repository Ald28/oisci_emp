/// Entidad: InspeccionDetalle
/// Coincide con el modelo InspeccionDetalle del backend (Prisma)
class InspectionDetailEntity {
  final int id;
  final int servicioExtintorId;
  final String? foto1Url;
  final String? foto2Url;
  final String? foto3Url;

  /// Paths locales para modo offline (no vienen del backend)
  final String? foto1Path;
  final String? foto2Path;
  final String? foto3Path;
  final String? accesibilidad;
  final String? observaciones;
  final String? ubicacion;
  final String? instalacion;
  final String? instrucciones;
  final String? clasificacion;
  final String? recarga;
  final String? certificacion;
  final String? presion;
  final String? seguridad;
  final String? estado;
  final String? carga;
  final String? soporte;
  final String? activacion;
  final String? manguera;
  final String? boquilla;
  final String? abrazadera;
  final int usuarioCreadorId;
  final int? usuarioActualizadorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InspectionDetailEntity({
    required this.id,
    required this.servicioExtintorId,
    this.foto1Url,
    this.foto2Url,
    this.foto3Url,
    this.foto1Path,
    this.foto2Path,
    this.foto3Path,
    this.accesibilidad,
    this.observaciones,
    this.ubicacion,
    this.instalacion,
    this.instrucciones,
    this.clasificacion,
    this.recarga,
    this.certificacion,
    this.presion,
    this.seguridad,
    this.estado,
    this.carga,
    this.soporte,
    this.activacion,
    this.manguera,
    this.boquilla,
    this.abrazadera,
    required this.usuarioCreadorId,
    this.usuarioActualizadorId,
    this.createdAt,
    this.updatedAt,
  });
}
